import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_intelligence_location_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

/// Reconciles stable map identities with the latest published admin geometry.
///
/// POI/extraction names and stable seed references remain the durable identity.
/// Coordinates are treated as replaceable geometry so moving a published marker
/// automatically moves all intelligence linked to that identity.
class ArcRaidRuntimeMapResolver {
  const ArcRaidRuntimeMapResolver();

  ArcRaidMap resolve({
    required ArcRaidMap seedMap,
    List<ArcAdminMapMarker> adminMarkers = const <ArcAdminMapMarker>[],
  }) {
    final mapMarkers = adminMarkers
        .where((marker) => marker.mapId == seedMap.id && marker.isPublished)
        .toList(growable: false);
    if (mapMarkers.isEmpty) return seedMap;

    final pois = [
      for (final poi in seedMap.pois) _resolvedPoi(seedMap, poi, mapMarkers),
    ];
    final extractions = _resolvedExtractions(seedMap, mapMarkers);
    final hatches = _resolvedHatches(seedMap, mapMarkers);
    final routeNodes = [
      for (final node in seedMap.routeNodes)
        _resolvedRouteNode(node, pois, extractions, hatches),
    ];

    return ArcRaidMap(
      id: seedMap.id,
      displayName: seedMap.displayName,
      bounds: seedMap.bounds,
      regions: seedMap.regions,
      pois: pois,
      spawnRegions: seedMap.spawnRegions,
      extractions: extractions,
      hatches: hatches,
      routeNodes: routeNodes,
      routeEdges: seedMap.routeEdges,
      markers: seedMap.markers,
      aliases: seedMap.aliases,
      asset: seedMap.asset,
      calibration: seedMap.calibration,
      layerAssets: seedMap.layerAssets,
      layerCalibrations: seedMap.layerCalibrations,
      publicationState: seedMap.publicationState,
      dataVersion: '${seedMap.dataVersion}+published-geometry',
      lastReviewed: seedMap.lastReviewed,
      schematicLabel: seedMap.schematicLabel,
    );
  }

  ArcRaidMapPoi _resolvedPoi(
    ArcRaidMap map,
    ArcRaidMapPoi poi,
    List<ArcAdminMapMarker> markers,
  ) {
    final resolution = const ArcIntelligenceLocationResolver().resolve(
      map: map,
      adminMarkers: markers,
      canonicalPoiId: poi.id,
      currentPoiName: poi.name,
      legacyPoint: poi.point,
    );
    if (resolution == null || !resolution.resolvedFromCanonicalMarker) {
      return poi;
    }
    return ArcRaidMapPoi(
      id: poi.id,
      mapId: poi.mapId,
      name: poi.name,
      point: resolution.point,
      regionId: poi.regionId,
      approximate: resolution.approximate,
      lootTags: poi.lootTags,
    );
  }

  List<ArcRaidExtraction> _resolvedExtractions(
    ArcRaidMap map,
    List<ArcAdminMapMarker> markers,
  ) {
    final result = <ArcRaidExtraction>[];
    final consumedMarkerIds = <String>{};

    for (final extraction in map.extractions) {
      final marker = _bestMarkerForIdentity(
        markers,
        kind: ArcAdminMapMarkerKind.extraction,
        stableId: extraction.id,
        name: extraction.name,
      );
      if (marker == null) {
        result.add(extraction);
        continue;
      }
      consumedMarkerIds.add(marker.id);
      result.add(
        ArcRaidExtraction(
          id: extraction.id,
          mapId: extraction.mapId,
          name: marker.name,
          point: marker.point,
          visibleByDefault: extraction.visibleByDefault,
          notes: marker.description.trim().isEmpty
              ? extraction.notes
              : marker.description.trim(),
        ),
      );
    }

    for (final marker in markers) {
      if (marker.kind != ArcAdminMapMarkerKind.extraction ||
          consumedMarkerIds.contains(marker.id)) {
        continue;
      }
      result.add(
        ArcRaidExtraction(
          id: _runtimeId(marker, 'extraction'),
          mapId: map.id,
          name: marker.name,
          point: marker.point,
          notes: marker.description.trim().isEmpty
              ? 'Published admin extraction.'
              : marker.description.trim(),
        ),
      );
    }

    return List<ArcRaidExtraction>.unmodifiable(result);
  }

  List<ArcRaiderHatch> _resolvedHatches(
    ArcRaidMap map,
    List<ArcAdminMapMarker> markers,
  ) {
    final result = <ArcRaiderHatch>[];
    final consumedMarkerIds = <String>{};

    for (final hatch in map.hatches) {
      final marker = _bestMarkerForIdentity(
        markers,
        kind: ArcAdminMapMarkerKind.raiderHatch,
        stableId: hatch.id,
        name: hatch.name,
      );
      if (marker == null) {
        result.add(hatch);
        continue;
      }
      consumedMarkerIds.add(marker.id);
      result.add(
        ArcRaiderHatch(
          id: hatch.id,
          mapId: hatch.mapId,
          name: marker.name,
          point: marker.point,
          requiresKey: hatch.requiresKey,
        ),
      );
    }

    for (final marker in markers) {
      if (marker.kind != ArcAdminMapMarkerKind.raiderHatch ||
          consumedMarkerIds.contains(marker.id)) {
        continue;
      }
      result.add(
        ArcRaiderHatch(
          id: _runtimeId(marker, 'hatch'),
          mapId: map.id,
          name: marker.name,
          point: marker.point,
          requiresKey: true,
        ),
      );
    }

    return List<ArcRaiderHatch>.unmodifiable(result);
  }

  ArcRaidRouteNode _resolvedRouteNode(
    ArcRaidRouteNode node,
    List<ArcRaidMapPoi> pois,
    List<ArcRaidExtraction> extractions,
    List<ArcRaiderHatch> hatches,
  ) {
    ArcNormalizedPoint? point;
    for (final poi in pois) {
      if (poi.id == node.id || _sameName(poi.name, node.name)) {
        point = poi.point;
        break;
      }
    }
    if (point == null) {
      for (final extraction in extractions) {
        if (extraction.id == node.id || _sameName(extraction.name, node.name)) {
          point = extraction.point;
          break;
        }
      }
    }
    if (point == null) {
      for (final hatch in hatches) {
        if (hatch.id == node.id || _sameName(hatch.name, node.name)) {
          point = hatch.point;
          break;
        }
      }
    }
    if (point == null || point == node.point) return node;
    return ArcRaidRouteNode(
      id: node.id,
      mapId: node.mapId,
      name: node.name,
      point: point,
      layer: node.layer,
    );
  }

  ArcAdminMapMarker? _bestMarkerForIdentity(
    List<ArcAdminMapMarker> markers, {
    required ArcAdminMapMarkerKind kind,
    required String stableId,
    required String name,
  }) {
    final stable = _normalize(stableId);
    final label = _normalize(name);
    final candidates = markers.where((marker) => marker.kind == kind).toList();

    for (final marker in candidates) {
      if (_normalize(marker.seedReferenceId ?? '') == stable) return marker;
    }

    final named = candidates
        .where(
          (marker) =>
              _normalize(marker.name) == label ||
              marker.aliases.any((alias) => _normalize(alias) == label),
        )
        .toList(growable: false);
    return named.length == 1 ? named.first : null;
  }

  String _runtimeId(ArcAdminMapMarker marker, String prefix) {
    final stable = marker.seedReferenceId?.trim();
    if (stable != null && stable.isNotEmpty) return stable;
    return 'admin_${prefix}_${marker.id}';
  }

  bool _sameName(String left, String right) =>
      _normalize(left) == _normalize(right);

  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
