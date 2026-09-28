import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_intelligence_workspace_bar.dart';

void main() {
  test('player guidance has no seeded or operational source terminology', () {
    const root = 'lib/features/trading_hub/arc_raiders/';
    for (final path in [
      'raid_planner/screens/raid_planner_screen.dart',
      'raid_planner/data/raid_planner_engine.dart',
      'widgets/arc_intelligence_workspace_bar.dart',
      'widgets/arc_blueprint_intel_card.dart',
      'widgets/arc_blueprint_sighting_activity.dart',
      'widgets/arc_events_workspace.dart',
      'widgets/arc_loadout_intelligence_summary.dart',
      'screens/operations_command_screen.dart',
      'screens/arc_raid_intelligence_screen.dart',
      'data/arc_blueprint_intel_seed.dart',
      'data/arc_blueprint_sighting_aggregator.dart',
    ]) {
      final source = File('$root$path')
          .readAsStringSync()
          .replaceAll(RegExp(r'\$\{[^}]*\}'), '')
          .replaceAll(RegExp(r'\$[a-zA-Z_]\w*'), '');
      final literals = RegExp(
        r"'([^'\n]*)'",
      ).allMatches(source).map((m) => m[1]!).join('\n');
      expect(
        literals,
        isNot(
          matches(
            RegExp(
              r'\b(seeded|seed data|seed map|seed route|seed containers|seed condition|MetaForge|fixture|dummy|mock|hardcoded|Firestore|official source|official tracker|official ARC Raiders schedule|refreshed from the live source)\b',
              caseSensitive: false,
            ),
          ),
        ),
        reason: path,
      );
    }
  });

  final base = DateTime.utc(2026, 9, 28, 12);
  ArcRegionalMapConditionsSnapshot snapshot({bool captured = false}) =>
      ArcRegionalMapConditionsSnapshot(
        entries: [
          ArcRegionalMapConditionEntry(
            conditionName: 'Night Raid',
            mapDisplayName: 'Buried City',
            duration: const Duration(minutes: 30),
            regionWindows: {
              for (final region in ArcServerRegion.values)
                region: ArcRegionalConditionWindow(
                  startUtc: base.subtract(const Duration(minutes: 5)),
                  endUtc: base.add(const Duration(seconds: 30)),
                ),
            },
          ),
        ],
        serverNowUtc: base,
        loadedAtUtc: base,
        source: captured
            ? ArcMapConditionsSource.officialCapturedFallback
            : ArcMapConditionsSource.officialLive,
      );

  testWidgets(
    'condition clock expires windows without user interaction and regions are unique',
    (tester) async {
      var now = base;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArcLiveMapConditionsStrip(
              loadConditions: () async => snapshot(),
              nowUtc: () => now,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('LIVE REGIONAL CONDITIONS'), findsOneWidget);
      expect(find.textContaining('Night Raid'), findsWidgets);
      now = base.add(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 15));
      expect(find.textContaining('Night Raid'), findsNothing);
      await tester.tap(find.byTooltip('ARC server region'));
      await tester.pumpAndSettle();
      final entries = tester.widgetList<PopupMenuItem<ArcServerRegion>>(
        find.byType(PopupMenuItem<ArcServerRegion>),
      );
      expect(entries.length, ArcServerRegion.values.length);
      expect(entries.map((e) => e.value).toSet().length, entries.length);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final captured in [false, true]) {
    testWidgets(
      '${captured ? 'captured' : 'expired'} schedule is not labelled live',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ArcLiveMapConditionsStrip(
                loadConditions: () async => snapshot(captured: captured),
                nowUtc: () => base.add(const Duration(days: 1)),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('SAVED REGIONAL CONDITIONS'), findsOneWidget);
        expect(
          find.textContaining('Saved times may be out of date'),
          findsOneWidget,
        );
        expect(find.textContaining('Night Raid'), findsNothing);
        expect(find.textContaining('Official'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('condition failures are human readable and retry recovers', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArcLiveMapConditionsStrip(
            loadConditions: () async {
              if (++attempts == 1) {
                throw StateError(
                  'parser API admin_hatch_753bc1fa-66af-4cc5-a280-711b4127e5d7',
                );
              }
              return snapshot();
            },
            nowUtc: () => base,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.text('Map conditions unavailable. Please retry.'),
      findsOneWidget,
    );
    expect(find.textContaining('753bc1fa'), findsNothing);
    expect(find.textContaining('parser'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(find.text('LIVE REGIONAL CONDITIONS'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
