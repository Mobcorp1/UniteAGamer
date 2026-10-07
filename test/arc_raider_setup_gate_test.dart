import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raider_setup_evaluator.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_raider_setup_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raider_setup_screen.dart';

class _Repository extends Fake implements ArcRaiderSetupRepository {
  _Repository(this.status);
  ArcRaiderSetupStatus status;
  bool fail = false;
  int writes = 0;
  @override
  Future<ArcRaiderSetupSnapshot> load() async {
    if (fail) throw StateError('offline');
    return ArcRaiderSetupSnapshot(
      status: status,
      progression: ArcProgressionRecords.empty,
    );
  }

  @override
  Future<void> complete() async {
    writes++;
    status = ArcRaiderSetupStatus(completed: status.completed, version: 1);
  }
}

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(430, 932),
    const Size(640, 360),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1280, 900),
  ]) {
    testWidgets('catch-up first missing section and responsive layout $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 24);
      addTearDown(tester.view.reset);
      final repo = _Repository(
        const ArcRaiderSetupStatus(
          completed: {ArcRaiderSetupSection.profile},
          version: 0,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ArcRaiderSetupGate(
            repository: repo,
            child: const Text('Command Centre'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 / 7 COMPLETE'), findsOneWidget);
      expect(find.text('Edit Availability'), findsOneWidget);
      expect(find.text('Complete Profile'), findsNothing);
      expect(find.text('Command Centre'), findsNothing);
      expect(tester.takeException(), isNull);
      expect(repo.writes, 0);
    });
  }
  for (final size in [const Size(320, 640), const Size(640, 360)]) {
    testWidgets('every setup section scrolls without overflow at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 24);
      addTearDown(tester.view.reset);
      for (final section in ArcRaiderSetupSection.values) {
        final repo = _Repository(
          ArcRaiderSetupStatus(
            completed: ArcRaiderSetupSection.values
                .where((s) => s != section)
                .toSet(),
            version: 0,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: ArcRaiderSetupGate(
              key: ValueKey(section),
              repository: repo,
              child: const Text('Command Centre'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('6 / 7 COMPLETE'), findsOneWidget);
        expect(find.text(section.label.toUpperCase()), findsOneWidget);
        if (section == ArcRaiderSetupSection.quests) {
          await tester.scrollUntilVisible(find.byType(TextField), 150);
          await tester.enterText(
            find.byType(TextField),
            'unlikely quest search',
          );
          await tester.pump();
        }
        await tester.drag(find.byType(ListView), const Offset(0, -1500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: section.label);
        expect(find.text('Command Centre'), findsNothing);
        expect(repo.writes, 0);
      }
    });
  }
  testWidgets('ready legacy account accepts new version before normal entry', (
    tester,
  ) async {
    final repo = _Repository(
      ArcRaiderSetupStatus(
        completed: ArcRaiderSetupSection.values.toSet(),
        version: 0,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ArcRaiderSetupGate(
          repository: repo,
          child: const Text('Command Centre'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('RAIDER INTELLIGENCE READY'), findsOneWidget);
    expect(find.text('Command Centre'), findsNothing);
    await tester.ensureVisible(find.text('ENTER COMMAND CENTRE'));
    await tester.tap(find.text('ENTER COMMAND CENTRE'));
    await tester.pumpAndSettle();
    expect(find.text('Command Centre'), findsOneWidget);
    expect(repo.writes, 1);
  });
  testWidgets('errors block entry and retry; preview causes no setup writes', (
    tester,
  ) async {
    final repo = _Repository(
      const ArcRaiderSetupStatus(completed: {}, version: 0, preview: true),
    )..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: ArcRaiderSetupGate(
          repository: repo,
          child: const Text('Preview'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Preview'), findsNothing);
    expect(find.text('Raider Setup could not be loaded.'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Preview'), findsOneWidget);
    expect(repo.writes, 0);
  });
}
