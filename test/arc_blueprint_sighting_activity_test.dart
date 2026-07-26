import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_sighting_aggregator.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_sighting_activity.dart';

void main() {
  testWidgets('renders live Blueprint sighting totals and trend', (
    tester,
  ) async {
    final activity = ArcBlueprintLocationActivity(
      sightings: <ArcBlueprintSightingSummary>[
        ArcBlueprintSightingSummary(
          blueprintId: 'tempest',
          totalFinds: 6,
          findsLast24Hours: 2,
          findsLast7Days: 5,
          latestSightingAt: DateTime.now().subtract(const Duration(hours: 2)),
          trend: ArcBlueprintSightingTrend.surging,
          confidence: ArcRaidIntelConfidence.confirmed,
          reportDriven: true,
        ),
      ],
      totalFinds: 6,
      findsLast24Hours: 2,
      findsLast7Days: 5,
      contributorCount: 4,
      latestSightingAt: DateTime.now().subtract(const Duration(hours: 2)),
      trend: ArcBlueprintSightingTrend.surging,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ArcBlueprintSightingActivity(activity: activity)),
      ),
    );

    expect(find.text('LIVE SIGHTING ACTIVITY'), findsOneWidget);
    expect(find.text('SURGING'), findsOneWidget);
    expect(find.text('Last 24h'), findsOneWidget);
    expect(find.text('Contributors'), findsOneWidget);
    expect(find.text('Tempest'), findsOneWidget);
    expect(find.text('6 finds'), findsOneWidget);
    expect(find.text('5 this week'), findsOneWidget);
  });
}
