import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_runtime_map_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_raid_location_picker.dart';

const markerId =
    'admin_buried_city_surface_753bc1fa-66af-4cc5-a280-711b4127e5d7';
const hatchId = 'admin_hatch_$markerId';
const stop = ArcRaidRouteStop(
  id: hatchId,
  label: 'Saved hatch',
  point: ArcNormalizedPoint(x: .5, y: .5),
  order: 1,
);
const marker = ArcAdminMapMarker(
  id: markerId,
  mapId: 'buried_city',
  layer: ArcRaidMapLayer.surface,
  kind: ArcAdminMapMarkerKind.raiderHatch,
  name: 'Saved hatch',
  point: ArcNormalizedPoint(x: .5, y: .5),
  state: ArcAdminMapMarkerState.published,
);

const guidedSpawnMarker = ArcAdminMapMarker(
  id: 'guided_blue_gate_player_spawn',
  mapId: 'blue_gate',
  layer: ArcRaidMapLayer.surface,
  kind: ArcAdminMapMarkerKind.poi,
  name: 'Player Spawn',
  subtypeId: 'player_spawn',
  point: ArcNormalizedPoint(x: .28, y: .32),
  state: ArcAdminMapMarkerState.published,
);
const guidedMetroMarker = ArcAdminMapMarker(
  id: 'guided_blue_gate_metro',
  mapId: 'blue_gate',
  layer: ArcRaidMapLayer.surface,
  kind: ArcAdminMapMarkerKind.extraction,
  name: 'Metro Station',
  subtypeId: 'metro_station',
  point: ArcNormalizedPoint(x: .72, y: .67),
  state: ArcAdminMapMarkerState.published,
);
const guidedHatchMarker = ArcAdminMapMarker(
  id: 'guided_blue_gate_hatch',
  mapId: 'blue_gate',
  layer: ArcRaidMapLayer.surface,
  kind: ArcAdminMapMarkerKind.raiderHatch,
  name: 'Raider Hatch',
  subtypeId: 'raider_hatch',
  point: ArcNormalizedPoint(x: .64, y: .38),
  state: ArcAdminMapMarkerState.published,
);
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final kind in [
    ArcAdminMapMarkerKind.raiderHatch,
    ArcAdminMapMarkerKind.extraction,
  ]) {
    test('runtime $kind deduplicates records and shared stable references', () {
      final old = marker.copyWith(
        kind: kind,
        updatedAt: DateTime.utc(2026, 9, 1),
      );
      final latest = old.copyWith(
        name: 'Current location',
        updatedAt: DateTime.utc(2026, 9, 28),
      );
      final shared = old.copyWith(
        id: 'another_record',
        seedReferenceId: 'shared_location',
      );
      final duplicateReference = shared.copyWith(id: 'third_record');
      final result = const ArcRaidRuntimeMapResolver().resolve(
        seedMap: ArcRaidIntelligenceSeedData.mapById('buried_city'),
        adminMarkers: [old, latest, shared, duplicateReference],
      );
      final ids = kind == ArcAdminMapMarkerKind.raiderHatch
          ? result.hatches.map((e) => e.id).toList()
          : result.extractions.map((e) => e.id).toList();
      final names = kind == ArcAdminMapMarkerKind.raiderHatch
          ? result.hatches.map((e) => e.name)
          : result.extractions.map((e) => e.name);
      expect(ids.toSet().length, ids.length);
      expect(ids.where((id) => id == 'shared_location'), hasLength(1));
      expect(names, contains('Current location'));
    });
  }

  testWidgets(
    'duplicate and stale saved IDs remain safe across refresh and deletion',
    (tester) async {
      Future<void> pump(List<ArcRaidRouteStop> options) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ArcRaidLocationPicker(
                label: 'Raider Hatch',
                options: options,
                selected: stop,
                onChanged: (_) {},
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final dropdown = tester.widget<DropdownButton<String>>(
          find.byType(DropdownButton<String>),
        );
        expect(dropdown.value, hatchId);
        expect(
          dropdown.items!.map((item) => item.value).toSet().length,
          dropdown.items!.length,
        );
        expect(find.textContaining(markerId), findsNothing);
      }

      await pump([]);
      expect(
        find.text('Saved location unavailable — choose another'),
        findsOneWidget,
      );
      await pump([stop, stop]);
      expect(find.text('Saved hatch'), findsOneWidget);
      await pump([]);
      expect(
        find.text('Saved location unavailable — choose another'),
        findsOneWidget,
      );
      await pump([stop]);
      expect(find.text('Saved hatch'), findsOneWidget);
    },
  );

  test('published player-spawn pins replace generic seed spawn bands', () {
    final result = const ArcRaidRuntimeMapResolver().resolve(
      seedMap: ArcRaidIntelligenceSeedData.mapById('blue_gate'),
      adminMarkers: const [guidedSpawnMarker],
    );

    expect(result.spawnRegions, hasLength(1));
    expect(result.spawnRegions.single.name, 'Player Spawn');
    expect(result.spawnRegions.single.center.x, closeTo(.28, .0001));
    expect(result.spawnRegions.single.center.y, closeTo(.32, .0001));
    expect(result.spawnRegions.single.radius, lessThan(.04));
  });

  for (final size in [
    const Size(390, 844),
    const Size(740, 360),
    const Size(1280, 900),
  ]) {
    testWidgets(
      'guided setup uses physical spawn then raid stage then extraction pins at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: ArcRaidIntelligenceScreen(
              blueprintStates: () => Stream.value({}),
              favouriteLoadout: () => Stream.value(null),
              dropReports: () => Stream.value([]),
              communityReports: (_) => Stream.value([]),
              publishedMarkers: (_) => Stream.value(const [
                guidedSpawnMarker,
                guidedMetroMarker,
                guidedHatchMarker,
              ]),
              scrappyStates: () => Stream.value({}),
              progressionRecords: () =>
                  Stream.value(ArcProgressionRecords.empty),
              loadActiveRoute: () async => null,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(ArcRaidLocationPicker), findsNothing);
        expect(find.byKey(const Key('raid-map-step-spawn')), findsOneWidget);
        expect(find.byTooltip('Spawn: Player Spawn'), findsOneWidget);

        await tester.tap(find.byTooltip('Spawn: Player Spawn'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.byKey(const Key('raid-map-step-raidStage')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('raid-stage-full')), findsOneWidget);
        expect(find.byKey(const Key('raid-stage-mid')), findsOneWidget);
        expect(find.byKey(const Key('raid-stage-near-end')), findsOneWidget);

        await tester.tap(find.byKey(const Key('raid-stage-mid')));
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.byKey(const Key('raid-map-step-extraction')),
          findsOneWidget,
        );
        expect(
          find.byTooltip('Standard Extraction: Metro Station'),
          findsOneWidget,
        );
        expect(find.byTooltip('Raider Hatch: Raider Hatch'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
