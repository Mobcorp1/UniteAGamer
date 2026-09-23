import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  const engine = ArcRaidIntelligenceEngine();

  ArcRaidObjective objective(String id, String item, {double weight = 1}) {
    return ArcRaidObjective(
      id: id,
      label: item,
      reason: 'Need $item for current tracker progress.',
      category: ArcRaidMapMarkerCategory.operationObjective,
      system: 'Tracker',
      itemName: item,
      missingCount: 1,
      weight: weight,
    );
  }

  ArcRaidIntelCluster cluster({
    required String id,
    required double x,
    required double y,
    required List<ArcRaidObjective> objectives,
    required double objectiveScore,
  }) {
    return ArcRaidIntelCluster(
      id: id,
      mapId: 'blue_gate',
      label: id,
      point: ArcNormalizedPoint(x: x, y: y),
      blueprintIds: const <String>[],
      evidence: const <ArcRaidIntelEvidence>[],
      confidence: ArcRaidIntelConfidence.moderate,
      markerCategory: ArcRaidMapMarkerCategory.operationObjective,
      objectives: objectives,
      objectiveScore: objectiveScore,
    );
  }

  test('late-raid planner prefers a comparable multi-objective stop', () {
    final map = ArcRaidIntelligenceSeedData.mapById('blue_gate');
    final spawn = engine.stopFromSpawn(map.spawnRegions.first);
    final extraction = engine.stopFromExtraction(map.extractions.first);
    final multi = cluster(
      id: 'multi-purpose',
      x: 0.50,
      y: 0.50,
      objectives: <ArcRaidObjective>[
        objective('quest-need', 'Quest Item', weight: 1.35),
        objective('bench-need', 'Bench Item'),
      ],
      objectiveScore: 95,
    );
    final single = cluster(
      id: 'single-purpose',
      x: 0.49,
      y: 0.50,
      objectives: <ArcRaidObjective>[objective('single-need', 'Single Item')],
      objectiveScore: 45,
    );

    final route = engine.generateRoute(
      map: map,
      clusters: <ArcRaidIntelCluster>[single, multi],
      spawn: spawn,
      extraction: extraction,
      raidStage: 'Late',
      routeStyle: ArcRaidRouteStyle.balanced,
    );

    expect(route, isNotNull);
    expect(route!.stops, hasLength(1));
    expect(route.stops.single.clusterId, 'multi-purpose');
    expect(route.stops.single.objectiveIds, <String>[
      'quest-need',
      'bench-need',
    ]);
    expect(route.metrics.objectiveTargetCount, 2);
    expect(route.metrics.blueprintTargetCount, 0);
    expect(route.summary, contains('2 tracked goals'));
  });

  test('manual stop addition keeps tracker objective identity and reason', () {
    final map = ArcRaidIntelligenceSeedData.mapById('blue_gate');
    final spawn = engine.stopFromSpawn(map.spawnRegions.first);
    final extraction = engine.stopFromExtraction(map.extractions.first);
    final seed = cluster(
      id: 'seed',
      x: 0.45,
      y: 0.45,
      objectives: <ArcRaidObjective>[objective('seed-goal', 'Seed Goal')],
      objectiveScore: 40,
    );
    final added = cluster(
      id: 'added',
      x: 0.55,
      y: 0.55,
      objectives: <ArcRaidObjective>[objective('added-goal', 'Added Goal')],
      objectiveScore: 55,
    );
    final route = engine.generateRoute(
      map: map,
      clusters: <ArcRaidIntelCluster>[seed],
      spawn: spawn,
      extraction: extraction,
      raidStage: 'Late',
    );

    final updated = engine.addStop(route!, added);
    final stop = updated.stops.firstWhere((item) => item.clusterId == 'added');
    expect(stop.objectiveIds, <String>['added-goal']);
    expect(stop.reason, isNot(contains('Seed Goal')));
    expect(stop.reason, contains('Added Goal'));
  });
}
