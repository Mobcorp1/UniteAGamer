import 'dart:async';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_expedition_state_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_season_reset_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_season_reset_repository.dart';

abstract class ArcExpeditionStateGateway {
  Stream<ArcSeasonState> watchSeasonState();
  Future<void> ensureSeasonStateExists();
  Future<ArcSeasonState> getSeasonState();
  Future<ArcSeasonResetPreview> createResetPreview({
    String? nextSeasonId,
    String? resetId,
  });
  Future<ArcSeasonResetApplyResult> applyReset(
    ArcSeasonResetPreview preview, {
    bool adminPreview = false,
  });
  Future<ArcSeasonResetApplyResult?> reconcileInterruptedReset();
}

class ArcSeasonResetExpeditionGateway implements ArcExpeditionStateGateway {
  ArcSeasonResetExpeditionGateway({ArcSeasonResetRepository? repository})
    : _repository = repository ?? ArcSeasonResetRepository();

  final ArcSeasonResetRepository _repository;

  @override
  Stream<ArcSeasonState> watchSeasonState() => _repository.watchSeasonState();

  @override
  Future<void> ensureSeasonStateExists() =>
      _repository.ensureSeasonStateExists();

  @override
  Future<ArcSeasonState> getSeasonState() => _repository.getSeasonState();

  @override
  Future<ArcSeasonResetPreview> createResetPreview({
    String? nextSeasonId,
    String? resetId,
  }) {
    return _repository.createResetPreview(
      nextSeasonId: nextSeasonId,
      resetId: resetId,
    );
  }

  @override
  Future<ArcSeasonResetApplyResult> applyReset(
    ArcSeasonResetPreview preview, {
    bool adminPreview = false,
  }) {
    return _repository.applyReset(preview, adminPreview: adminPreview);
  }

  @override
  Future<ArcSeasonResetApplyResult?> reconcileInterruptedReset() =>
      _repository.reconcileInterruptedReset();
}

class ArcExpeditionStateManager {
  ArcExpeditionStateManager({ArcExpeditionStateGateway? gateway})
    : _gateway = gateway ?? ArcSeasonResetExpeditionGateway();

  static final ArcExpeditionStateManager instance = ArcExpeditionStateManager();

  final ArcExpeditionStateGateway _gateway;
  final StreamController<ArcExpeditionRefreshEvent> _refreshController =
      StreamController<ArcExpeditionRefreshEvent>.broadcast();

  Stream<ArcExpeditionRefreshEvent> get refreshEvents =>
      _refreshController.stream;

  Stream<ArcExpeditionRefreshEvent> watchRefreshesFor(
    ArcExpeditionSubsystem subsystem,
  ) {
    return refreshEvents.where((event) => event.includes(subsystem));
  }

  Stream<ArcExpeditionStateSnapshot> watchState() {
    try {
      return _gateway.watchSeasonState().map(
        (state) => ArcExpeditionStateSnapshot.fromSeasonState(state),
      );
    } catch (_) {
      return Stream.value(
        ArcExpeditionStateSnapshot.fromSeasonState(ArcSeasonState.initial()),
      );
    }
  }

  Future<ArcExpeditionStateSnapshot> refresh({
    ArcExpeditionRefreshReason reason =
        ArcExpeditionRefreshReason.manualRefresh,
  }) async {
    await _gateway.ensureSeasonStateExists();
    final reconciled = await _gateway.reconcileInterruptedReset();
    final state = await _gateway.getSeasonState();
    final resolvedReason = reconciled == null
        ? reason
        : ArcExpeditionRefreshReason.resetReconciled;
    final snapshot = ArcExpeditionStateSnapshot.fromSeasonState(
      state,
      reason: resolvedReason,
    );
    _emit(
      ArcExpeditionRefreshEvent(
        reason: resolvedReason,
        currentSeasonId: snapshot.currentSeasonId,
        resetId: reconciled?.resetId,
        resetVersion: snapshot.resetVersion,
        occurredAt: DateTime.now().toUtc(),
      ),
    );
    return snapshot;
  }

  Future<ArcSeasonResetPreview> createResetPreview({
    String? nextSeasonId,
    String? resetId,
  }) async {
    await _gateway.ensureSeasonStateExists();
    await _gateway.reconcileInterruptedReset();
    return _gateway.createResetPreview(
      nextSeasonId: nextSeasonId,
      resetId: resetId,
    );
  }

  Future<ArcSeasonResetApplyResult> beginReset(
    ArcSeasonResetPreview preview, {
    bool adminPreview = false,
  }) async {
    _emit(
      ArcExpeditionRefreshEvent(
        reason: ArcExpeditionRefreshReason.resetStarted,
        currentSeasonId: preview.currentSeasonId,
        resetId: preview.resetId,
        resetVersion: preview.resetVersion,
        occurredAt: DateTime.now().toUtc(),
        systems: ArcExpeditionSubsystem.values,
      ),
    );

    try {
      final result = await _gateway.applyReset(
        preview,
        adminPreview: adminPreview,
      );
      _emit(
        ArcExpeditionRefreshEvent(
          reason: ArcExpeditionRefreshReason.resetCompleted,
          currentSeasonId: result.currentSeasonId,
          resetId: result.resetId,
          resetVersion: result.resetVersion,
          occurredAt: result.completedAt,
          systems: ArcExpeditionSubsystem.values,
        ),
      );
      return result;
    } catch (_) {
      _emit(
        ArcExpeditionRefreshEvent(
          reason: ArcExpeditionRefreshReason.resetFailed,
          currentSeasonId: preview.currentSeasonId,
          resetId: preview.resetId,
          resetVersion: preview.resetVersion,
          occurredAt: DateTime.now().toUtc(),
          systems: ArcExpeditionSubsystem.values,
        ),
      );
      rethrow;
    }
  }

  void notifyProgressionChanged(
    ArcExpeditionSubsystem subsystem, {
    String? currentSeasonId,
  }) {
    _emit(
      ArcExpeditionRefreshEvent(
        reason: ArcExpeditionRefreshReason.progressionChanged,
        currentSeasonId:
            currentSeasonId ?? ArcSeasonResetPolicy.defaultCurrentSeasonId,
        occurredAt: DateTime.now().toUtc(),
        systems: <ArcExpeditionSubsystem>[subsystem],
      ),
    );
  }

  void dispose() {
    _refreshController.close();
  }

  void _emit(ArcExpeditionRefreshEvent event) {
    if (_refreshController.isClosed) return;
    _refreshController.add(event);
  }
}
