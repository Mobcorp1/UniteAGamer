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

  for (final size in [
    const Size(390, 844),
    const Size(740, 360),
    const Size(1280, 900),
  ]) {
    testWidgets(
      'saved admin hatch route survives delayed, duplicate, deleted and failed marker streams at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final markers = StreamController<List<ArcAdminMapMarker>>();
        addTearDown(markers.close);
        await tester.pumpWidget(
          MaterialApp(
            home: ArcRaidIntelligenceScreen(
              blueprintStates: () => Stream.value({}),
              favouriteLoadout: () => Stream.value(null),
              dropReports: () => Stream.value([]),
              communityReports: (_) => Stream.value([]),
              publishedMarkers: (_) => markers.stream,
              scrappyStates: () => Stream.value({}),
              progressionRecords: () =>
                  Stream.value(ArcProgressionRecords.empty),
              loadActiveRoute: () async => const ArcRaidRoutePlan(
                id: 'saved_route',
                mapId: 'buried_city',
                mapName: 'Buried City',
                squadMode: ArcRaidSquadMode.solo,
                routeStyle: ArcRaidRouteStyle.balanced,
                raidStage: 'Full',
                objectivePriority: ArcRaidObjectivePriority.myNeedsFirst,
                spawn: ArcRaidRouteStop(
                  id: 'freeform_spawn',
                  label: 'Spawn',
                  point: ArcNormalizedPoint(x: .2, y: .2),
                  order: 0,
                ),
                extraction: stop,
                stops: [],
                usesRaiderHatch: true,
                hatchKeyConfirmed: true,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.byTooltip('Map tools'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.scrollUntilVisible(
          find.byWidgetPredicate(
            (widget) =>
                widget is ArcRaidLocationPicker &&
                widget.label == 'Raider Hatch',
          ),
          250,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(find.byType(ArcRaidLocationPicker), findsNWidgets(2));
        expect(tester.takeException(), isNull);
        for (final records in [
          <ArcAdminMapMarker>[marker, marker],
          <ArcAdminMapMarker>[],
          <ArcAdminMapMarker>[marker],
        ]) {
          markers.add(records);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
        }
        markers.add([]);
        await tester.pump();
        await tester.scrollUntilVisible(
          find.text('BUILD MY RAID'),
          150,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pump(const Duration(milliseconds: 300));
        await Scrollable.ensureVisible(
          tester.element(find.text('BUILD MY RAID')),
          alignment: 0.5,
        );
        await tester.pump();
        expect(find.text('BUILD MY RAID').hitTestable(), findsOneWidget);
        await tester.tap(find.text('BUILD MY RAID'));
        await tester.pump();
        expect(
          find.text(
            'Saved extraction is unavailable. Choose another extraction.',
          ),
          findsOneWidget,
        );
        markers.addError(StateError('Firestore $hatchId'));
        await tester.pump();
        expect(
          find.textContaining('Some intel is unavailable'),
          findsOneWidget,
        );
        expect(find.textContaining(markerId), findsNothing);
        expect(find.textContaining('Firestore'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 500));
      },
    );
  }
}
