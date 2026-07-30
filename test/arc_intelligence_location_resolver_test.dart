import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_intelligence_location_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

void main() {
  const map = ArcRaidMap(
    id: 'test_map',
    displayName: 'Test Map',
    bounds: ArcNormalizedPoint(x: 1, y: 1),
    regions: <ArcRaidMapRegion>[],
    pois: <ArcRaidMapPoi>[
      ArcRaidMapPoi(
        id: 'south_lift',
        mapId: 'test_map',
        name: 'South Lift',
        point: ArcNormalizedPoint(x: 0.1, y: 0.1),
        approximate: false,
      ),
    ],
    spawnRegions: <ArcRaidSpawnRegion>[],
    extractions: <ArcRaidExtraction>[],
    hatches: <ArcRaiderHatch>[],
    routeNodes: <ArcRaidRouteNode>[],
    routeEdges: <ArcRaidRouteEdge>[],
    markers: <ArcRaidMapMarker>[
      ArcRaidMapMarker(
        id: 'test_map_poi_static_lift',
        mapId: 'test_map',
        category: ArcRaidMapMarkerCategory.poi,
        label: 'Static Lift',
        point: ArcNormalizedPoint(x: 0.2, y: 0.2),
        payloadId: 'static_lift',
        confidence: ArcRaidIntelConfidence.moderate,
        approximate: true,
      ),
    ],
  );

  const movedMarker = ArcAdminMapMarker(
    id: 'admin_south_lift',
    mapId: 'test_map',
    layer: ArcRaidMapLayer.underground,
    kind: ArcAdminMapMarkerKind.poi,
    name: 'South Lift - Corrected',
    aliases: <String>['South Lift', 'Old Lift'],
    point: ArcNormalizedPoint(x: 0.72, y: 0.31),
    confidence: ArcRaidIntelConfidence.confirmed,
    state: ArcAdminMapMarkerState.published,
    adminVerified: true,
    seedReferenceId: 'south_lift',
    sourceRecordId: 'seed_south_lift',
  );

  test('canonical POI IDs resolve to current Admin marker coordinates', () {
    final resolution = const ArcIntelligenceLocationResolver().resolve(
      map: map,
      adminMarkers: const <ArcAdminMapMarker>[movedMarker],
      canonicalPoiId: 'south_lift',
    );

    expect(
      resolution?.source,
      ArcIntelligenceLocationResolutionSource.canonicalPoiId,
    );
    expect(resolution?.point.x, closeTo(0.72, 0.0001));
    expect(resolution?.point.y, closeTo(0.31, 0.0001));
    expect(resolution?.layer, ArcRaidMapLayer.underground);
    expect(resolution?.canBackfillCanonicalReference, isTrue);
  });

  test('historical aliases resolve without trusting old coordinates', () {
    final resolution = const ArcIntelligenceLocationResolver().resolve(
      map: map,
      adminMarkers: const <ArcAdminMapMarker>[movedMarker],
      historicalAlias: 'Old Lift',
    );

    expect(
      resolution?.source,
      ArcIntelligenceLocationResolutionSource.historicalAlias,
    );
    expect(resolution?.label, 'South Lift - Corrected');
    expect(resolution?.point.x, closeTo(0.72, 0.0001));
  });

  test('static marker and legacy POI fallbacks remain deterministic', () {
    final staticResolution = const ArcIntelligenceLocationResolver().resolve(
      map: map,
      canonicalPoiId: 'static_lift',
    );
    final poiResolution = const ArcIntelligenceLocationResolver().resolve(
      map: map,
      canonicalPoiId: 'south_lift',
    );

    expect(
      staticResolution?.source,
      ArcIntelligenceLocationResolutionSource.staticMarker,
    );
    expect(staticResolution?.point.x, closeTo(0.2, 0.0001));
    expect(
      poiResolution?.source,
      ArcIntelligenceLocationResolutionSource.legacyPoi,
    );
    expect(poiResolution?.point.x, closeTo(0.1, 0.0001));
  });

  test(
    'coordinate-only reports require review when nearest POI confidence is low',
    () {
      final resolution = const ArcIntelligenceLocationResolver().resolve(
        map: map,
        legacyPoint: const ArcNormalizedPoint(x: 0.95, y: 0.95),
      );

      expect(
        resolution?.source,
        ArcIntelligenceLocationResolutionSource.legacyCoordinate,
      );
      expect(resolution?.needsAdminReview, isTrue);
      expect(resolution?.canBackfillCanonicalReference, isFalse);
    },
  );
}
