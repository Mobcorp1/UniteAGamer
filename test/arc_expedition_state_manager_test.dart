import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_expedition_state_manager.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_expedition_state_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_season_reset_models.dart';

void main() {
  group('ArcExpeditionStateManager', () {
    test(
      'refresh reconciles interrupted resets and publishes update events',
      () async {
        final gateway = _FakeExpeditionStateGateway()
          ..state = _seasonState(resetVersion: 4)
          ..reconciledResult = _applyResult(resetVersion: 4);
        final manager = ArcExpeditionStateManager(gateway: gateway);
        addTearDown(manager.dispose);

        final eventFuture = manager.refreshEvents.first;
        final snapshot = await manager.refresh();
        final event = await eventFuture;

        expect(gateway.ensureCount, 1);
        expect(gateway.reconcileCount, 1);
        expect(snapshot.resetVersion, 4);
        expect(snapshot.subscribedSystems, ArcExpeditionSubsystem.values);
        expect(event.reason, ArcExpeditionRefreshReason.resetReconciled);
        expect(event.includes(ArcExpeditionSubsystem.commandCentre), isTrue);
        expect(event.includes(ArcExpeditionSubsystem.blueprintTracker), isTrue);
      },
    );

    test('beginReset delegates once and emits start and completion', () async {
      final gateway = _FakeExpeditionStateGateway();
      final manager = ArcExpeditionStateManager(gateway: gateway);
      addTearDown(manager.dispose);

      final eventsFuture = manager
          .watchRefreshesFor(ArcExpeditionSubsystem.blueprintTracker)
          .take(2)
          .toList();
      final result = await manager.beginReset(gateway.preview);
      final events = await eventsFuture;

      expect(gateway.applyCount, 1);
      expect(result.resetId, gateway.preview.resetId);
      expect(events.map((event) => event.reason), [
        ArcExpeditionRefreshReason.resetStarted,
        ArcExpeditionRefreshReason.resetCompleted,
      ]);
      expect(events.every((event) => event.systems.length == 10), isTrue);
    });

    test('beginReset emits failure without swallowing the exception', () async {
      final gateway = _FakeExpeditionStateGateway()..failApply = true;
      final manager = ArcExpeditionStateManager(gateway: gateway);
      addTearDown(manager.dispose);

      final eventsFuture = manager.refreshEvents.take(2).toList();

      await expectLater(
        manager.beginReset(gateway.preview),
        throwsA(isA<StateError>()),
      );

      final events = await eventsFuture;
      expect(events.map((event) => event.reason), [
        ArcExpeditionRefreshReason.resetStarted,
        ArcExpeditionRefreshReason.resetFailed,
      ]);
    });

    test('createResetPreview ensures season state before delegating', () async {
      final gateway = _FakeExpeditionStateGateway();
      final manager = ArcExpeditionStateManager(gateway: gateway);
      addTearDown(manager.dispose);

      final preview = await manager.createResetPreview(
        nextSeasonId: 'closed-beta-season-2',
        resetId: 'manual-reset',
      );

      expect(gateway.ensureCount, 1);
      expect(gateway.reconcileCount, 1);
      expect(gateway.previewCount, 1);
      expect(preview.nextSeasonId, 'closed-beta-season-2');
      expect(preview.resetId, 'manual-reset');
    });
  });
}

class _FakeExpeditionStateGateway implements ArcExpeditionStateGateway {
  ArcSeasonState state = _seasonState();
  ArcSeasonResetApplyResult? reconciledResult;
  bool failApply = false;
  int ensureCount = 0;
  int getCount = 0;
  int previewCount = 0;
  int applyCount = 0;
  int reconcileCount = 0;

  late ArcSeasonResetPreview preview = _preview(
    currentSeasonId: state.currentSeasonId,
    nextSeasonId: 'closed-beta-season-2',
    resetId: 'reset-1',
    resetVersion: state.resetVersion + 1,
  );

  @override
  Future<void> ensureSeasonStateExists() async {
    ensureCount += 1;
  }

  @override
  Future<ArcSeasonState> getSeasonState() async {
    getCount += 1;
    return state;
  }

  @override
  Future<ArcSeasonResetPreview> createResetPreview({
    String? nextSeasonId,
    String? resetId,
  }) async {
    previewCount += 1;
    preview = _preview(
      currentSeasonId: state.currentSeasonId,
      nextSeasonId: nextSeasonId ?? 'closed-beta-season-2',
      resetId: resetId ?? 'reset-1',
      resetVersion: state.resetVersion + 1,
    );
    return preview;
  }

  @override
  Future<ArcSeasonResetApplyResult> applyReset(
    ArcSeasonResetPreview preview, {
    bool adminPreview = false,
  }) async {
    applyCount += 1;
    if (failApply) {
      throw StateError('reset failed');
    }
    final result = _applyResult(
      resetId: preview.resetId,
      currentSeasonId: preview.nextSeasonId,
      archivedSeasonId: preview.currentSeasonId,
      resetVersion: preview.resetVersion,
    );
    state = state.copyWith(
      currentSeasonId: result.currentSeasonId,
      lastCompletedSeasonId: result.archivedSeasonId,
      lastResetId: result.resetId,
      lastResetAt: result.completedAt,
      resetVersion: result.resetVersion,
      resetStatus: ArcSeasonResetStatus.completed,
    );
    return result;
  }

  @override
  Future<ArcSeasonResetApplyResult?> reconcileInterruptedReset() async {
    reconcileCount += 1;
    return reconciledResult;
  }

  @override
  Stream<ArcSeasonState> watchSeasonState() => Stream.value(state);
}

ArcSeasonState _seasonState({int resetVersion = 0}) {
  return ArcSeasonState.initial(
    now: DateTime.utc(2026),
  ).copyWith(resetVersion: resetVersion);
}

ArcSeasonResetPreview _preview({
  required String currentSeasonId,
  required String nextSeasonId,
  required String resetId,
  required int resetVersion,
}) {
  return ArcSeasonResetPreview(
    currentSeasonId: currentSeasonId,
    nextSeasonId: nextSeasonId,
    resetId: resetId,
    resetVersion: resetVersion,
    generatedAt: DateTime.utc(2026, 1, 2),
    impacts: ArcSeasonResetPolicy.impacts(
      blueprintStateCount: 2,
      scrappyStateCount: 1,
      questStateCount: 1,
      benchStateCount: 1,
      rewardCount: 3,
      operationProgressCount: 1,
    ),
  );
}

ArcSeasonResetApplyResult _applyResult({
  String resetId = 'reset-1',
  String archivedSeasonId = 'closed-beta-season-1',
  String currentSeasonId = 'closed-beta-season-2',
  int resetVersion = 1,
}) {
  return ArcSeasonResetApplyResult(
    resetId: resetId,
    archivedSeasonId: archivedSeasonId,
    currentSeasonId: currentSeasonId,
    resetVersion: resetVersion,
    completedAt: DateTime.utc(2026, 1, 2, 12),
  );
}
