import 'package:flutter/foundation.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

@immutable
class ArcRegisteredMapAsset {
  const ArcRegisteredMapAsset({
    required this.mapId,
    required this.displayName,
    required this.layerAssets,
    required this.layerCalibrations,
    this.statusLabel = 'Schematic only',
  });

  final String mapId;
  final String displayName;
  final Map<ArcRaidMapLayer, ArcRaidMapAsset> layerAssets;
  final Map<ArcRaidMapLayer, ArcRaidMapCalibration> layerCalibrations;
  final String statusLabel;

  bool get hasRenderableAsset =>
      layerAssets.values.any((asset) => asset.hasRenderableImage);

  bool get hasPublishedCalibration => layerCalibrations.entries.any(
    (entry) =>
        entry.value.published &&
        entry.value.valid &&
        layerAssets[entry.key]?.hasRenderableImage == true,
  );
}

class ArcMapAssetRegistry {
  const ArcMapAssetRegistry._();

  static const String blueGateMapId = 'blue_gate';
  static const String buriedCityMapId = 'buried_city';
  static const String damBattlegroundsMapId = 'dam_battlegrounds';
  static const String rivenTidesMapId = 'riven_tides';
  static const String spaceportMapId = 'spaceport';
  static const String stellaMontisMapId = 'stella_montis';

  static const List<ArcRaidMapAnchor> _identityAnchors = [
    ArcRaidMapAnchor(
      id: 'top_left',
      label: 'Top-left',
      canonicalPoint: ArcNormalizedPoint(x: 0, y: 0),
      imagePoint: ArcNormalizedPoint(x: 0, y: 0),
    ),
    ArcRaidMapAnchor(
      id: 'top_right',
      label: 'Top-right',
      canonicalPoint: ArcNormalizedPoint(x: 1, y: 0),
      imagePoint: ArcNormalizedPoint(x: 1, y: 0),
    ),
    ArcRaidMapAnchor(
      id: 'bottom_left',
      label: 'Bottom-left',
      canonicalPoint: ArcNormalizedPoint(x: 0, y: 1),
      imagePoint: ArcNormalizedPoint(x: 0, y: 1),
    ),
    ArcRaidMapAnchor(
      id: 'bottom_right',
      label: 'Bottom-right',
      canonicalPoint: ArcNormalizedPoint(x: 1, y: 1),
      imagePoint: ArcNormalizedPoint(x: 1, y: 1),
    ),
  ];

  static const Map<ArcRaidMapLayer, ArcRaidMapAsset> blueGateAssets = {
    ArcRaidMapLayer.surface: ArcRaidMapAsset(
      id: 'blue_gate_surface_v1',
      mapId: blueGateMapId,
      renderMode: ArcRaidMapRenderMode.calibratedGameMap,
      layer: ArcRaidMapLayer.surface,
      localAssetPath: 'assets/arc_raiders/maps/blue_gate/bluegate_master.webp',
      width: 2048,
      height: 1740,
      published: true,
    ),
    ArcRaidMapLayer.underground: ArcRaidMapAsset(
      id: 'blue_gate_level_2_v1',
      mapId: blueGateMapId,
      renderMode: ArcRaidMapRenderMode.calibratedGameMap,
      layer: ArcRaidMapLayer.underground,
      localAssetPath: 'assets/arc_raiders/maps/blue_gate/bluegate_level_2.webp',
      width: 2048,
      height: 1152,
      published: true,
    ),
  };

  static const Map<ArcRaidMapLayer, ArcRaidMapCalibration>
  blueGateCalibrations = {
    ArcRaidMapLayer.surface: ArcRaidMapCalibration(
      id: 'blue_gate_surface_identity_v1',
      mapId: blueGateMapId,
      anchors: _identityAnchors,
      residualError: 0,
      published: true,
    ),
    ArcRaidMapLayer.underground: ArcRaidMapCalibration(
      id: 'blue_gate_level_2_identity_v1',
      mapId: blueGateMapId,
      anchors: _identityAnchors,
      residualError: 0,
      published: true,
    ),
  };

  static const Map<ArcRaidMapLayer, ArcRaidMapAsset> buriedCityAssets = {
    ArcRaidMapLayer.surface: ArcRaidMapAsset(
      id: 'buried_city_surface_master_v1',
      mapId: buriedCityMapId,
      renderMode: ArcRaidMapRenderMode.calibratedGameMap,
      layer: ArcRaidMapLayer.surface,
      localAssetPath:
          'assets/arc_raiders/maps/buried_city/buried_city_master.webp',
      published: true,
    ),
  };

  static const Map<ArcRaidMapLayer, ArcRaidMapCalibration>
  buriedCityCalibrations = {
    ArcRaidMapLayer.surface: ArcRaidMapCalibration(
      id: 'buried_city_surface_provisional_v1',
      mapId: buriedCityMapId,
      anchors: _identityAnchors,
      residualError: 0,
      published: true,
    ),
  };

  static const Map<ArcRaidMapLayer, ArcRaidMapAsset> stellaMontisAssets = {
    ArcRaidMapLayer.surface: ArcRaidMapAsset(
      id: 'stella_montis_surface_master_v1',
      mapId: stellaMontisMapId,
      renderMode: ArcRaidMapRenderMode.calibratedGameMap,
      layer: ArcRaidMapLayer.surface,
      localAssetPath:
          'assets/arc_raiders/maps/stella_montis/stella_montis_master.webp',
      published: true,
    ),
    ArcRaidMapLayer.underground: ArcRaidMapAsset(
      id: 'stella_montis_level_2_master_v1',
      mapId: stellaMontisMapId,
      renderMode: ArcRaidMapRenderMode.calibratedGameMap,
      layer: ArcRaidMapLayer.underground,
      localAssetPath:
          'assets/arc_raiders/maps/stella_montis/stella_montis_level_2.webp',
      published: true,
    ),
  };

  static const Map<ArcRaidMapLayer, ArcRaidMapCalibration>
  stellaMontisCalibrations = {
    ArcRaidMapLayer.surface: ArcRaidMapCalibration(
      id: 'stella_montis_surface_provisional_v1',
      mapId: stellaMontisMapId,
      anchors: _identityAnchors,
      residualError: 0,
      published: true,
    ),
    ArcRaidMapLayer.underground: ArcRaidMapCalibration(
      id: 'stella_montis_level_2_provisional_v1',
      mapId: stellaMontisMapId,
      anchors: _identityAnchors,
      residualError: 0,
      published: true,
    ),
  };

  static const Map<ArcRaidMapLayer, ArcRaidMapAsset> damBattlegroundsAssets = {
    ArcRaidMapLayer.surface: ArcRaidMapAsset(
      id: 'dam_battlegrounds_surface_master_v1',
      mapId: damBattlegroundsMapId,
      renderMode: ArcRaidMapRenderMode.calibratedGameMap,
      layer: ArcRaidMapLayer.surface,
      localAssetPath:
          'assets/arc_raiders/maps/dam_battlegrounds/dam_battlegrounds_master.webp',
      published: true,
    ),
  };

  static const Map<ArcRaidMapLayer, ArcRaidMapCalibration>
  damBattlegroundsCalibrations = {
    ArcRaidMapLayer.surface: ArcRaidMapCalibration(
      id: 'dam_battlegrounds_surface_provisional_v1',
      mapId: damBattlegroundsMapId,
      anchors: _identityAnchors,
      residualError: 0,
      published: true,
    ),
  };

  static const Map<ArcRaidMapLayer, ArcRaidMapAsset> spaceportAssets = {
    ArcRaidMapLayer.surface: ArcRaidMapAsset(
      id: 'spaceport_surface_master_v1',
      mapId: spaceportMapId,
      renderMode: ArcRaidMapRenderMode.calibratedGameMap,
      layer: ArcRaidMapLayer.surface,
      localAssetPath: 'assets/arc_raiders/maps/spaceport/spaceport_master.webp',
      published: true,
    ),
    ArcRaidMapLayer.underground: ArcRaidMapAsset(
      id: 'spaceport_level_2_master_v1',
      mapId: spaceportMapId,
      renderMode: ArcRaidMapRenderMode.calibratedGameMap,
      layer: ArcRaidMapLayer.underground,
      localAssetPath:
          'assets/arc_raiders/maps/spaceport/spaceport_level_2.webp',
      published: true,
    ),
  };

  static const Map<ArcRaidMapLayer, ArcRaidMapCalibration>
  spaceportCalibrations = {
    ArcRaidMapLayer.surface: ArcRaidMapCalibration(
      id: 'spaceport_surface_provisional_v1',
      mapId: spaceportMapId,
      anchors: _identityAnchors,
      residualError: 0,
      published: true,
    ),
    ArcRaidMapLayer.underground: ArcRaidMapCalibration(
      id: 'spaceport_level_2_provisional_v1',
      mapId: spaceportMapId,
      anchors: _identityAnchors,
      residualError: 0,
      published: true,
    ),
  };

  static const Map<ArcRaidMapLayer, ArcRaidMapAsset> rivenTidesAssets = {
    ArcRaidMapLayer.surface: ArcRaidMapAsset(
      id: 'riven_tides_surface_master_v1',
      mapId: rivenTidesMapId,
      renderMode: ArcRaidMapRenderMode.calibratedGameMap,
      layer: ArcRaidMapLayer.surface,
      localAssetPath:
          'assets/arc_raiders/maps/riven_tides/riven_tides_master.webp',
      published: true,
    ),
  };

  static const Map<ArcRaidMapLayer, ArcRaidMapCalibration>
  rivenTidesCalibrations = {
    ArcRaidMapLayer.surface: ArcRaidMapCalibration(
      id: 'riven_tides_surface_provisional_v1',
      mapId: rivenTidesMapId,
      anchors: _identityAnchors,
      residualError: 0,
      published: true,
    ),
  };

  static const List<ArcRegisteredMapAsset> registeredMaps = [
    ArcRegisteredMapAsset(
      mapId: blueGateMapId,
      displayName: 'Blue Gate',
      layerAssets: blueGateAssets,
      layerCalibrations: blueGateCalibrations,
      statusLabel: 'Calibrated',
    ),
    ArcRegisteredMapAsset(
      mapId: buriedCityMapId,
      displayName: 'Buried City',
      layerAssets: buriedCityAssets,
      layerCalibrations: buriedCityCalibrations,
      statusLabel: 'Calibrated',
    ),
    ArcRegisteredMapAsset(
      mapId: damBattlegroundsMapId,
      displayName: 'Dam Battlegrounds',
      layerAssets: damBattlegroundsAssets,
      layerCalibrations: damBattlegroundsCalibrations,
      statusLabel: 'Calibrated',
    ),
    ArcRegisteredMapAsset(
      mapId: spaceportMapId,
      displayName: 'Spaceport',
      layerAssets: spaceportAssets,
      layerCalibrations: spaceportCalibrations,
      statusLabel: 'Calibrated',
    ),
    ArcRegisteredMapAsset(
      mapId: stellaMontisMapId,
      displayName: 'Stella Montis',
      layerAssets: stellaMontisAssets,
      layerCalibrations: stellaMontisCalibrations,
      statusLabel: 'Calibrated',
    ),
    ArcRegisteredMapAsset(
      mapId: rivenTidesMapId,
      displayName: 'Riven Tides',
      layerAssets: rivenTidesAssets,
      layerCalibrations: rivenTidesCalibrations,
      statusLabel: 'Calibrated',
    ),
  ];

  static const Map<String, String> _canonicalMapAliases = {
    'bluegate': blueGateMapId,
    'blue gate': blueGateMapId,
    'the blue gate': blueGateMapId,
    'buried city': buriedCityMapId,
    'buried_city': buriedCityMapId,
    'dam battlegrounds': damBattlegroundsMapId,
    'dam': damBattlegroundsMapId,
    'dam_battlegrounds': damBattlegroundsMapId,
    'riven tides': rivenTidesMapId,
    'riven_tides': rivenTidesMapId,
    'spaceport': spaceportMapId,
    'stella montis': stellaMontisMapId,
    'stella_montis': stellaMontisMapId,
  };

  static const Map<String, ArcRaidMapLayer> _canonicalLayerAliases = {
    'surface': ArcRaidMapLayer.surface,
    'surface_layer': ArcRaidMapLayer.surface,
    'level 1': ArcRaidMapLayer.surface,
    'level_1': ArcRaidMapLayer.surface,
    'l1': ArcRaidMapLayer.surface,
    'underground': ArcRaidMapLayer.underground,
    'level 2': ArcRaidMapLayer.underground,
    'level_2': ArcRaidMapLayer.underground,
    'level2': ArcRaidMapLayer.underground,
    'l2': ArcRaidMapLayer.underground,
    'transition': ArcRaidMapLayer.transition,
  };

  static String? canonicalMapIdFor(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final normalized = _normalizeIdentifier(trimmed);
    if (normalized.isEmpty) return null;
    if (registeredMapIds.contains(normalized)) return normalized;
    return _canonicalMapAliases[normalized];
  }

  static String? canonicalMapDisplayNameFor(String? value) {
    final mapId = canonicalMapIdFor(value);
    if (mapId == null) return null;
    return registrationFor(mapId)?.displayName;
  }

  static ArcRegisteredMapAsset? registrationFor(String? mapId) {
    final canonicalId = canonicalMapIdFor(mapId);
    if (canonicalId == null) return null;
    for (final registration in registeredMaps) {
      if (registration.mapId == canonicalId) return registration;
    }
    return null;
  }

  static List<String> get registeredMapIds =>
      registeredMaps.map((entry) => entry.mapId).toList(growable: false);

  static ArcRaidMapLayer resolveLayer(String? value) {
    if (value == null) return ArcRaidMapLayer.surface;
    final normalized = _normalizeIdentifier(value);
    if (normalized.isEmpty) return ArcRaidMapLayer.surface;
    return _canonicalLayerAliases[normalized] ?? ArcRaidMapLayer.surface;
  }

  static Map<ArcRaidMapLayer, ArcRaidMapAsset> assetsFor(String? mapId) {
    return registrationFor(mapId)?.layerAssets ??
        const <ArcRaidMapLayer, ArcRaidMapAsset>{};
  }

  static Map<ArcRaidMapLayer, ArcRaidMapCalibration> calibrationsFor(
    String? mapId,
  ) {
    return registrationFor(mapId)?.layerCalibrations ??
        const <ArcRaidMapLayer, ArcRaidMapCalibration>{};
  }

  static String statusFor(String? mapId) {
    return registrationFor(mapId)?.statusLabel ?? 'Schematic only';
  }

  static bool hasRegisteredAsset(String? mapId) {
    return registrationFor(mapId)?.hasRenderableAsset == true;
  }

  static bool hasPublishedCalibration(String? mapId) {
    return registrationFor(mapId)?.hasPublishedCalibration == true;
  }

  static String _normalizeIdentifier(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }
}
