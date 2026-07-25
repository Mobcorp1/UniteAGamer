import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_map_marker_detail_card.dart';

void main() {
  testWidgets('renders reusable marker intelligence details', (tester) async {
    const marker = ArcRaidMapMarker(
      id: 'poi',
      mapId: 'blue_gate',
      category: ArcRaidMapMarkerCategory.poi,
      label: 'Ancient Fort',
      point: ArcNormalizedPoint(x: 0.48, y: 0.70),
      confidence: ArcRaidIntelConfidence.confirmed,
      approximate: false,
      detail: 'Southern production POI.',
      tags: <String>['POI', 'South'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ArcMapMarkerDetailCard(marker: marker)),
      ),
    );

    expect(find.text('Ancient Fort'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Calibrated'), findsOneWidget);
    expect(find.text('Southern production POI.'), findsOneWidget);
    expect(find.text('South'), findsOneWidget);
  });
}
