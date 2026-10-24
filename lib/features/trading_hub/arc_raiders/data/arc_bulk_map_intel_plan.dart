import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

/// Admin-only input. The empty POI set means *map-wide unlocated intelligence*,
/// never a fabricated pin at the centre of the map.
class ArcBulkIntelRequest {
  const ArcBulkIntelRequest({
    required this.kind,
    required this.name,
    required this.mapPoiIds,
    required this.containerTypeIds,
    required this.noContainer,
    required this.confidence,
    this.blueprintId,
    this.itemId,
    this.subtypeId,
    this.subtypeLabel,
    this.description = '',
    this.conditionLabel = '',
    this.sourceLabel = 'UAG Admin Bulk Intel',
  });

  final ArcAdminMapMarkerKind kind;
  final String name;
  final Map<String, Set<String>> mapPoiIds;
  final Set<String> containerTypeIds;
  final bool noContainer;
  final ArcRaidIntelConfidence confidence;
  final String? blueprintId;
  final String? itemId;
  final String? subtypeId;
  final String? subtypeLabel;
  final String description;
  final String conditionLabel;
  final String sourceLabel;
}

class ArcBulkMapAreaIntel {
  const ArcBulkMapAreaIntel({
    required this.id,
    required this.mapId,
    required this.kind,
    required this.name,
    required this.containerTypeIds,
    required this.confidence,
    required this.description,
    required this.conditionLabel,
    required this.sourceLabel,
    this.blueprintId,
    this.itemId,
    this.subtypeId,
  });

  final String id;
  final String mapId;
  final String kind;
  final String name;
  final List<String> containerTypeIds;
  final ArcRaidIntelConfidence confidence;
  final String description;
  final String conditionLabel;
  final String sourceLabel;
  final String? blueprintId;
  final String? itemId;
  final String? subtypeId;

  Map<String, dynamic> toMap() => {
    'id': id,
    'mapId': mapId,
    'kind': kind,
    'name': name,
    'containerTypeIds': containerTypeIds,
    'locationPrecision': 'map_wide_unlocated',
    'confidence': confidence.name,
    'description': description,
    'conditionLabel': conditionLabel,
    'sourceLabel': sourceLabel,
    'blueprintId': blueprintId,
    'itemId': itemId,
    'subtypeId': subtypeId,
    'state': 'draft',
  };
}

class ArcBulkIntelPlan {
  const ArcBulkIntelPlan({required this.markers, required this.unlocated});

  final List<ArcAdminMapMarker> markers;
  final List<ArcBulkMapAreaIntel> unlocated;
  int get total => markers.length + unlocated.length;

  static ArcBulkIntelPlan build(ArcBulkIntelRequest request) {
    final name = request.name.trim();
    if (name.isEmpty) {
      throw ArgumentError('Give the intel an item or marker name.');
    }
    if (request.mapPoiIds.isEmpty) {
      throw ArgumentError('Select at least one map.');
    }
    if (request.kind == ArcAdminMapMarkerKind.blueprint &&
        (request.blueprintId?.trim().isEmpty ?? true)) {
      throw ArgumentError('Choose a Blueprint.');
    }
    if (request.noContainer && request.containerTypeIds.isNotEmpty) {
      throw ArgumentError('No container cannot be combined with containers.');
    }
    if (request.mapPoiIds.length > 10) {
      throw ArgumentError('Too many maps.');
    }
    final markerDrafts = <ArcAdminMapMarker>[];
    final areaDrafts = <ArcBulkMapAreaIntel>[];
    final containers =
        request.noContainer ? <String>[] : request.containerTypeIds.toList()
          ..sort();

    for (final entry in request.mapPoiIds.entries) {
      final map = ArcRaidIntelligenceSeedData.mapById(entry.key);
      if (map.id != entry.key) {
        throw ArgumentError('Unknown map: ${entry.key}');
      }
      // The map-wide row is informational only and has NO map coordinates.
      if (entry.value.isEmpty) {
        areaDrafts.add(
          ArcBulkMapAreaIntel(
            id: stableId(
              'area|${map.id}|${request.kind.name}|$name|${request.blueprintId ?? ''}|${request.itemId ?? ''}|${request.subtypeId ?? ''}',
            ),
            mapId: map.id,
            kind: request.kind.name,
            name: name,
            containerTypeIds: containers,
            confidence: request.confidence,
            description: request.description.trim(),
            conditionLabel: request.conditionLabel.trim(),
            sourceLabel: request.sourceLabel.trim(),
            blueprintId: request.blueprintId,
            itemId: request.itemId,
            subtypeId: request.subtypeId,
          ),
        );
        continue;
      }
      for (final poiId in entry.value) {
        final hits = map.pois.where((poi) => poi.id == poiId).toList();
        if (hits.length != 1) {
          throw ArgumentError(
            'POI does not belong to ${map.displayName}: $poiId',
          );
        }
        final poi = hits.single;
        markerDrafts.add(
          ArcAdminMapMarker(
            id: stableId(
              'poi|${map.id}|${poi.id}|${request.kind.name}|$name|${request.blueprintId ?? ''}|${request.itemId ?? ''}|${request.subtypeId ?? ''}',
            ),
            mapId: map.id,
            layer: ArcRaidMapLayer.surface,
            kind: request.kind,
            name: '$name — ${poi.name} (approximate POI)',
            description: request.description.trim(),
            conditionLabel: request.conditionLabel.trim(),
            subtypeId: request.subtypeId,
            subtypeLabel: request.subtypeLabel,
            itemId: request.itemId,
            blueprintId: request.blueprintId,
            point: poi.point,
            sourceLabel: request.sourceLabel.trim(),
            sourceAttribution:
                'POI-level approximate intelligence, not a confirmed exact spawn.',
            seedReferenceId: poi.id,
            coordinateSpace: 'poi_approximate',
            poiId: poi.id,
            containerTypeIds: containers,
            confidence: request.confidence,
            state: ArcAdminMapMarkerState.draft,
            adminVerified: false,
            provisionalVisible: false,
          ),
        );
      }
    }
    if (markerDrafts.length + areaDrafts.length > 200) {
      throw ArgumentError('Maximum 200 records per batch.');
    }
    return ArcBulkIntelPlan(markers: markerDrafts, unlocated: areaDrafts);
  }

  /// Stable idempotency key: resubmitting the same POI/item cannot create
  /// duplicate documents. Persisting code refuses overwrites of existing IDs.
  static String stableId(String key) {
    var first = 5381;
    var second = 2166136261;
    for (final unit in key.toLowerCase().codeUnits) {
      // 32-bit components avoid JS precision loss in Flutter Web.
      first = ((first * 33) + unit) & 0xffffffff;
      second = ((second * 31) + unit) & 0xffffffff;
    }
    return 'uag_bulk_${first.toRadixString(16).padLeft(8, '0')}${second.toRadixString(16).padLeft(8, '0')}';
  }
}
