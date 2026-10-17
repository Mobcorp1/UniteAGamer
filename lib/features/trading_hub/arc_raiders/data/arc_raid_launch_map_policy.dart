import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';

/// Defines map precedence when Raid Intelligence is opened from an explicit
/// recommendation versus a normal/manual app entry.
class ArcRaidLaunchMapPolicy {
  const ArcRaidLaunchMapPolicy._();

  static String? canonicalExplicitMapId(String? rawMapId) {
    final trimmed = rawMapId?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    final canonical = ArcMapAssetRegistry.canonicalMapIdFor(trimmed) ?? trimmed;
    if (!ArcRaidIntelligenceSeedData.supportedMapIds.contains(canonical)) {
      return null;
    }
    return canonical;
  }

  static bool routeCanApply({
    required String? explicitMapId,
    required String routeMapId,
  }) {
    if (explicitMapId == null) return true;

    final canonicalRoute =
        ArcMapAssetRegistry.canonicalMapIdFor(routeMapId) ?? routeMapId;
    return canonicalRoute == explicitMapId;
  }

  static bool shouldRestoreLastMap({required String? explicitMapId}) =>
      explicitMapId == null;
}
