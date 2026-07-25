import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

class ArcMapAssetRegistry {
  const ArcMapAssetRegistry._();

  static const String blueGateMapId = 'blue_gate';

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
      anchors: [
        ArcRaidMapAnchor(
          id: 'surface_top_left',
          label: 'Surface top-left',
          canonicalPoint: ArcNormalizedPoint(x: 0, y: 0),
          imagePoint: ArcNormalizedPoint(x: 0, y: 0),
        ),
        ArcRaidMapAnchor(
          id: 'surface_top_right',
          label: 'Surface top-right',
          canonicalPoint: ArcNormalizedPoint(x: 1, y: 0),
          imagePoint: ArcNormalizedPoint(x: 1, y: 0),
        ),
        ArcRaidMapAnchor(
          id: 'surface_bottom_left',
          label: 'Surface bottom-left',
          canonicalPoint: ArcNormalizedPoint(x: 0, y: 1),
          imagePoint: ArcNormalizedPoint(x: 0, y: 1),
        ),
        ArcRaidMapAnchor(
          id: 'surface_bottom_right',
          label: 'Surface bottom-right',
          canonicalPoint: ArcNormalizedPoint(x: 1, y: 1),
          imagePoint: ArcNormalizedPoint(x: 1, y: 1),
        ),
      ],
      residualError: 0,
      published: true,
    ),
    ArcRaidMapLayer.underground: ArcRaidMapCalibration(
      id: 'blue_gate_level_2_identity_v1',
      mapId: blueGateMapId,
      anchors: [
        ArcRaidMapAnchor(
          id: 'level_2_top_left',
          label: 'Level 2 top-left',
          canonicalPoint: ArcNormalizedPoint(x: 0, y: 0),
          imagePoint: ArcNormalizedPoint(x: 0, y: 0),
        ),
        ArcRaidMapAnchor(
          id: 'level_2_top_right',
          label: 'Level 2 top-right',
          canonicalPoint: ArcNormalizedPoint(x: 1, y: 0),
          imagePoint: ArcNormalizedPoint(x: 1, y: 0),
        ),
        ArcRaidMapAnchor(
          id: 'level_2_bottom_left',
          label: 'Level 2 bottom-left',
          canonicalPoint: ArcNormalizedPoint(x: 0, y: 1),
          imagePoint: ArcNormalizedPoint(x: 0, y: 1),
        ),
        ArcRaidMapAnchor(
          id: 'level_2_bottom_right',
          label: 'Level 2 bottom-right',
          canonicalPoint: ArcNormalizedPoint(x: 1, y: 1),
          imagePoint: ArcNormalizedPoint(x: 1, y: 1),
        ),
      ],
      residualError: 0,
      published: true,
    ),
  };

  static Map<ArcRaidMapLayer, ArcRaidMapAsset> assetsFor(String mapId) {
    return mapId == blueGateMapId
        ? blueGateAssets
        : const <ArcRaidMapLayer, ArcRaidMapAsset>{};
  }

  static Map<ArcRaidMapLayer, ArcRaidMapCalibration> calibrationsFor(
    String mapId,
  ) {
    return mapId == blueGateMapId
        ? blueGateCalibrations
        : const <ArcRaidMapLayer, ArcRaidMapCalibration>{};
  }
}
