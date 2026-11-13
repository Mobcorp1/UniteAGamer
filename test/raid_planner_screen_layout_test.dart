import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/models/raid_planner_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_availability.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';

RaidPlannerScreen screen({
  Stream<RaidPlannerEntitlement> Function()? entitlement,
  List<RaidBlueprintTarget> targets = const [],
}) => RaidPlannerScreen(
  entitlementSource:
      entitlement ??
      () => Stream.value(
        const RaidPlannerEntitlement(tier: RaidPlannerTier.free),
      ),
  targetsSource: () => Stream.value(targets),
  statesSource: () => Stream.value({}),
  availabilitySource: () => Stream.value(ArcAvailability.initial()),
  regionalSource: () async => ArcRegionalMapConditionsSnapshot(
    entries: [],
    serverNowUtc: DateTime.utc(2026, 9, 19),
    loadedAtUtc: DateTime.utc(2026, 9, 19),
    source: ArcMapConditionsSource.officialCapturedFallback,
  ),
);
void main() {
  for (final size in [
    const Size(390, 844),
    const Size(640, 360),
    const Size(740, 360),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1280, 900),
    const Size(1600, 1000),
  ]) {
    testWidgets('Planner workspace ${size.width} x ${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: screen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Saved target schedule').hitTestable(), findsOneWidget);
      expect(
        find.byKey(const Key('planner-wide-layout')),
        size.width >= 980 ? findsOneWidget : findsNothing,
      );
      for (var i = 0; i < 6; i++) {
        final tab = find.byKey(ValueKey('planner-tab-$i'));
        await tester.ensureVisible(tab);
        await tester.pump();
        await tester.tap(tab);
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      final content = size.width >= 980
          ? find.byKey(const ValueKey('planner-page-5'))
          : find.byKey(const ValueKey('planner-page-5'));
      expect(
        tester.getRect(content).bottom,
        lessThanOrEqualTo(
          tester.getRect(find.byType(ArcCompanionBottomDock)).top,
        ),
      );
      expect(find.byTooltip('Planner actions').hitTestable(), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets(
    'Planner never treats entitlement failure as Free empty collection',
    (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: screen(
            entitlement: () {
              attempts++;
              return attempts == 1
                  ? Stream.error(StateError('offline'))
                  : Stream.value(
                      const RaidPlannerEntitlement(tier: RaidPlannerTier.free),
                    );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('Planner data unavailable'), findsOneWidget);
      expect(find.text('No target windows in the next 7 days.'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Saved target schedule'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final size in [
    const Size(390, 844),
    const Size(740, 360),
    const Size(1600, 1000),
  ]) {
    testWidgets('populated target timeline remains readable at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: screen(
            targets: const [
              RaidBlueprintTarget(
                blueprintId: 'surge-coil',
                tier: RaidTargetTier.activeHunt,
                rank: 0,
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Surge Coil').hitTestable(), findsWidgets);
      expect(find.text('No target windows in the next 7 days.'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
