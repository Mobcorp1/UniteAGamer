import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_objective_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';

void main() {
  const engine = ArcRaidObjectiveIntelligenceEngine();

  const questObjective = ArcProgressionObjective(
    id: 'quest-medical',
    label: 'Antiseptic',
    requiredCount: 3,
    currentCount: 1,
    sourceHint: 'Search medical clinics and hospital containers.',
  );
  const scrappyObjective = ArcProgressionObjective(
    id: 'scrappy-medical',
    label: 'Syringe',
    requiredCount: 2,
    currentCount: 0,
    sourceHint: 'Medical locations and med crates.',
  );
  const benchObjective = ArcProgressionObjective(
    id: 'bench-medical',
    label: 'Bioscanner',
    requiredCount: 4,
    currentCount: 0,
    sourceHint: 'Search medical and laboratory areas.',
  );

  const questDefinition = ArcQuestProgressionDefinition(
    questId: 'quest-1',
    trader: 'Shani',
    questName: 'Medical Run',
    order: 1,
    prerequisiteQuestIds: <String>[],
    objectives: <ArcProgressionObjective>[questObjective],
  );
  const scrappyDefinition = ArcScrappyProgressionDefinition(
    level: 2,
    title: 'Scrappy Lv.2',
    objectives: <ArcProgressionObjective>[scrappyObjective],
  );
  const benchDefinition = ArcBenchProgressionDefinition(
    benchId: 'medical-bench',
    station: 'Medical Lab',
    level: 1,
    objectives: <ArcProgressionObjective>[benchObjective],
  );

  const progression = ArcProgressionSnapshotBundle(
    quest: ArcQuestProgressionSnapshot(
      seasonId: 'season-1',
      entries: <ArcQuestProgressionEntry>[
        ArcQuestProgressionEntry(
          definition: questDefinition,
          status: ArcProgressionStatus.active,
          objectives: <ArcProgressionObjective>[questObjective],
        ),
      ],
      completedQuestIds: <String>{},
      archivedQuestIds: <String>{},
      trackingKnown: true,
    ),
    scrappy: ArcScrappyProgressionSnapshot(
      state: ArcScrappyProgressionState.empty,
      definitions: <ArcScrappyProgressionDefinition>[scrappyDefinition],
      nextUpgrade: scrappyDefinition,
      trackingKnown: true,
      status: ArcCommandStatus.active,
      completionPercent: 0,
      collectedCount: 0,
      requiredCount: 2,
    ),
    bench: ArcBenchProgressionSnapshot(
      recordsByBenchId: <String, ArcBenchProgressionRecord>{},
      definitions: <ArcBenchProgressionDefinition>[benchDefinition],
      nextUpgrade: benchDefinition,
      trackingKnown: true,
      status: ArcCommandStatus.active,
      completionPercent: 0,
      collectedCount: 0,
      requiredCount: 4,
    ),
  );

  const map = ArcRaidMap(
    id: 'test-map',
    displayName: 'Test Map',
    bounds: ArcNormalizedPoint(x: 1, y: 1),
    regions: <ArcRaidMapRegion>[],
    pois: <ArcRaidMapPoi>[
      ArcRaidMapPoi(
        id: 'medical-centre',
        mapId: 'test-map',
        name: 'Medical Centre',
        point: ArcNormalizedPoint(x: 0.4, y: 0.4),
        approximate: false,
        lootTags: <String>['Medical', 'High Loot'],
      ),
      ArcRaidMapPoi(
        id: 'industrial-yard',
        mapId: 'test-map',
        name: 'Industrial Yard',
        point: ArcNormalizedPoint(x: 0.7, y: 0.7),
        approximate: false,
        lootTags: <String>['Industrial'],
      ),
    ],
    spawnRegions: <ArcRaidSpawnRegion>[],
    extractions: <ArcRaidExtraction>[],
    hatches: <ArcRaiderHatch>[],
    routeNodes: <ArcRaidRouteNode>[],
    routeEdges: <ArcRaidRouteEdge>[],
    markers: <ArcRaidMapMarker>[],
  );

  test('live tracker gaps become Quest, Scrappy and Bench objectives', () {
    final objectives = engine.trackedObjectives(
      progression: progression,
      scrappyStates: const <String, ArcScrappyState>{
        'scrappy-medical': ArcScrappyState(
          itemId: 'scrappy-medical',
          collectedCount: 1,
        ),
        'bench-medical': ArcScrappyState(
          itemId: 'bench-medical',
          collectedCount: 2,
        ),
      },
    );

    expect(
      objectives.map((item) => item.system),
      containsAll(<String>['Quest', 'Scrappy', 'Bench']),
    );
    expect(
      objectives.firstWhere((item) => item.system == 'Quest').missingCount,
      2,
    );
    expect(
      objectives.firstWhere((item) => item.system == 'Scrappy').missingCount,
      1,
    );
    expect(
      objectives.firstWhere((item) => item.system == 'Bench').missingCount,
      2,
    );
  });

  test('one matching POI combines multiple live tracker objectives', () {
    final objectives = engine.trackedObjectives(
      progression: progression,
      scrappyStates: const <String, ArcScrappyState>{},
    );
    final clusters = engine.buildClusters(map: map, objectives: objectives);

    final medical = clusters.firstWhere(
      (cluster) => cluster.poiId == 'medical-centre',
    );
    expect(medical.label, 'Medical Centre');
    expect(medical.objectiveCount, 3);
    expect(
      medical.objectives.map((objective) => objective.system).toSet(),
      <String>{'Quest', 'Scrappy', 'Bench'},
    );
    expect(medical.markerCategory, ArcRaidMapMarkerCategory.questObjective);
    expect(medical.commonSource, contains('Quest'));
  });

  test('unmatched source guidance does not invent an arbitrary POI', () {
    const objective = ArcRaidObjective(
      id: 'unknown',
      label: 'Unknown objective',
      reason: 'Find a mystery item.',
      category: ArcRaidMapMarkerCategory.operationObjective,
      system: 'Bench',
      itemName: 'Mystery Fragment',
      missingCount: 1,
      sourceHint: 'Only from submerged lunar archives.',
    );

    final clusters = engine.buildClusters(
      map: map,
      objectives: const <ArcRaidObjective>[objective],
    );

    expect(clusters, isEmpty);
  });

  test('generic admin resource markers do not attract unrelated goals', () {
    const objective = ArcRaidObjective(
      id: 'unrelated-admin',
      label: 'Unknown objective',
      reason: 'Find a mystery item.',
      category: ArcRaidMapMarkerCategory.operationObjective,
      system: 'Bench',
      itemName: 'Mystery Fragment',
      missingCount: 1,
      sourceHint: 'Only from submerged lunar archives.',
    );
    const genericResource = ArcAdminMapMarker(
      id: 'generic-resource',
      mapId: 'test-map',
      layer: ArcRaidMapLayer.surface,
      kind: ArcAdminMapMarkerKind.resourceNode,
      name: 'Resource Node',
      point: ArcNormalizedPoint(x: 0.3, y: 0.3),
      state: ArcAdminMapMarkerState.published,
    );

    final clusters = engine.buildClusters(
      map: map,
      objectives: const <ArcRaidObjective>[objective],
      adminMarkers: const <ArcAdminMapMarker>[genericResource],
    );

    expect(clusters, isEmpty);
  });
}
