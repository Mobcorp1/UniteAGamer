import 'dart:convert';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_map_marker_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

class ArcPermittedJsonMapMarkerImportAdapter {
  const ArcPermittedJsonMapMarkerImportAdapter();

  ArcMapMarkerImportPayload parse(
    String rawJson, {
    required String defaultMapId,
    required ArcRaidMapLayer defaultLayer,
  }) {
    final decoded = jsonDecode(rawJson);
    final root = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{'records': decoded};
    final source = _sourceFrom(root['source'], defaultMapId: defaultMapId);
    final recordsRaw = root['records'] is List
        ? root['records'] as List
        : root['markers'] is List
        ? root['markers'] as List
        : decoded is List
        ? decoded
        : const <dynamic>[];
    final rootCoordinateSpace = ArcMapMarkerCoordinateSpaceX.fromStorage(
      root['coordinateSpace']?.toString(),
    );
    final rootMapId = _mapId(root['mapId']?.toString(), defaultMapId);
    final rootLayer = _layerFrom(root['layer']?.toString(), defaultLayer);
    final rootWidth = _doubleFrom(root['imageWidth'] ?? root['sourceWidth']);
    final rootHeight = _doubleFrom(root['imageHeight'] ?? root['sourceHeight']);
    final records = <ArcExternalMapMarkerRecord>[];

    for (var index = 0; index < recordsRaw.length; index++) {
      final value = recordsRaw[index];
      if (value is! Map) continue;
      final map = Map<String, dynamic>.from(value);
      final point = _pointFrom(map);
      if (point == null) continue;
      final name = (map['name'] ?? map['label'] ?? 'Imported marker')
          .toString()
          .trim();
      records.add(
        ArcExternalMapMarkerRecord(
          id: _recordId(map, index),
          mapId: _mapId(map['mapId']?.toString(), rootMapId),
          layer: _layerFrom(map['layer']?.toString(), rootLayer),
          kind: _kindFrom(map['kind'] ?? map['category'] ?? map['type']),
          name: name.isEmpty ? 'Imported marker' : name,
          description:
              (map['description'] ?? map['detail'] ?? map['notes'])
                  ?.toString()
                  .trim() ??
              '',
          point: point,
          blueprintId: map['blueprintId']?.toString(),
          confidence: ArcRaidIntelConfidenceX.fromStorage(
            map['confidence']?.toString(),
          ),
          coordinateSpace: map.containsKey('coordinateSpace')
              ? ArcMapMarkerCoordinateSpaceX.fromStorage(
                  map['coordinateSpace']?.toString(),
                )
              : rootCoordinateSpace,
          sourceWidth: _doubleFrom(map['sourceWidth']) ?? rootWidth,
          sourceHeight: _doubleFrom(map['sourceHeight']) ?? rootHeight,
          sourceLayerId: map['sourceLayerId']?.toString(),
          tags: _tagsFrom(map['tags']),
        ),
      );
    }

    return ArcMapMarkerImportPayload(source: source, records: records);
  }

  ArcMapMarkerSourceDescriptor _sourceFrom(
    dynamic value, {
    required String defaultMapId,
  }) {
    final map = value is Map ? Map<String, dynamic>.from(value) : const {};
    final name = (map['name'] ?? map['label'] ?? 'Admin JSON import')
        .toString()
        .trim();
    final id = (map['id'] ?? map['sourceId'] ?? _slug(name)).toString().trim();
    return ArcMapMarkerSourceDescriptor(
      id: id.isEmpty ? 'admin_json_$defaultMapId' : _slug(id),
      name: name.isEmpty ? 'Admin JSON import' : name,
      attribution: map['attribution']?.toString().trim() ?? '',
      permission: ArcAdminMapMarkerSourcePermissionX.fromStorage(
        (map['permissionState'] ?? map['permission'] ?? map['licenseState'])
            ?.toString(),
      ),
      sourceUrl: map['sourceUrl']?.toString(),
      licenseUrl: map['licenseUrl']?.toString(),
      fetchedAt: DateTime.tryParse(map['fetchedAt']?.toString() ?? ''),
    );
  }

  static String _recordId(Map<String, dynamic> map, int index) {
    final raw = (map['id'] ?? map['recordId'] ?? map['sourceRecordId'])
        ?.toString()
        .trim();
    if (raw == null || raw.isEmpty) return 'record_$index';
    return _slug(raw);
  }

  static String _mapId(String? value, String fallback) {
    if (value == null || value.trim().isEmpty) return fallback;
    return ArcRaidIntelligenceSeedData.normalizeMapId(value);
  }

  static ArcRaidMapLayer _layerFrom(String? value, ArcRaidMapLayer fallback) {
    return ArcRaidMapLayer.values.firstWhere(
      (layer) =>
          layer.name == value?.trim().toLowerCase() ||
          layer.storageValue == value?.trim().toLowerCase(),
      orElse: () => fallback,
    );
  }

  static ArcAdminMapMarkerKind _kindFrom(dynamic value) {
    final raw = value?.toString().trim().toLowerCase() ?? '';
    final normalized = raw.replaceAll('-', '_').replaceAll(' ', '_');
    return switch (normalized) {
      'poi' || 'point_of_interest' => ArcAdminMapMarkerKind.poi,
      'extraction' ||
      'standard_extraction' ||
      'exit' => ArcAdminMapMarkerKind.extraction,
      'raider_hatch' || 'hatch' => ArcAdminMapMarkerKind.raiderHatch,
      'blueprint' ||
      'blueprint_find' ||
      'blueprint_opportunity' => ArcAdminMapMarkerKind.blueprint,
      'quest' ||
      'quest_location' ||
      'quest_objective' => ArcAdminMapMarkerKind.questLocation,
      'event' ||
      'map_event' ||
      'world_event' ||
      'hurricane' => ArcAdminMapMarkerKind.mapEvent,
      'resource' || 'resource_node' => ArcAdminMapMarkerKind.resourceNode,
      'natural_resource' ||
      'natural_resources' ||
      'material' ||
      'materials' => ArcAdminMapMarkerKind.naturalResource,
      'arc' ||
      'arc_spawn' ||
      'machine_spawn' ||
      'enemy_spawn' => ArcAdminMapMarkerKind.arcSpawn,
      'weapon_case' || 'weapon_crate' => ArcAdminMapMarkerKind.weaponCase,
      'weapon_cache' || 'weapon' => ArcAdminMapMarkerKind.weaponCache,
      'first_wave_cache' ||
      'first_wave' ||
      'hurricane_cache' => ArcAdminMapMarkerKind.firstWaveCache,
      'raider_cache' || 'cache' => ArcAdminMapMarkerKind.raiderCache,
      'field_crate' || 'field_crates' => ArcAdminMapMarkerKind.fieldCrate,
      'loot' ||
      'loot_container' ||
      'crate' => ArcAdminMapMarkerKind.lootContainer,
      'container' ||
      'containers' ||
      'container_cluster' => ArcAdminMapMarkerKind.containerCluster,
      'locked_room' => ArcAdminMapMarkerKind.lockedRoom,
      'security_room' ||
      'security' ||
      'security_locker' => ArcAdminMapMarkerKind.securityRoom,
      'high_value_loot' || 'rare_loot' => ArcAdminMapMarkerKind.highValueLoot,
      'key' || 'access_key' => ArcAdminMapMarkerKind.key,
      'key_room' ||
      'key_required' ||
      'key_required_location' ||
      'locked_key_room' => ArcAdminMapMarkerKind.keyRequiredLocation,
      'arc_threat' || 'threat' => ArcAdminMapMarkerKind.arcThreat,
      'extraction_danger' ||
      'exit_danger' => ArcAdminMapMarkerKind.extractionDanger,
      'surface_transition' ||
      'surface_access' => ArcAdminMapMarkerKind.surfaceTransition,
      'underground_transition' ||
      'underground_access' ||
      'level_2_access' => ArcAdminMapMarkerKind.undergroundTransition,
      'hazard' || 'danger' || 'danger_zone' => ArcAdminMapMarkerKind.hazard,
      _ => ArcAdminMapMarkerKind.customIntel,
    };
  }

  static ArcNormalizedPoint? _pointFrom(Map<String, dynamic> map) {
    final nested = map['point'];
    if (nested is Map) {
      return ArcNormalizedPoint.fromMap(Map<String, dynamic>.from(nested));
    }
    final x = _doubleFrom(map['x'] ?? map['left'] ?? map['u']);
    final y = _doubleFrom(map['y'] ?? map['top'] ?? map['v']);
    if (x == null || y == null) return null;
    return ArcNormalizedPoint(x: x, y: y);
  }

  static List<String> _tagsFrom(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  static double? _doubleFrom(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static String _slug(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return slug.isEmpty ? 'source' : slug;
  }
}
