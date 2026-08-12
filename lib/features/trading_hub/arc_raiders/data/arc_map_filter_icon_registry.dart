import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_taxonomy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

class ArcMapFilterIconRegistry {
  const ArcMapFilterIconRegistry._();

  static const String assetDirectory = 'assets/arc_raiders/map_filter_icons';
  static const String fallbackIconKey = 'map_filter_unknown';
  static const String fallbackAssetPath =
      '$assetDirectory/$fallbackIconKey.svg';

  static Set<String> get canonicalIconKeys => {
    for (final entry in ArcMapFilterTaxonomy.all) entry.iconKey,
  };

  static List<String> get canonicalAssetPaths => [
    for (final key in canonicalIconKeys) assetPathFor(key),
  ];

  static String assetPathFor(String iconKey) {
    final normalized = _normalize(iconKey);
    if (!canonicalIconKeys.contains(normalized)) {
      return fallbackAssetPath;
    }
    return '$assetDirectory/$normalized.svg';
  }

  static String? iconKeyForSubtype(String? subtypeId) {
    return ArcMapFilterTaxonomy.iconKeyFor(subtypeId);
  }

  static String assetPathForSubtype(String? subtypeId) {
    final iconKey = iconKeyForSubtype(subtypeId);
    if (iconKey == null) return fallbackAssetPath;
    return assetPathFor(iconKey);
  }

  static String? iconKeyForMarkerCategory(ArcRaidMapMarkerCategory category) {
    return switch (category) {
      ArcRaidMapMarkerCategory.standardExtraction => 'extract_standard',
      ArcRaidMapMarkerCategory.raiderHatch => 'extract_raider_hatch',
      ArcRaidMapMarkerCategory.spawn ||
      ArcRaidMapMarkerCategory.spawnRegion => 'infra_player_spawn',
      ArcRaidMapMarkerCategory.poi => 'infra_field_depot',
      ArcRaidMapMarkerCategory.weaponCase => 'loot_weapon_case',
      ArcRaidMapMarkerCategory.securityLocker => 'loot_security_locker',
      ArcRaidMapMarkerCategory.firstWaveCache => 'loot_first_wave_cache',
      ArcRaidMapMarkerCategory.raiderCache => 'loot_raider_cache',
      ArcRaidMapMarkerCategory.fieldCrate => 'loot_field_crate',
      ArcRaidMapMarkerCategory.containerCluster ||
      ArcRaidMapMarkerCategory.generalLoot => 'loot_special_container',
      ArcRaidMapMarkerCategory.lockedRoom => 'access_locked_room',
      ArcRaidMapMarkerCategory.keyRoom => 'access_key_room',
      ArcRaidMapMarkerCategory.arcThreat => 'arc_probe',
      ArcRaidMapMarkerCategory.questObjective ||
      ArcRaidMapMarkerCategory.operationObjective ||
      ArcRaidMapMarkerCategory.teammateObjective => 'quest_objective',
      ArcRaidMapMarkerCategory.surfaceTransition ||
      ArcRaidMapMarkerCategory.undergroundTransition => 'extract_airshaft',
      ArcRaidMapMarkerCategory.configuredHazard => 'arc_vaporizer',
      ArcRaidMapMarkerCategory.mapEvent => 'infra_antenna',
      _ => null,
    };
  }

  static String assetPathForMarker({
    String? iconKey,
    required ArcRaidMapMarkerCategory category,
  }) {
    final explicit = iconKey?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return assetPathFor(explicit);
    }
    final categoryKey = iconKeyForMarkerCategory(category);
    if (categoryKey == null) return fallbackAssetPath;
    return assetPathFor(categoryKey);
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}
