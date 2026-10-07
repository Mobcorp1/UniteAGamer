import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_coordinate_projection.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_endpoint_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  test('canonical marker survives laptop external monitor and mobile fits', () {
    const point = ArcNormalizedPoint(x: 0.4231, y: 0.6178);
    const viewports = <Size>[
      Size(1366, 768),
      Size(1920, 1080),
      Size(2560, 1440),
      Size(390, 844),
      Size(844, 390),
    ];

    for (final viewport in viewports) {
      final mapSize = ArcMapCoordinateProjection.containSize(
        viewport: viewport,
        sourceWidth: 2500,
        sourceHeight: 2000,
      );
      final canvas = ArcMapCoordinateProjection.canonicalToCanvas(
        point: point,
        mapSize: mapSize,
      );
      final restored = ArcMapCoordinateProjection.canvasToCanonical(
        localPosition: canvas,
        mapSize: mapSize,
      );
      expect(restored.x, closeTo(point.x, 0.000001));
      expect(restored.y, closeTo(point.y, 0.000001));
    }
  });

  test('crop and rotation calibration round-trips canonical coordinates', () {
    const calibration = ArcRaidMapCalibration(
      id: 'integrity-test',
      mapId: 'test-map',
      cropOrigin: ArcNormalizedPoint(x: 0.08, y: 0.06),
      cropSize: ArcNormalizedPoint(x: 0.82, y: 0.86),
      rotationDegrees: 12,
    );
    const point = ArcNormalizedPoint(x: 0.46, y: 0.52);
    const mapSize = Size(1000, 800);

    final canvas = ArcMapCoordinateProjection.canonicalToCanvas(
      point: point,
      mapSize: mapSize,
      calibration: calibration,
    );
    final restored = ArcMapCoordinateProjection.canvasToCanonical(
      localPosition: canvas,
      mapSize: mapSize,
      calibration: calibration,
    );

    expect(restored.x, closeTo(point.x, 0.000001));
    expect(restored.y, closeTo(point.y, 0.000001));
  });

  test('published extraction keeps exact canonical point through resolver', () {
    final seedMap = ArcRaidIntelligenceSeedData.maps.first;
    const point = ArcNormalizedPoint(x: 0.76, y: 0.69);
    final marker = ArcAdminMapMarker(
      id: 'published-exit-integrity',
      mapId: seedMap.id,
      layer: ArcRaidMapLayer.surface,
      kind: ArcAdminMapMarkerKind.extraction,
      name: 'Integrity Exit',
      point: point,
      state: ArcAdminMapMarkerState.published,
    );

    final endpoints = const ArcRaidEndpointResolver().resolve(
      seedMap: seedMap,
      layer: ArcRaidMapLayer.surface,
      markers: [marker],
    );

    expect(endpoints.authoritativeExtractions, isTrue);
    expect(endpoints.extractions, hasLength(1));
    expect(endpoints.extractions.single.id, marker.id);
    expect(endpoints.extractions.single.point.x, point.x);
    expect(endpoints.extractions.single.point.y, point.y);
  });
}
