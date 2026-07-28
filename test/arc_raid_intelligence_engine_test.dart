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

    test('injects UAG world population markers into live intelligence', () {
      final intelligence = engine.build(
        mapId: 'buried_city',
        filters: ArcRaidMapFilterState.defaults.copyWith(
          lootSources: true,
          researchedIntel: true,
        ),
      );

      final matches = intelligence.visibleMarkers
          .where(
            (item) =>
                item.label.contains('Town Hall') ||
                item.detail.contains('Town Hall') ||
                item.tags.any((tag) => tag.contains('Town Hall')),
          )
          .toList(growable: false);

      expect(
        matches,
        isNotEmpty,
        reason: intelligence.visibleMarkers
            .map((item) => '${item.label} :: ${item.detail}')
            .join('\n'),
      );
      final marker = matches.first;

      expect(marker.tags, contains('UAG POI Catalogue'));
      expect(marker.tags.any((tag) => tag.contains('evidence')), isTrue);
      expect(marker.detail, contains('Town Hall'));
    });

    test(
      'supports new provisional maps in live marker and route pipelines',
      () {
        const spaceportMarker = ArcAdminMapMarker(
          id: 'spaceport_level_2_cache',
          mapId: 'spaceport',
          layer: ArcRaidMapLayer.underground,
          kind: ArcAdminMapMarkerKind.lootContainer,
          name: 'Level 2 Cache',
          point: ArcNormalizedPoint(x: 0.58, y: 0.44),
          confidence: ArcRaidIntelConfidence.moderate,
          state: ArcAdminMapMarkerState.published,
          adminVerified: false,
          sourceName: 'Permitted source',
          sourceRecordId: 'level-2-cache',
        );

        final spaceport = engine.build(
          mapId: 'spaceport',
          activeLayer: ArcRaidMapLayer.underground,
          adminMarkers: const [spaceportMarker],
          filters: ArcRaidMapFilterState.defaults.copyWith(lootSources: true),
        );

        expect(
          spaceport.map.hasRenderableLayer(ArcRaidMapLayer.surface),
          isTrue,
        );
        expect(
          spaceport.map.hasRenderableLayer(ArcRaidMapLayer.underground),
          isTrue,
        );
        expect(spaceport.activeLayer, ArcRaidMapLayer.underground);
        expect(
          spaceport.visibleMarkers.map((marker) => marker.label),
          contains('Level 2 Cache'),
        );

        final dam = ArcRaidIntelligenceSeedData.mapById('dam_battlegrounds');
        final route = engine.generateRoute(
          map: dam,
          clusters: engine.opportunityClusters(map: dam),
          spawn: engine.stopFromSpawn(dam.spawnRegions.first),
          extraction: engine.stopFromExtraction(dam.extractions.first),
        );

        expect(dam.hasRenderableLayer(ArcRaidMapLayer.surface), isTrue);
        expect(route, isNotNull);
        expect(route!.orderedStops.first.label, dam.spawnRegions.first.name);
      },
    );

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
