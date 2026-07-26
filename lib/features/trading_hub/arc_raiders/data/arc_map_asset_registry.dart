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
      published: false,
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
      statusLabel: 'Provisional map image',
    ),
  ];

  static ArcRegisteredMapAsset? registrationFor(String mapId) {
    for (final registration in registeredMaps) {
      if (registration.mapId == mapId) return registration;
    }
    return null;
  }

  static Map<ArcRaidMapLayer, ArcRaidMapAsset> assetsFor(String mapId) {
    return registrationFor(mapId)?.layerAssets ??
        const <ArcRaidMapLayer, ArcRaidMapAsset>{};
  }

  static Map<ArcRaidMapLayer, ArcRaidMapCalibration> calibrationsFor(
    String mapId,
  ) {
    return registrationFor(mapId)?.layerCalibrations ??
        const <ArcRaidMapLayer, ArcRaidMapCalibration>{};
  }

  static String statusFor(String mapId) {
    return registrationFor(mapId)?.statusLabel ?? 'Schematic only';
  }

  static bool hasRegisteredAsset(String mapId) {
    return registrationFor(mapId)?.hasRenderableAsset == true;
  }

  static bool hasPublishedCalibration(String mapId) {
    return registrationFor(mapId)?.hasPublishedCalibration == true;
  }
}
