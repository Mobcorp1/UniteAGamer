import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_objective_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';

void main() {
  const firstQuestId = 'quest-chain-apollo-groundbreaking';
  const secondQuestId = 'quest-chain-shani-a-dead-end';

  const firstDefinition = ArcQuestProgressionDefinition(
    questId: firstQuestId,
    trader: 'Apollo',
    questName: 'Groundbreaking',
    order: 79,
    prerequisiteQuestIds: <String>[],
    objectives: <ArcProgressionObjective>[],
  );
  const secondDefinition = ArcQuestProgressionDefinition(
    questId: secondQuestId,
    trader: 'Shani',
    questName: 'A Dead End',
    order: 80,
    prerequisiteQuestIds: <String>[],
    objectives: <ArcProgressionObjective>[],
  );

  const progression = ArcProgressionSnapshotBundle(
    quest: ArcQuestProgressionSnapshot(
      seasonId: 'season-1',
      entries: <ArcQuestProgressionEntry>[
        ArcQuestProgressionEntry(
          definition: firstDefinition,
          status: ArcProgressionStatus.active,
          objectives: <ArcProgressionObjective>[],
        ),
        ArcQuestProgressionEntry(
          definition: secondDefinition,
          status: ArcProgressionStatus.active,
          objectives: <ArcProgressionObjective>[],
        ),
      ],
      completedQuestIds: <String>{},
      archivedQuestIds: <String>{},
      trackingKnown: true,
      trackedQuestIds: <String>{firstQuestId, secondQuestId},
    ),
    scrappy: ArcScrappyProgressionSnapshot.empty,
    bench: ArcBenchProgressionSnapshot.empty,
  );

  const map = ArcRaidMap(
    id: 'blue_gate',
    displayName: 'Blue Gate',
    bounds: ArcNormalizedPoint(x: 1, y: 1),
    regions: <ArcRaidMapRegion>[],
    pois: <ArcRaidMapPoi>[
      ArcRaidMapPoi(
        id: 'groundbreaking-poi',
        mapId: 'blue_gate',
        name: 'Groundbreaking',
        point: ArcNormalizedPoint(x: 0.5, y: 0.5),
        approximate: false,
        lootTags: <String>['Quest'],
      ),
    ],
    spawnRegions: <ArcRaidSpawnRegion>[],
    extractions: <ArcRaidExtraction>[],
    hatches: <ArcRaiderHatch>[],
    routeNodes: <ArcRaidRouteNode>[],
    routeEdges: <ArcRaidRouteEdge>[],
    markers: <ArcRaidMapMarker>[],
  );

  test('all explicitly tracked active Quests produce spatial objectives', () {
    final objectives = const ArcRaidObjectiveIntelligenceEngine()
        .trackedObjectives(
          progression: progression,
          scrappyStates: const <String, ArcScrappyState>{},
        );

    final locations = objectives
        .where((objective) => objective.questLocationOnly)
        .toList(growable: false);

    expect(locations, hasLength(2));
    expect(locations.map((objective) => objective.questId).toSet(), <String>{
      firstQuestId,
      secondQuestId,
    });
  });

  test(
    'location-only Quest routes only to matching published marker and layer',
    () {
      final objectives = const ArcRaidObjectiveIntelligenceEngine()
          .trackedObjectives(
            progression: progression,
            scrappyStates: const <String, ArcScrappyState>{},
          );

      const markers = <ArcAdminMapMarker>[
        ArcAdminMapMarker(
          id: 'groundbreaking-exact',
          mapId: 'blue_gate',
          layer: ArcRaidMapLayer.surface,
          kind: ArcAdminMapMarkerKind.questLocation,
          name: 'Groundbreaking antenna',
          questId: firstQuestId,
          subtypeId: 'quest_objective',
          point: ArcNormalizedPoint(x: 0.2, y: 0.3),
          state: ArcAdminMapMarkerState.published,
        ),
        ArcAdminMapMarker(
          id: 'groundbreaking-wrong-id',
          mapId: 'blue_gate',
          layer: ArcRaidMapLayer.surface,
          kind: ArcAdminMapMarkerKind.questLocation,
          name: 'Groundbreaking',
          questId: 'quest-chain-apollo-paving-the-way',
          subtypeId: 'quest_objective',
          point: ArcNormalizedPoint(x: 0.8, y: 0.3),
          state: ArcAdminMapMarkerState.published,
        ),
        ArcAdminMapMarker(
          id: 'dead-end-underground',
          mapId: 'blue_gate',
          layer: ArcRaidMapLayer.underground,
          kind: ArcAdminMapMarkerKind.questLocation,
          name: 'A Dead End console',
          questId: secondQuestId,
          subtypeId: 'quest_objective',
          point: ArcNormalizedPoint(x: 0.7, y: 0.7),
          state: ArcAdminMapMarkerState.published,
        ),
        ArcAdminMapMarker(
          id: 'dead-end-draft',
          mapId: 'blue_gate',
          layer: ArcRaidMapLayer.surface,
          kind: ArcAdminMapMarkerKind.questLocation,
          name: 'A Dead End draft',
          questId: secondQuestId,
          subtypeId: 'quest_objective',
          point: ArcNormalizedPoint(x: 0.4, y: 0.7),
          state: ArcAdminMapMarkerState.draft,
        ),
      ];

      final surface = const ArcRaidObjectiveIntelligenceEngine().buildClusters(
        map: map,
        objectives: objectives,
        adminMarkers: markers,
        activeLayer: ArcRaidMapLayer.surface,
      );

      expect(
        surface.map((cluster) => cluster.label),
        contains('Groundbreaking antenna'),
      );
      expect(
        surface.map((cluster) => cluster.label),
        isNot(contains('Groundbreaking')),
      );
      expect(
        surface.map((cluster) => cluster.label),
        isNot(contains('A Dead End console')),
      );
      expect(
        surface.map((cluster) => cluster.label),
        isNot(contains('A Dead End draft')),
      );

      final underground = const ArcRaidObjectiveIntelligenceEngine()
          .buildClusters(
            map: map,
            objectives: objectives,
            adminMarkers: markers,
            activeLayer: ArcRaidMapLayer.underground,
          );

      expect(
        underground.map((cluster) => cluster.label),
        contains('A Dead End console'),
      );
      expect(
        underground.map((cluster) => cluster.label),
        isNot(contains('Groundbreaking antenna')),
      );
    },
  );

  test(
    'ordinary POI text cannot satisfy an exact Quest-location objective',
    () {
      final objective = const ArcRaidObjectiveIntelligenceEngine()
          .trackedObjectives(
            progression: progression,
            scrappyStates: const <String, ArcScrappyState>{},
          )
          .firstWhere(
            (item) => item.questId == firstQuestId && item.questLocationOnly,
          );

      final clusters = const ArcRaidObjectiveIntelligenceEngine().buildClusters(
        map: map,
        objectives: <ArcRaidObjective>[objective],
        activeLayer: ArcRaidMapLayer.surface,
      );

      expect(clusters, isEmpty);
    },
  );
}
