import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  group('ArcRaidIntelligenceEngine', () {
    const engine = ArcRaidIntelligenceEngine();

    test('builds personalized blueprint opportunity clusters', () {
      final target = ArcBlueprintSeedData.blueprints.first;
      final states = _statesWithOnlyMissing(target.id, priorityRank: 1);

      final intelligence = engine.build(
        mapId: 'blue_gate',
        blueprintStates: states,
      );

      expect(intelligence.map.id, 'blue_gate');
      expect(intelligence.opportunityClusters, isNotEmpty);
      expect(
        intelligence.opportunityClusters.expand(
          (cluster) => cluster.blueprintIds,
        ),
        contains(target.id),
      );
      expect(intelligence.statusLabel, 'Generate a run');
      expect(
        intelligence.visibleMarkers.any((marker) => marker.count > 0),
        isTrue,
      );
    });

    test('keeps loot markers hidden until the loot filter is enabled', () {
      final defaultState = engine.build(mapId: 'blue_gate');
      final lootState = engine.build(
        mapId: 'blue_gate',
        filters: ArcRaidMapFilterState.defaults.copyWith(lootSources: true),
      );

      expect(
        defaultState.visibleMarkers.any(
          (marker) => marker.category.filteringGroup == 'Loot Sources',
        ),
        isFalse,
      );
      expect(
        lootState.visibleMarkers.any(
          (marker) => marker.category.filteringGroup == 'Loot Sources',
        ),
        isTrue,
      );
    });

    test('merges live admin import markers into visible intelligence', () {
      const imported = ArcAdminMapMarker(
        id: 'imported_cache',
        mapId: 'blue_gate',
        layer: ArcRaidMapLayer.surface,
        kind: ArcAdminMapMarkerKind.weaponCache,
        name: 'Imported Cache',
        point: ArcNormalizedPoint(x: 0.61, y: 0.32),
        confidence: ArcRaidIntelConfidence.strong,
        state: ArcAdminMapMarkerState.published,
        adminVerified: false,
        sourceName: 'Permitted source',
        sourceRecordId: 'cache-1',
      );

      final intelligence = engine.build(
        mapId: 'blue_gate',
        adminMarkers: const [imported],
        filters: ArcRaidMapFilterState.defaults.copyWith(lootSources: true),
      );

      expect(
        intelligence.visibleMarkers.map((marker) => marker.label),
        contains('Imported Cache'),
      );
      expect(
        intelligence.visibleMarkers
            .firstWhere((marker) => marker.label == 'Imported Cache')
            .tags,
        contains('Permitted source'),
      );
    });

    test('generates deterministic route limits by raid stage and style', () {
      final map = ArcRaidIntelligenceSeedData.mapById('The Blue Gate');
      final clusters = engine.opportunityClusters(map: map);
      final spawn = engine.stopFromSpawn(map.spawnRegions.first);
      final extraction = engine.stopFromExtraction(map.extractions.first);

      final full = engine.generateRoute(
        map: map,
        clusters: clusters,
        spawn: spawn,
        extraction: extraction,
        routeStyle: ArcRaidRouteStyle.thorough,
        raidStage: 'Full',
      );
      final late = engine.generateRoute(
        map: map,
        clusters: clusters,
        spawn: spawn,
        extraction: extraction,
        routeStyle: ArcRaidRouteStyle.thorough,
        raidStage: 'Late',
      );

      expect(full, isNotNull);
      expect(late, isNotNull);
      expect(full!.stops.length, lessThanOrEqualTo(5));
      expect(late!.stops.length, 2);
      expect(full.orderedStops.first.label, spawn.label);
      expect(full.orderedStops.last.label, extraction.label);
      expect(full.approximate, isTrue);
    });

    test('requires hatch key confirmation for Raider Hatch routes', () {
      final map = ArcRaidIntelligenceSeedData.mapById('blue_gate');
      final clusters = engine.opportunityClusters(map: map);
      final spawn = engine.stopFromSpawn(map.spawnRegions.first);
      final hatch = engine.stopFromHatch(map.hatches.first);

      expect(
        engine.generateRoute(
          map: map,
          clusters: clusters,
          spawn: spawn,
          extraction: hatch,
          usesRaiderHatch: true,
          hatchKeyConfirmed: false,
        ),
        isNull,
      );
      expect(
        engine.generateRoute(
          map: map,
          clusters: clusters,
          spawn: spawn,
          extraction: hatch,
          usesRaiderHatch: true,
          hatchKeyConfirmed: true,
        ),
        isNotNull,
      );
    });

    test('supports route editing state transitions', () {
      final map = ArcRaidIntelligenceSeedData.mapById('blue_gate');
      final clusters = engine.opportunityClusters(map: map);
      final route = engine.generateRoute(
        map: map,
        clusters: clusters,
        spawn: engine.stopFromSpawn(map.spawnRegions.first),
        extraction: engine.stopFromExtraction(map.extractions.first),
      )!;

      final added = engine.addStop(route, clusters.last);
      final searched = engine.markStop(
        added,
        added.stops.first.id,
        ArcRaidRouteStopState.searched,
      );
      final removed = engine.removeStop(searched, searched.stops.first.id);

      expect(added.stops.length, route.stops.length + 1);
      expect(searched.stops.first.state, ArcRaidRouteStopState.searched);
      expect(
        removed.stops.any((stop) => stop.id == searched.stops.first.id),
        isFalse,
      );
      expect(removed.extraction.order, removed.stops.length + 1);
    });

    test('calculates explainable confidence from evidence', () {
      expect(
        engine.confidenceForEvidence(
          independentReportCount: 4,
          age: const Duration(days: 3),
          coordinateAgreement: true,
          sourceAgreement: true,
          hasEvidence: true,
        ),
        ArcRaidIntelConfidence.strong,
      );
      expect(
        engine.confidenceForEvidence(
          independentReportCount: 0,
          age: const Duration(days: 90),
          hasConflicts: true,
        ),
        ArcRaidIntelConfidence.unverified,
      );
    });
  });
}

Map<String, ArcBlueprintState> _statesWithOnlyMissing(
  String missingId, {
  int priorityRank = 0,
}) {
  return {
    for (final blueprint in ArcBlueprintSeedData.blueprints)
      blueprint.id: ArcBlueprintState(
        blueprintId: blueprint.id,
        owned: blueprint.id != missingId,
        dupesOwned: 0,
        priorityRank: blueprint.id == missingId ? priorityRank : 0,
        updatedAt: null,
      ),
  };
}
