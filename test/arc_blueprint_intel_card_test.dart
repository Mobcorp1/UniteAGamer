import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_intel_card.dart';

void main() {
  testWidgets('premium Blueprint Intel card renders evidence and navigation', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 7, 25);
    final cluster = ArcRaidIntelCluster(
      id: 'cluster',
      mapId: 'blue_gate',
      label: 'Warehouse Complex',
      point: const ArcNormalizedPoint(x: 0.313, y: 0.476),
      blueprintIds: const <String>['tempest'],
      evidence: <ArcRaidIntelEvidence>[
        ArcRaidIntelEvidence(
          id: 'evidence',
          blueprintId: 'tempest',
          mapId: 'blue_gate',
          poiId: 'blue_gate_warehouse_complex',
          containerSource: 'Weapon Case',
          acquisitionSource: 'Normal Drop',
          sourceReference: 'Community Drop Report',
          publishedAt: now,
          confidence: ArcRaidIntelConfidence.confirmed,
        ),
      ],
      confidence: ArcRaidIntelConfidence.confirmed,
      reportCount: 7,
      independentReporterCount: 4,
      freshnessLabel: 'Reported today',
      commonSource: 'Weapon Case',
      conditionCorrelation: 'Any condition',
    );
    const marker = ArcRaidMapMarker(
      id: 'marker',
      mapId: 'blue_gate',
      category: ArcRaidMapMarkerCategory.blueprintOpportunity,
      label: 'Tempest opportunity',
      point: ArcNormalizedPoint(x: 0.313, y: 0.476),
      count: 7,
      blueprintIds: <String>['tempest'],
      blueprintFindCounts: <String, int>{'tempest': 7},
      prioritizedBlueprintIds: <String>['tempest'],
      confidence: ArcRaidIntelConfidence.confirmed,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ArcBlueprintIntelCard(
              marker: marker,
              cluster: cluster,
              map: ArcRaidIntelligenceSeedData.mapById('blue_gate'),
              onCentreMap: () {},
              onAddStop: () {},
              onOpenBlueprint: () {},
              onOpenRaidPlanner: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tempest'), findsWidgets);
    expect(find.text('7 Reports'), findsNothing);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Raiders'), findsOneWidget);
    expect(find.text('Nearest POI'), findsOneWidget);
    expect(find.text('Nearest Extraction'), findsOneWidget);
    expect(find.text('Nearest Raider Hatch'), findsOneWidget);
    expect(find.text('Add to Route'), findsOneWidget);
    expect(find.text('Open Raid Planner'), findsOneWidget);
    expect(find.textContaining('Community Drop Report'), findsOneWidget);
  });

  testWidgets('premium Blueprint Intel card action callbacks are wired', (
    tester,
  ) async {
    var routePressed = false;
    var plannerPressed = false;
    final cluster = ArcRaidIntelCluster(
      id: 'cluster',
      mapId: 'blue_gate',
      label: 'Warehouse Complex',
      point: const ArcNormalizedPoint(x: 0.313, y: 0.476),
      blueprintIds: const <String>['tempest'],
      evidence: const <ArcRaidIntelEvidence>[],
    );
    const marker = ArcRaidMapMarker(
      id: 'marker',
      mapId: 'blue_gate',
      category: ArcRaidMapMarkerCategory.blueprintOpportunity,
      label: 'Tempest opportunity',
      point: ArcNormalizedPoint(x: 0.313, y: 0.476),
      blueprintIds: <String>['tempest'],
      blueprintFindCounts: <String, int>{'tempest': 1},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ArcBlueprintIntelCard(
              marker: marker,
              cluster: cluster,
              map: ArcRaidIntelligenceSeedData.mapById('blue_gate'),
              onCentreMap: () {},
              onAddStop: () => routePressed = true,
              onOpenBlueprint: () {},
              onOpenRaidPlanner: () => plannerPressed = true,
            ),
          ),
        ),
      ),
    );

    final addToRoute = find.text('Add to Route');
    await tester.ensureVisible(addToRoute);
    await tester.pumpAndSettle();
    await tester.tap(addToRoute);

    final openRaidPlanner = find.text('Open Raid Planner');
    await tester.ensureVisible(openRaidPlanner);
    await tester.pumpAndSettle();
    await tester.tap(openRaidPlanner);

    expect(routePressed, isTrue);
    expect(plannerPressed, isTrue);
  });
}
