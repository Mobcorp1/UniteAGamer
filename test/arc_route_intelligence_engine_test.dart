import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  const engine = ArcRaidIntelligenceEngine();

  ArcRaidIntelCluster cluster({
    required String id,
    required double x,
    required double y,
    required List<String> blueprints,
    ArcRaidIntelConfidence confidence = ArcRaidIntelConfidence.strong,
  }) {
    return ArcRaidIntelCluster(
      id: id,
      mapId: 'blue_gate',
      label: id,
      point: ArcNormalizedPoint(x: x, y: y),
      blueprintIds: blueprints,
      evidence: const <ArcRaidIntelEvidence>[],
      confidence: confidence,
    );
  }

  test('builds an optimised all-map Loot Run with route metrics', () {
    final map = ArcRaidIntelligenceSeedData.mapById('blue_gate');
    final spawn = engine.stopFromSpawn(map.spawnRegions.first);
    final extraction = engine.stopFromExtraction(map.extractions.first);
    final route = engine.generateRoute(
      map: map,
      clusters: <ArcRaidIntelCluster>[
        cluster(id: 'far', x: 0.82, y: 0.78, blueprints: const ['b2']),
        cluster(id: 'near', x: 0.28, y: 0.30, blueprints: const ['b1']),
        cluster(id: 'middle', x: 0.51, y: 0.48, blueprints: const ['b1', 'b3']),
      ],
      spawn: spawn,
      extraction: extraction,
      routeStyle: ArcRaidRouteStyle.thorough,
    );

    expect(route, isNotNull);
    expect(route!.stops, isNotEmpty);
    expect(route.metrics.opportunityCount, route.stops.length);
    expect(route.metrics.blueprintTargetCount, 3);
    expect(route.metrics.estimatedMinutes, greaterThan(0));
    expect(route.metrics.totalDistance, greaterThan(0));
    expect(route.metrics.efficiencyScore, inInclusiveRange(0, 100));
    expect(route.summary, contains('Loot Run'));
  });

  test('recommends an extraction when the player has not selected one', () {
    final map = ArcRaidIntelligenceSeedData.mapById('blue_gate');
    final spawn = engine.stopFromSpawn(map.spawnRegions.first);
    final recommendation = engine.recommendExtraction(
      map: map,
      spawn: spawn,
      clusters: <ArcRaidIntelCluster>[
        cluster(id: 'target', x: 0.50, y: 0.50, blueprints: const ['b1']),
      ],
    );

    expect(recommendation, isNotNull);
    expect(
      map.extractions.map((item) => item.id),
      contains(recommendation!.id),
    );
  });
}
