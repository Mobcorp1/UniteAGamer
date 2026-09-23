import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_runtime_map_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  const engine = ArcRaidIntelligenceEngine();

  test('published named POI geometry becomes the research source of truth', () {
    final states = _statesWithOnlyMissing('extended-shotgun-mag-iii');
    const movedVillage = ArcAdminMapMarker(
      id: 'published_blue_gate_village',
      mapId: 'blue_gate',
      layer: ArcRaidMapLayer.surface,
      kind: ArcAdminMapMarkerKind.poi,
      name: 'Village',
      point: ArcNormalizedPoint(x: 0.91, y: 0.14),
      state: ArcAdminMapMarkerState.published,
      adminVerified: true,
      seedReferenceId: 'blue_gate_village',
    );

    final intelligence = engine.build(
      mapId: 'blue_gate',
      blueprintStates: states,
      adminMarkers: const <ArcAdminMapMarker>[movedVillage],
    );

    final village = intelligence.map.pois.firstWhere(
      (poi) => poi.id == 'blue_gate_village',
    );
    expect(village.point.x, closeTo(movedVillage.point.x, 0.000001));
    expect(village.point.y, closeTo(movedVillage.point.y, 0.000001));

    final researched = intelligence.opportunityClusters.firstWhere(
      (cluster) =>
          cluster.poiId == 'blue_gate_village' &&
          cluster.blueprintIds.contains('extended-shotgun-mag-iii'),
    );
    expect(researched.point.x, closeTo(movedVillage.point.x, 0.000001));
    expect(researched.point.y, closeTo(movedVillage.point.y, 0.000001));
    expect(researched.evidence.single.sourceCategory, 'uag_research_baseline');
    expect(
      researched.evidence.single.notes,
      contains('not a guaranteed Blueprint spawn'),
    );
  });

  test('community report remains the POI anchor when research overlaps it', () {
    final report = ArcBlueprintDropReport(
      id: 'gifted_original',
      blueprintId: 'anvil',
      userId: 'raider_1',
      mapName: ArcPoiDataStore.spaceport,
      sourceType: ArcDropSourceType.other,
      originalFindMapName: ArcPoiDataStore.blueGate,
      originalFindPoiId: 'blue_gate_warehouse_complex',
      originalFindPoiName: 'Warehouse Complex',
      handoverMapName: ArcPoiDataStore.spaceport,
      handoverPoiName: 'Launch Tower',
      acquisitionSource: ArcBlueprintAcquisitionSource.giftedBySquadmate,
      giftRelationship: ArcGiftedBlueprintRelationship.squadmate,
      mode: ArcRaidMode.dayRaid,
      raidType: ArcRaidType.fullRaid,
      entryTime: ArcEntryTime.unknown,
      timeOfDay: ArcTimeOfDay.unknown,
      createdAt: DateTime.utc(2026, 9, 23),
      confirmationCount: 2,
      confirmedByUserIds: const <String>['raider_1', 'raider_2'],
    );

    final intelligence = engine.build(
      mapId: 'blue_gate',
      dropReports: <ArcBlueprintDropReport>[report],
    );
    final reportCluster = intelligence.opportunityClusters.firstWhere(
      (cluster) => cluster.evidence.any(
        (evidence) => evidence.sourceCategory == 'community_drop_report',
      ),
    );
    final reportMarker = intelligence.visibleMarkers.firstWhere(
      (marker) =>
          marker.category == ArcRaidMapMarkerCategory.blueprintOpportunity &&
          marker.tags.contains('Drop Reports') &&
          marker.blueprintIds.contains('anvil'),
    );

    expect(reportCluster.label, contains('Warehouse Complex'));
    expect(reportCluster.reportCount, 2);
    expect(reportCluster.independentReporterCount, 2);
    expect(reportMarker.label, contains('Warehouse Complex'));
    expect(reportMarker.approximate, isFalse);
  });

  test(
    'published extraction markers populate missing runtime route choices',
    () {
      final seed = ArcRaidIntelligenceSeedData.mapById('riven_tides');
      const publishedExit = ArcAdminMapMarker(
        id: 'riven_published_exit',
        mapId: 'riven_tides',
        layer: ArcRaidMapLayer.surface,
        kind: ArcAdminMapMarkerKind.extraction,
        name: 'Community Gate Exit',
        point: ArcNormalizedPoint(x: 0.82, y: 0.76),
        state: ArcAdminMapMarkerState.published,
        adminVerified: true,
        seedReferenceId: 'riven_community_gate_exit',
      );

      final resolved = const ArcRaidRuntimeMapResolver().resolve(
        seedMap: seed,
        adminMarkers: const <ArcAdminMapMarker>[publishedExit],
      );

      expect(
        resolved.extractions.any(
          (extraction) =>
              extraction.name == 'Community Gate Exit' &&
              (extraction.point.x - publishedExit.point.x).abs() < 0.000001 &&
              (extraction.point.y - publishedExit.point.y).abs() < 0.000001,
        ),
        isTrue,
      );
    },
  );

  test('objective-only ordering works before extraction data is synced', () {
    final states = _statesWithOnlyMissing('extended-shotgun-mag-iii');
    final intelligence = engine.build(
      mapId: 'blue_gate',
      blueprintStates: states,
    );
    const spawn = ArcRaidRouteStop(
      id: 'freeform_spawn',
      label: 'Approximate Spawn',
      point: ArcNormalizedPoint(x: 0.2, y: 0.2),
      order: 0,
    );

    final stops = engine.orderObjectiveStops(
      map: intelligence.map,
      clusters: intelligence.opportunityClusters,
      spawn: spawn,
      routeStyle: ArcRaidRouteStyle.balanced,
      raidStage: 'Full',
    );

    expect(stops, isNotEmpty);
    expect(
      stops.expand((cluster) => cluster.blueprintIds),
      contains('extended-shotgun-mag-iii'),
    );
  });
}

Map<String, ArcBlueprintState> _statesWithOnlyMissing(String missingId) {
  return <String, ArcBlueprintState>{
    for (final blueprint in ArcBlueprintSeedData.blueprints)
      blueprint.id: ArcBlueprintState(
        blueprintId: blueprint.id,
        owned: blueprint.id != missingId,
        dupesOwned: 0,
        priorityRank: blueprint.id == missingId ? 1 : 0,
        updatedAt: null,
      ),
  };
}
