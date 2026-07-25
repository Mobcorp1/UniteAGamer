import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_opportunity_carousel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_blueprint_opportunity_marker.dart';

void main() {
  testWidgets('Blueprint opportunity marker uses artwork, count and priority', (
    tester,
  ) async {
    const marker = ArcRaidMapMarker(
      id: 'opportunity',
      mapId: 'blue_gate',
      category: ArcRaidMapMarkerCategory.blueprintOpportunity,
      label: 'Blueprint opportunity',
      point: ArcNormalizedPoint(x: 0.5, y: 0.5),
      count: 7,
      blueprintIds: <String>['tempest', 'bobcat'],
      blueprintFindCounts: <String, int>{'tempest': 4, 'bobcat': 3},
      prioritizedBlueprintIds: <String>['tempest'],
      confidence: ArcRaidIntelConfidence.strong,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ArcBlueprintOpportunityMarker(
              marker: marker,
              selected: false,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('7'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('Blueprint opportunity carousel shows find totals', (
    tester,
  ) async {
    const marker = ArcRaidMapMarker(
      id: 'opportunity',
      mapId: 'blue_gate',
      category: ArcRaidMapMarkerCategory.blueprintOpportunity,
      label: 'Blueprint opportunity',
      point: ArcNormalizedPoint(x: 0.5, y: 0.5),
      count: 4,
      blueprintIds: <String>['tempest'],
      blueprintFindCounts: <String, int>{'tempest': 4},
      confidence: ArcRaidIntelConfidence.confirmed,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ArcBlueprintOpportunityCarousel(marker: marker, cluster: null),
        ),
      ),
    );

    expect(find.text('Tempest'), findsOneWidget);
    expect(find.text('4 finds'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
  });
}
