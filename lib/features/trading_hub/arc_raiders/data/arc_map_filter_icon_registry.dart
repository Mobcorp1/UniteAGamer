import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_taxonomy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

class ArcMapFilterIconRegistry {
  const ArcMapFilterIconRegistry._();

  static const String assetDirectory = 'assets/arc_raiders/map_filter_icons';
  static const String fallbackIconKey = 'map_filter_unknown';
  static const String communityReportRatIconKey = 'community_report_rat';
  static const String fallbackAssetPath = '';

  static const Set<String> uagCommunityIconKeys = {communityReportRatIconKey};

  // New in-game raster marker artwork. Taxonomy keys stay stable so existing
  // Firestore/admin marker data does not need migration.
  static const Map<String, String> _rasterAssets = {
    'extract_standard': 'extraction_point.webp',
    'extract_raider_hatch': 'raider_hatch.webp',
    'infra_field_depot': 'field_depot.webp',
    'infra_zipline': 'zipline.webp',
    'loot_weapon_case': 'weapon_case.webp',
    'loot_security_locker': 'security_locker.webp',
    'loot_raider_cache': 'raider_cache.webp',
    'loot_field_crate': 'field_crate.webp',
    'loot_ammo_case': 'ammo_case.webp',
    'loot_medical_container': 'medical_bag.webp',
    'access_locked_room': 'locked_room.webp',
    'access_breachable_door': 'breachable_container.webp',
    'arc_assessor': 'arc_assessor.webp',
    'arc_baron_husk': 'arc_baron_husk.webp',
    'arc_bastion': 'arc_bastion.webp',
    'arc_bombardier': 'arc_bombardier.webp',
    'arc_comet': 'arc_comet.webp',
    'arc_courier': 'arc_courier.webp',
    'arc_fireball': 'arc_fireball.webp',
    'arc_firefly': 'arc_firefly.webp',
    'arc_harvester': 'arc_harvester.webp',
    'arc_hornet': 'arc_hornet.webp',
    'arc_leaper': 'arc_leaper.webp',
    'arc_matriarch': 'arc_matriarch.webp',
    'arc_pop': 'arc_pop.webp',
    'arc_probe': 'arc_probe.webp',
    'arc_queen': 'arc_queen.webp',
    'arc_rocketeer': 'arc_rocketeer.webp',
    'arc_sentinel': 'arc_sentinel.webp',
    'arc_shredder': 'arc_shredder.webp',
    'arc_snitch': 'arc_snitch.webp',
    'arc_spotter': 'arc_spotter.webp',
    'arc_surveyor': 'arc_surveyor.webp',
    'arc_tick': 'arc_tick.webp',
    'arc_turbine': 'arc_turbine.webp',
    'arc_turret': 'arc_turret.webp',
    'arc_vaporizer': 'arc_vaporizer.webp',
    'arc_wasp': 'arc_wasp.webp',
  };

  static Set<String> get canonicalIconKeys => {
    for (final entry in ArcMapFilterTaxonomy.all) entry.iconKey,
  };

  static Set<String> get supportedIconKeys => {
    ...canonicalIconKeys,
    ...uagCommunityIconKeys,
  };

  static Set<String> get rasterIconKeys => _rasterAssets.keys.toSet();

  static List<String> get canonicalAssetPaths => [
    for (final key in canonicalIconKeys)
      if (tryAssetPathFor(key) case final path?) path,
  ];

  static List<String> get uagCommunityAssetPaths => [
    for (final key in uagCommunityIconKeys)
      if (tryAssetPathFor(key) case final path?) path,
  ];

  static String? tryAssetPathFor(String iconKey) {
    final normalized = _normalize(iconKey);
    final filename = _rasterAssets[normalized];
    return filename == null ? null : '$assetDirectory/$filename';
  }

  static String assetPathFor(String iconKey) {
    return tryAssetPathFor(iconKey) ?? fallbackAssetPath;
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

  static String? tryAssetPathForMarker({
    String? iconKey,
    required ArcRaidMapMarkerCategory category,
  }) {
    final explicit = iconKey?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      final explicitPath = tryAssetPathFor(explicit);
      if (explicitPath != null) return explicitPath;
    }
    final categoryKey = iconKeyForMarkerCategory(category);
    return categoryKey == null ? null : tryAssetPathFor(categoryKey);
  }

  static String assetPathForMarker({
    String? iconKey,
    required ArcRaidMapMarkerCategory category,
  }) {
    return tryAssetPathForMarker(iconKey: iconKey, category: category) ??
        fallbackAssetPath;
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}
