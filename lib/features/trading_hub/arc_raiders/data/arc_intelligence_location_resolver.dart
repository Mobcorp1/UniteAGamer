import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

enum ArcIntelligenceLocationResolutionSource {
  canonicalPoiId,
  publishedMarkerId,
  seedReferenceId,
  sourceRecordId,
  currentPoiName,
  historicalAlias,
  staticMarker,
  legacyPoi,
  legacyCoordinate,
  unresolved,
}

class ArcIntelligenceLocationResolution {
  const ArcIntelligenceLocationResolution({
    required this.point,
    required this.layer,
    required this.label,
    required this.source,
    required this.confidence,
    this.canonicalMarker,
    this.staticMarker,
    this.legacyPoi,
    this.needsAdminReview = false,
  });

  final ArcNormalizedPoint point;
  final ArcRaidMapLayer layer;
  final String label;
  final ArcIntelligenceLocationResolutionSource source;
  final double confidence;
  final ArcAdminMapMarker? canonicalMarker;
  final ArcRaidMapMarker? staticMarker;
  final ArcRaidMapPoi? legacyPoi;
  final bool needsAdminReview;

  bool get resolvedFromCanonicalMarker => canonicalMarker != null;

  bool get canBackfillCanonicalReference =>
      resolvedFromCanonicalMarker && !needsAdminReview && confidence >= 0.78;

  bool get approximate {
    final marker = canonicalMarker;
    if (marker != null) return !marker.adminVerified;
    final staticMatch = staticMarker;
    if (staticMatch != null) return staticMatch.approximate;
    final poi = legacyPoi;
    if (poi != null) return poi.approximate;
    return true;
  }
}

class ArcIntelligenceLocationResolver {
  const ArcIntelligenceLocationResolver();

  static const double highConfidenceCoordinateDistance = 0.035;
  static const double reviewCoordinateDistance = 0.09;

  ArcIntelligenceLocationResolution? resolve({
    required ArcRaidMap map,
    List<ArcAdminMapMarker> adminMarkers = const <ArcAdminMapMarker>[],
    String? canonicalPoiId,
    String? publishedMarkerId,
    String? seedReferenceId,
    String? sourceRecordId,
    String? currentPoiName,
    String? historicalAlias,
    ArcNormalizedPoint? legacyPoint,
    ArcRaidMapLayer preferredLayer = ArcRaidMapLayer.surface,
  }) {
    final normalizedCanonicalPoiId = _normalizedOrNull(canonicalPoiId);
    final normalizedPublishedMarkerId = _normalizedOrNull(publishedMarkerId);
    final normalizedSeedReferenceId = _normalizedOrNull(seedReferenceId);
    final normalizedSourceRecordId = _normalizedOrNull(sourceRecordId);
    final normalizedCurrentPoiName = _normalizedOrNull(currentPoiName);
    final normalizedHistoricalAlias = _normalizedOrNull(historicalAlias);
    final normalizedLabels = <String>{
      ?normalizedCurrentPoiName,
      ?normalizedHistoricalAlias,
    };

    final liveMarkers = adminMarkers
        .where((marker) => marker.mapId == map.id && marker.isPublished)
        .toList(growable: false);

    final canonical = _firstCanonicalMarker(
      liveMarkers,
      source: ArcIntelligenceLocationResolutionSource.canonicalPoiId,
      matches: (marker) =>
          normalizedCanonicalPoiId != null &&
          _markerCanonicalIds(marker).contains(normalizedCanonicalPoiId),
    );
    if (canonical != null) return canonical;

    final published = _firstCanonicalMarker(
      liveMarkers,
      source: ArcIntelligenceLocationResolutionSource.publishedMarkerId,
      matches: (marker) =>
          normalizedPublishedMarkerId != null &&
          _normalize(marker.id) == normalizedPublishedMarkerId,
    );
    if (published != null) return published;

    final seed = _firstCanonicalMarker(
      liveMarkers,
      source: ArcIntelligenceLocationResolutionSource.seedReferenceId,
      matches: (marker) =>
          normalizedSeedReferenceId != null &&
          _normalizedOrNull(marker.seedReferenceId) ==
              normalizedSeedReferenceId,
    );
    if (seed != null) return seed;

    final sourceRecord = _firstCanonicalMarker(
      liveMarkers,
      source: ArcIntelligenceLocationResolutionSource.sourceRecordId,
      matches: (marker) =>
          normalizedSourceRecordId != null &&
          _normalizedOrNull(marker.sourceRecordId) == normalizedSourceRecordId,
    );
    if (sourceRecord != null) return sourceRecord;

    final currentName = _firstCanonicalMarker(
      liveMarkers,
      source: ArcIntelligenceLocationResolutionSource.currentPoiName,
      matches: (marker) =>
          normalizedLabels.isNotEmpty &&
          normalizedLabels.contains(_normalize(marker.name)),
    );
    if (currentName != null) return currentName;

    final alias = _firstCanonicalMarker(
      liveMarkers,
      source: ArcIntelligenceLocationResolutionSource.historicalAlias,
      matches: (marker) =>
          normalizedLabels.isNotEmpty &&
          marker.aliases.any(
            (value) => normalizedLabels.contains(_normalize(value)),
          ),
    );
    if (alias != null) return alias;

    final staticMarker = _resolveStaticMarker(
      map: map,
      canonicalPoiId: normalizedCanonicalPoiId,
      publishedMarkerId: normalizedPublishedMarkerId,
      labels: normalizedLabels,
    );
    if (staticMarker != null) return staticMarker;

    final legacyPoi = _resolveLegacyPoi(
      map: map,
      canonicalPoiId: normalizedCanonicalPoiId,
      labels: normalizedLabels,
      preferredLayer: preferredLayer,
    );
    if (legacyPoi != null) return legacyPoi;

    if (legacyPoint != null && normalizedLabels.isEmpty) {
      return _resolveLegacyCoordinate(
        map: map,
        point: legacyPoint.clamp(),
        preferredLayer: preferredLayer,
      );
    }

    if (legacyPoint != null) {
      return ArcIntelligenceLocationResolution(
        point: legacyPoint.clamp(),
        layer: preferredLayer,
        label: currentPoiName?.trim().isNotEmpty == true
            ? currentPoiName!.trim()
            : historicalAlias?.trim().isNotEmpty == true
            ? historicalAlias!.trim()
            : 'Unresolved report location',
        source: ArcIntelligenceLocationResolutionSource.unresolved,
        confidence: 0.18,
        needsAdminReview: true,
      );
    }

    return null;
  }

  ArcIntelligenceLocationResolution? resolveBlueprintReport({
    required ArcRaidMap map,
    required List<ArcAdminMapMarker> adminMarkers,
    required String? poiId,
    String? markerId,
    required String? poiName,
    required String fallbackLabel,
    ArcNormalizedPoint? legacyPoint,
    required ArcRaidMapLayer preferredLayer,
  }) {
    return resolve(
      map: map,
      adminMarkers: adminMarkers,
      canonicalPoiId: poiId,
      publishedMarkerId: markerId,
      seedReferenceId: poiId ?? markerId,
      sourceRecordId: poiId ?? markerId,
      currentPoiName: poiName,
      historicalAlias: fallbackLabel,
      legacyPoint: legacyPoint,
      preferredLayer: preferredLayer,
    );
  }

  ArcIntelligenceLocationResolution? _firstCanonicalMarker(
    List<ArcAdminMapMarker> markers, {
    required ArcIntelligenceLocationResolutionSource source,
    required bool Function(ArcAdminMapMarker marker) matches,
  }) {
    final candidates = markers.where(matches).toList(growable: false)
      ..sort(_compareCanonicalMarkerQuality);
    if (candidates.isEmpty) return null;
    final marker = candidates.first;
    return ArcIntelligenceLocationResolution(
      point: marker.point,
      layer: marker.layer,
      label: marker.name,
      source: source,
      confidence: marker.isPublished
          ? marker.confidence.score / 100
          : (marker.confidence.score / 100) * 0.86,
      canonicalMarker: marker,
    );
  }

  ArcIntelligenceLocationResolution? _resolveStaticMarker({
    required ArcRaidMap map,
    required String? canonicalPoiId,
    required String? publishedMarkerId,
    required Set<String> labels,
  }) {
    final candidates =
        map.markers
            .where((marker) {
              final markerIds = <String>{
                _normalize(marker.id),
                if (marker.payloadId?.trim().isNotEmpty == true)
                  _normalize(marker.payloadId!),
                _normalize(marker.id.replaceFirst('_poi_', '_')),
              };
              final markerNames = <String>{_normalize(marker.label)};
              return (canonicalPoiId != null &&
                      markerIds.contains(canonicalPoiId)) ||
                  (publishedMarkerId != null &&
                      markerIds.contains(publishedMarkerId)) ||
                  labels.any(markerNames.contains);
            })
            .toList(growable: false)
          ..sort(_compareStaticMarkerQuality);

    if (candidates.isEmpty) return null;
    final marker = candidates.first;
    return ArcIntelligenceLocationResolution(
      point: marker.point,
      layer: marker.layer,
      label: marker.label,
      source: ArcIntelligenceLocationResolutionSource.staticMarker,
      confidence: marker.confidence.score / 100,
      staticMarker: marker,
    );
  }

  ArcIntelligenceLocationResolution? _resolveLegacyPoi({
    required ArcRaidMap map,
    required String? canonicalPoiId,
    required Set<String> labels,
    required ArcRaidMapLayer preferredLayer,
  }) {
    final candidates =
        map.pois
            .where((poi) {
              final poiIds = <String>{_normalize(poi.id)};
              final poiNames = <String>{_normalize(poi.name)};
              return (canonicalPoiId != null &&
                      poiIds.contains(canonicalPoiId)) ||
                  labels.any(poiNames.contains);
            })
            .toList(growable: false)
          ..sort((a, b) {
            if (a.approximate != b.approximate) return a.approximate ? 1 : -1;
            return a.id.compareTo(b.id);
          });

    if (candidates.isEmpty) return null;
    final poi = candidates.first;
    return ArcIntelligenceLocationResolution(
      point: poi.point,
      layer: preferredLayer,
      label: poi.name,
      source: ArcIntelligenceLocationResolutionSource.legacyPoi,
      confidence: poi.approximate ? 0.62 : 0.72,
      legacyPoi: poi,
    );
  }

  ArcIntelligenceLocationResolution _resolveLegacyCoordinate({
    required ArcRaidMap map,
    required ArcNormalizedPoint point,
    required ArcRaidMapLayer preferredLayer,
  }) {
    final nearestPoi = _nearestPoi(map, point);
    if (nearestPoi == null) {
      return ArcIntelligenceLocationResolution(
        point: point,
        layer: preferredLayer,
        label: 'Legacy coordinates',
        source: ArcIntelligenceLocationResolutionSource.legacyCoordinate,
        confidence: 0.2,
        needsAdminReview: true,
      );
    }

    final confidence = _coordinateConfidence(nearestPoi.distance);
    final highConfidence =
        nearestPoi.distance <= highConfidenceCoordinateDistance;
    return ArcIntelligenceLocationResolution(
      point: highConfidence ? nearestPoi.poi.point : point,
      layer: preferredLayer,
      label: highConfidence ? nearestPoi.poi.name : 'Legacy coordinates',
      source: ArcIntelligenceLocationResolutionSource.legacyCoordinate,
      confidence: confidence,
      legacyPoi: highConfidence ? nearestPoi.poi : null,
      needsAdminReview:
          !highConfidence || nearestPoi.distance > reviewCoordinateDistance,
    );
  }

  _NearestPoi? _nearestPoi(ArcRaidMap map, ArcNormalizedPoint point) {
    _NearestPoi? nearest;
    for (final poi in map.pois) {
      final distance = point.distanceTo(poi.point);
      if (nearest == null || distance < nearest.distance) {
        nearest = _NearestPoi(poi: poi, distance: distance);
      }
    }
    return nearest;
  }

  double _coordinateConfidence(double distance) {
    final score = 1 - (distance / reviewCoordinateDistance).clamp(0.0, 1.0);
    return score.clamp(0.2, 0.98).toDouble();
  }

  Set<String> _markerCanonicalIds(ArcAdminMapMarker marker) {
    final rawId = _normalize(marker.id);
    final strippedLayerId = _normalize(
      marker.id.replaceAll(RegExp(r'^(world|marker)_[a-z0-9]+_[a-z0-9]+_'), ''),
    );
    final strippedPoiId = _normalize(
      marker.id.replaceAll(
        RegExp(r'^(world|marker)_[a-z0-9]+_[a-z0-9]+_poi_'),
        '',
      ),
    );
    final nameNorm = _normalize(marker.name);
    return <String>{
      rawId,
      strippedLayerId,
      strippedPoiId,
      nameNorm,
      _normalize(marker.id.replaceFirst('_poi_', '_')),
      if (marker.seedReferenceId?.trim().isNotEmpty == true)
        _normalize(marker.seedReferenceId!),
      if (marker.sourceRecordId?.trim().isNotEmpty == true)
        _normalize(marker.sourceRecordId!),
      for (final alias in marker.aliases) _normalize(alias),
    };
  }

  int _compareCanonicalMarkerQuality(ArcAdminMapMarker a, ArcAdminMapMarker b) {
    if (a.isPublished != b.isPublished) return a.isPublished ? -1 : 1;
    if (a.adminVerified != b.adminVerified) return a.adminVerified ? -1 : 1;
    final confidenceCompare = b.confidence.score.compareTo(a.confidence.score);
    if (confidenceCompare != 0) return confidenceCompare;
    return a.id.compareTo(b.id);
  }

  int _compareStaticMarkerQuality(ArcRaidMapMarker a, ArcRaidMapMarker b) {
    if (a.approximate != b.approximate) return a.approximate ? 1 : -1;
    final confidenceCompare = b.confidence.score.compareTo(a.confidence.score);
    if (confidenceCompare != 0) return confidenceCompare;
    final poiCompare = (b.category == ArcRaidMapMarkerCategory.poi ? 1 : 0)
        .compareTo(a.category == ArcRaidMapMarkerCategory.poi ? 1 : 0);
    if (poiCompare != 0) return poiCompare;
    return a.id.compareTo(b.id);
  }

  String? _normalizedOrNull(String? value) {
    final normalized = _normalize(value ?? '');
    return normalized.isEmpty ? null : normalized;
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }
}

class _NearestPoi {
  const _NearestPoi({required this.poi, required this.distance});

  final ArcRaidMapPoi poi;
  final double distance;
}
