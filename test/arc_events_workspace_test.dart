import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_event_relevance.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_events_workspace.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

void main() {
  final now = DateTime.utc(2026, 9, 21, 12);
  ArcRegionalMapConditionsSnapshot snapshot({bool captured = false}) =>
      ArcRegionalMapConditionsSnapshot(
        entries: [
          ArcRegionalMapConditionEntry(
            conditionName: 'Hurricane',
            mapDisplayName: 'Dam Battlegrounds',
            duration: const Duration(hours: 1),
            regionWindows: {
              ArcServerRegion.europe: ArcRegionalConditionWindow(
                startUtc: now,
                endUtc: now.add(const Duration(hours: 1)),
              ),
            },
          ),
        ],
        serverNowUtc: now,
        loadedAtUtc: now,
        source: captured
            ? ArcMapConditionsSource.officialCapturedFallback
            : ArcMapConditionsSource.officialLive,
      );

  Future<void> mount(WidgetTester tester, Widget child, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        routes: {
          arcEventsRoute: (_) =>
              const Scaffold(body: Text('Events destination')),
        },
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
    await tester.pump();
  }

  for (final size in [
    const Size(320, 640),
    const Size(430, 932),
    const Size(640, 360),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1024, 768),
    const Size(1280, 900),
  ]) {
    testWidgets('Events renders and scrolls at $size', (tester) async {
      await mount(
        tester,
        ArcEventsWorkspace(
          relevance: const ArcEventRelevance(),
          nowUtc: now,
          conditionsSource: () async => snapshot(),
        ),
        size,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Show all'));
      await tester.pump();
      expect(
        find.text('All events in time order. Times are local.'),
        findsOneWidget,
      );
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -650),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
    testWidgets('Command preview bounded to two rows at $size', (tester) async {
      await mount(
        tester,
        ArcEventsWorkspace(
          relevance: const ArcEventRelevance(),
          nowUtc: now,
          compact: true,
        ),
        size,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key as ValueKey<String>).value.startsWith('event-'),
        ),
        findsNWidgets(2),
      );
      expect(
        tester.getSize(find.byType(ArcEventsWorkspace)).height,
        lessThan(360),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('SHOW ALL EVENTS'));
      await tester.pumpAndSettle();
      expect(find.text('Events destination'), findsOneWidget);
    });
  }

  testWidgets(
    'loading, failure, retry and stale retained data remain distinct',
    (tester) async {
      var future = Completer<ArcRegionalMapConditionsSnapshot>();
      await mount(
        tester,
        ArcEventsWorkspace(
          relevance: const ArcEventRelevance(),
          nowUtc: now,
          conditionsSource: () => future.future,
          slots: const [],
        ),
        const Size(1280, 900),
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('No standard schedule available.'), findsOneWidget);
      future.completeError(StateError('offline'));
      await tester.pump();
      expect(
        find.text('Official source unavailable. Retry conditions.'),
        findsOneWidget,
      );
      future = Completer<ArcRegionalMapConditionsSnapshot>();
      await tester.tap(find.text('REFRESH CONDITIONS'));
      future.complete(snapshot());
      await tester.pump();
      expect(find.textContaining('CURRENT · Hurricane'), findsOneWidget);
      future = Completer<ArcRegionalMapConditionsSnapshot>();
      await tester.tap(find.text('REFRESH CONDITIONS'));
      future.completeError(StateError('offline'));
      await tester.pump();
      expect(
        find.textContaining('CURRENT · UNVERIFIED · Hurricane'),
        findsOneWidget,
      );
      expect(find.textContaining('STALE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('captured fallback is visibly stale, never reported as live', (
    tester,
  ) async {
    await mount(
      tester,
      ArcEventsWorkspace(
        relevance: const ArcEventRelevance(),
        nowUtc: now,
        conditionsSource: () async => snapshot(captured: true),
        slots: const [],
      ),
      const Size(1280, 900),
    );
    expect(
      find.textContaining('Official captured schedule fallback'),
      findsOneWidget,
    );
    expect(find.textContaining('STALE'), findsOneWidget);
    expect(find.textContaining('UNVERIFIED'), findsOneWidget);
  });
}
