import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_sighting_aggregator.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  final now = DateTime.utc(2026, 7, 26, 12);

  ArcRaidIntelEvidence evidence(String id, String blueprintId, DateTime at) {
    return ArcRaidIntelEvidence(
      id: id,
      blueprintId: blueprintId,
      mapId: 'blue_gate',
      point: const ArcNormalizedPoint(x: 0.4, y: 0.4),
      sourceCategory: 'community_drop_report',
      sourceReference: 'Drop Report',
      publishedAt: at,
      reviewedAt: at,
      confidence: ArcRaidIntelConfidence.moderate,
    );
  }

  test('aggregates totals, recent sightings and contributors', () {
    final cluster = ArcRaidIntelCluster(
      id: 'cluster',
      mapId: 'blue_gate',
      label: 'Warehouse Complex',
      point: const ArcNormalizedPoint(x: 0.4, y: 0.4),
      blueprintIds: const <String>['tempest', 'bobcat'],
      evidence: <ArcRaidIntelEvidence>[
        evidence('1', 'tempest', now.subtract(const Duration(hours: 2))),
        evidence('2', 'tempest', now.subtract(const Duration(hours: 8))),
        evidence('3', 'tempest', now.subtract(const Duration(days: 3))),
        evidence('4', 'bobcat', now.subtract(const Duration(days: 2))),
      ],
      reportCount: 4,
      independentReporterCount: 3,
      confidence: ArcRaidIntelConfidence.strong,
    );

    final activity = const ArcBlueprintSightingAggregator().aggregate(
      cluster,
      now: now,
    );

    expect(activity.totalFinds, 4);
    expect(activity.findsLast24Hours, 2);
    expect(activity.findsLast7Days, 4);
    expect(activity.contributorCount, 3);
    expect(activity.sightings.first.blueprintId, 'tempest');
    expect(activity.sightings.first.totalFinds, 3);
    expect(activity.trend, ArcBlueprintSightingTrend.surging);
  });

  test('keeps seeded evidence clearly separated from live reports', () {
    final cluster = ArcRaidIntelCluster(
      id: 'cluster',
      mapId: 'blue_gate',
      label: 'Seeded',
      point: const ArcNormalizedPoint(x: 0.4, y: 0.4),
      blueprintIds: const <String>['tempest'],
      evidence: const <ArcRaidIntelEvidence>[
        ArcRaidIntelEvidence(
          id: 'seed',
          blueprintId: 'tempest',
          mapId: 'blue_gate',
        ),
      ],
      reportCount: 1,
    );

    final activity = const ArcBlueprintSightingAggregator().aggregate(
      cluster,
      now: now,
    );

    expect(activity.hasLiveReports, isFalse);
    expect(activity.trend, ArcBlueprintSightingTrend.seeded);
    expect(activity.sightings.single.recencyLabel(now), 'Seeded Intel');
  });
}
