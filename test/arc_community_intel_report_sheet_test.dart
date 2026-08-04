import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_community_intel_report_sheet.dart';

void main() {
  const map = ArcRaidMap(
    id: 'test_map',
    displayName: 'Test Map',
    bounds: ArcNormalizedPoint(x: 1, y: 1),
    regions: <ArcRaidMapRegion>[],
    pois: <ArcRaidMapPoi>[
      ArcRaidMapPoi(
        id: 'nearby_poi',
        mapId: 'test_map',
        name: 'Nearby POI',
        point: ArcNormalizedPoint(x: 0.5, y: 0.5),
        approximate: false,
      ),
    ],
    spawnRegions: <ArcRaidSpawnRegion>[],
    extractions: <ArcRaidExtraction>[],
    hatches: <ArcRaiderHatch>[],
    routeNodes: <ArcRaidRouteNode>[],
    routeEdges: <ArcRaidRouteEdge>[],
    markers: <ArcRaidMapMarker>[],
  );

  testWidgets('guided report keeps an exact pin separate from nearby POI', (
    tester,
  ) async {
    String? submittedPoiId;
    ArcNormalizedPoint? submittedPoint;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArcCommunityIntelReportSheet(
            map: map,
            layer: ArcRaidMapLayer.surface,
            point: const ArcNormalizedPoint(x: 0.51, y: 0.49),
            submitter:
                ({
                  required mapId,
                  required layer,
                  required category,
                  required point,
                  poiId,
                  poiName,
                  blueprintId,
                  blueprintName,
                  notes = '',
                }) async {
                  submittedPoiId = poiId;
                  submittedPoint = point;
                  return 'report-id';
                },
          ),
        ),
      ),
    );

    expect(find.text('1/4 • Intel type'), findsOneWidget);
    await tester.tap(find.text('High Value'));
    await tester.pumpAndSettle();

    expect(find.text('2/4 • Location'), findsOneWidget);
    expect(find.text('No listed POI — use exact dropped pin'), findsOneWidget);
    expect(find.text('Attach to Nearby POI'), findsOneWidget);

    final exactPin = find.byKey(
      const ValueKey<String>('intel-location-exact-pin'),
    );
    await tester.ensureVisible(exactPin);
    await tester.pumpAndSettle();
    await tester.tap(exactPin);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('4/4 • Review'), findsOneWidget);
    expect(find.textContaining('Exact pin 51.0, 49.0'), findsOneWidget);

    await tester.tap(find.text('Submit Intel'));
    await tester.pumpAndSettle();

    expect(submittedPoiId, isNull);
    expect(submittedPoint?.x, closeTo(0.51, 0.0001));
    expect(submittedPoint?.y, closeTo(0.49, 0.0001));
  });
}
