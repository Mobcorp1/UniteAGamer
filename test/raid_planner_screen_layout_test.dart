import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/models/raid_planner_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_availability.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_companion_bottom_dock.dart';

RaidPlannerScreen screen({
  Stream<RaidPlannerEntitlement> Function()? entitlement,
  List<RaidBlueprintTarget> targets = const [],
  ArcAvailability? availability,
  List<TradingListing> listings = const [],
  Future<ArcRegionalMapConditionsSnapshot> Function()? regional,
}) => RaidPlannerScreen(
  entitlementSource:
      entitlement ??
      () => Stream.value(
        const RaidPlannerEntitlement(tier: RaidPlannerTier.free),
      ),
  targetsSource: () => Stream.value(targets),
  statesSource: () => Stream.value({}),
  availabilitySource: () =>
      Stream.value(availability ?? ArcAvailability.initial()),
  nowSource: () => DateTime(2026, 10, 6, 18),
  myListingsSource: () => Stream.value(listings),
  currentUidSource: () => 'me',
  regionalSource:
      regional ??
      () async => ArcRegionalMapConditionsSnapshot(
        entries: [
          for (final condition in ['Harvester', 'Electromagnetic Storm'])
            ArcRegionalMapConditionEntry(
              conditionName: condition,
              mapDisplayName: 'Dam Battlegrounds',
              duration: const Duration(hours: 1),
              regionWindows: {
                ArcServerRegion.europe: ArcRegionalConditionWindow(
                  startUtc: DateTime(2026, 10, 6, 20).toUtc(),
                  endUtc: DateTime(2026, 10, 6, 21).toUtc(),
                ),
              },
            ),
        ],
        serverNowUtc: DateTime(2026, 10, 6, 18).toUtc(),
        loadedAtUtc: DateTime(2026, 10, 6, 18).toUtc(),
        source: ArcMapConditionsSource.officialLive,
      ),
);
ArcAvailability savedPlaytime() => const ArcAvailability(
  scheduleType: 'weekly',
  useEveryWeek: true,
  weeks: [
    ArcAvailabilityWeek(
      label: 'Week 1',
      slots: [
        ArcAvailabilitySlot(
          dayKey: 'tue',
          enabled: true,
          fromTime: '19:00',
          toTime: '23:00',
        ),
      ],
    ),
  ],
);

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(430, 932),
    const Size(640, 360),
    const Size(740, 360),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1024, 768),
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
      expect(find.text("TODAY'S RAID INTEL").hitTestable(), findsOneWidget);
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
        expect(tester.takeException(), isNull, reason: 'tab $i');
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
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump();
      }
      expect(find.textContaining('Planner data unavailable'), findsOneWidget);
      expect(find.text('NO ACTIVE TARGETS'), findsNothing);
      await tester.tap(find.text('Retry'));
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump();
      }
      expect(find.text("TODAY'S RAID INTEL"), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(430, 932),
    const Size(640, 360),
    const Size(740, 360),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1024, 768),
    const Size(1280, 900),
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
            availability: savedPlaytime(),
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
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump();
      }
      await tester.ensureVisible(find.text('TARGET: Surge Coil Blueprint'));
      await tester.pump();
      expect(
        find.text('TARGET: Surge Coil Blueprint').hitTestable(),
        findsWidgets,
      );
      expect(find.text('NO ACTIVE TARGETS'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  Future<void> load(WidgetTester tester, RaidPlannerScreen planner) async {
    await tester.pumpWidget(MaterialApp(home: planner));
    for (var frame = 0; frame < 7; frame++) {
      await tester.pump();
    }
  }

  testWidgets('empty data prompts for playtime and then explicit objectives', (
    tester,
  ) async {
    await load(tester, screen());
    expect(find.text('SET YOUR PLAYTIME'), findsOneWidget);
    expect(find.text('OUTSIDE PLAYTIME'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await load(tester, screen(availability: savedPlaytime()));
    expect(find.text('NO ACTIVE TARGETS'), findsOneWidget);
    expect(find.textContaining('TARGET:'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'explicit Condition Item Finder intent updates one primary feed',
    (tester) async {
      await load(tester, screen(availability: savedPlaytime()));
      final objectives = find.byKey(const ValueKey('planner-tab-3'));
      await tester.ensureVisible(objectives);
      await tester.tap(objectives);
      await tester.pump(const Duration(milliseconds: 350));
      final dropdown = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Queen Reactor / Queen Parts').last);
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('NO ACTIVE TARGETS'), findsNothing);
      expect(find.text('TARGET: Queen Reactor / Queen Parts'), findsOneWidget);
      expect(find.textContaining('HARVESTER'), findsOneWidget);
      expect(find.textContaining('ELECTROMAGNETIC STORM'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'current-player wanted item drives the feed without manual selection',
    (tester) async {
      await load(
        tester,
        screen(
          availability: savedPlaytime(),
          listings: [
            TradingListing.empty().copyWith(
              ownerUid: 'me',
              wantedTradeItemNames: ['Queen Reactor'],
              expiresAt: DateTime(2026, 10, 7),
            ),
          ],
        ),
      );
      expect(find.text('TARGET: Queen Reactor / Queen Parts'), findsOneWidget);
      expect(find.textContaining('ELECTROMAGNETIC STORM'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('schedule failure is visible and can be retried', (tester) async {
    var calls = 0;
    await load(
      tester,
      screen(
        availability: savedPlaytime(),
        regional: () async {
          calls++;
          if (calls == 1) throw StateError('offline');
          return ArcRegionalMapConditionsSnapshot(
            entries: [],
            serverNowUtc: DateTime(2026, 10, 6, 18),
            loadedAtUtc: DateTime(2026, 10, 6, 18),
            source: ArcMapConditionsSource.officialLive,
          );
        },
      ),
    );
    expect(
      find.textContaining('Regional conditions unavailable.'),
      findsOneWidget,
    );
    expect(find.text('NO ACTIVE TARGETS'), findsNothing);
    await tester.tap(find.text('Retry conditions'));
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump();
    }
    expect(find.text('NO ACTIVE TARGETS'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('manual Event Finder stays empty until meaningful search', (
    tester,
  ) async {
    await load(tester, screen(availability: savedPlaytime()));
    await tester.tap(find.byKey(const ValueKey('planner-tab-1')));
    await tester.pump();
    await tester.tap(find.text('Event Finder').last);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Type at least 2 characters.'), findsOneWidget);
    expect(find.textContaining('Harvester - Dam'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Harvester');
    await tester.pump();
    expect(find.text('Harvester - Dam Battlegrounds'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
