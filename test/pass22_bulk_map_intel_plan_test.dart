import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bulk_map_intel_plan.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  test(
    'one resource can be drafted across multiple maps and multiple POIs',
    () {
      final eligible = ArcRaidIntelligenceSeedData.maps
          .where((m) => m.pois.length >= 2)
          .take(2)
          .toList();
      expect(eligible.length, 2);
      final plan = ArcBulkIntelPlan.build(
        ArcBulkIntelRequest(
          kind: ArcAdminMapMarkerKind.naturalResource,
          name: 'Mushroom',
          mapPoiIds: {
            for (final map in eligible)
              map.id: {map.pois.first.id, map.pois[1].id},
          },
          containerTypeIds: const <String>{},
          noContainer: true,
          confidence: ArcRaidIntelConfidence.moderate,
          subtypeId: 'mushroom',
        ),
      );
      expect(plan.markers.length, 4);
      expect(plan.unlocated, isEmpty);
      expect(plan.markers.map((m) => m.id).toSet().length, 4);
      for (final marker in plan.markers) {
        expect(marker.state, ArcAdminMapMarkerState.draft);
        expect(marker.provisionalVisible, isFalse);
        expect(marker.containerTypeIds, isEmpty);
        expect(marker.coordinateSpace, 'poi_approximate');
        final map = ArcRaidIntelligenceSeedData.mapById(marker.mapId);
        expect(
          map.pois.any(
            (poi) => poi.id == marker.poiId && poi.point.x == marker.point.x,
          ),
          isTrue,
        );
        expect(ArcAdminMapMarker.fromMap(marker.toMap()).poiId, marker.poiId);
      }
    },
  );

  test(
    'unknown POI creates unlocated map intelligence, not a phantom marker',
    () {
      final map = ArcRaidIntelligenceSeedData.maps.first;
      final plan = ArcBulkIntelPlan.build(
        ArcBulkIntelRequest(
          kind: ArcAdminMapMarkerKind.blueprint,
          name: 'Historical Blueprint',
          blueprintId: 'test-blueprint',
          mapPoiIds: {map.id: const <String>{}},
          containerTypeIds: const {'weapon_case', 'security_locker'},
          noContainer: false,
          confidence: ArcRaidIntelConfidence.limited,
        ),
      );
      expect(plan.markers, isEmpty);
      expect(plan.unlocated.length, 1);
      expect(plan.unlocated.single.toMap().containsKey('point'), isFalse);
      expect(
        plan.unlocated.single.toMap()['locationPrecision'],
        'map_wide_unlocated',
      );
      expect(plan.unlocated.single.containerTypeIds.length, 2);
      expect(plan.unlocated.single.toMap()['state'], 'draft');
    },
  );

  test('invalid POIs and contradictory containers fail closed', () {
    final map = ArcRaidIntelligenceSeedData.maps.first;
    ArcBulkIntelRequest makeRequest(
      Set<String> pois, {
      bool noContainer = true,
    }) => ArcBulkIntelRequest(
      kind: ArcAdminMapMarkerKind.naturalResource,
      name: 'Agave',
      mapPoiIds: {map.id: pois},
      containerTypeIds: const {'weapon_case'},
      noContainer: noContainer,
      confidence: ArcRaidIntelConfidence.unverified,
    );
    expect(
      () => ArcBulkIntelPlan.build(
        makeRequest({'not-a-real-poi'}, noContainer: false),
      ),
      throwsArgumentError,
    );
    expect(() => ArcBulkIntelPlan.build(makeRequest({})), throwsArgumentError);
  });

  test('identical bulk selection produces stable non-duplicating IDs', () {
    final map = ArcRaidIntelligenceSeedData.maps.firstWhere(
      (m) => m.pois.isNotEmpty,
    );
    final request = ArcBulkIntelRequest(
      kind: ArcAdminMapMarkerKind.weaponCase,
      name: 'Weapon Case',
      mapPoiIds: {
        map.id: {map.pois.first.id},
      },
      containerTypeIds: const {'weapon_case'},
      noContainer: false,
      confidence: ArcRaidIntelConfidence.limited,
    );
    expect(
      ArcBulkIntelPlan.build(request).markers.single.id,
      ArcBulkIntelPlan.build(request).markers.single.id,
    );
  });
}
