import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_item_intelligence_models.dart';

/// Verified Frozen Trail 2.0 weapon/blueprint recipes.
/// Blueprint research is an unlock action, not a per-weapon ingredient.
/// Source: arcraiders.wiki/wiki/Research_Points and /wiki/Mechanical_Components.
class ArcFrozenTrailWeaponContent {
  const ArcFrozenTrailWeaponContent._();
  static const List<ArcItemIntelligenceItem> items = <ArcItemIntelligenceItem>[
    ArcItemIntelligenceItem(
      id: 'bantam_blueprint',
      name: 'Bantam Blueprint',
      type: 'Blueprint',
      rarity: 'Rare',
      imageAsset: 'assets/arc_raiders/blueprints/bantam.webp',
      primaryStation: 'Research Station',
      stationIds: <String>['research_station'],
      stationLevel: 1,
      aliases: <String>['Bantam Blueprint'],
      recipe: <String, int>{'research_points': 3000, 'hornet_drivers': 8},
      recyclesInto: <String, int>{},
      salvagesInto: <String, int>{},
    ),
    ArcItemIntelligenceItem(
      id: 'bantam_i',
      name: 'Bantam I',
      type: 'Hand Cannon',
      rarity: 'Uncommon',
      imageAsset: 'assets/arc_raiders/blueprints/bantam.webp',
      primaryStation: 'Gunsmith',
      stationIds: <String>['weapon_bench'],
      stationLevel: 1,
      aliases: <String>['Bantam I', 'Bantam'],
      recipe: <String, int>{'simple_gun_parts': 4, 'mechanical_components': 4},
      recyclesInto: <String, int>{},
      salvagesInto: <String, int>{},
    ),
    ArcItemIntelligenceItem(
      id: 'bantam_ii',
      name: 'Bantam II',
      type: 'Hand Cannon',
      rarity: 'Uncommon',
      imageAsset: 'assets/arc_raiders/blueprints/bantam.webp',
      primaryStation: 'Gunsmith',
      stationIds: <String>['weapon_bench'],
      stationLevel: 1,
      aliases: <String>['Bantam II'],
      recipe: <String, int>{
        'bantam_i': 1,
        'mechanical_components': 3,
        'simple_gun_parts': 1,
      },
      recyclesInto: <String, int>{},
      salvagesInto: <String, int>{},
    ),
    ArcItemIntelligenceItem(
      id: 'bantam_iii',
      name: 'Bantam III',
      type: 'Hand Cannon',
      rarity: 'Uncommon',
      imageAsset: 'assets/arc_raiders/blueprints/bantam.webp',
      primaryStation: 'Gunsmith',
      stationIds: <String>['weapon_bench'],
      stationLevel: 1,
      aliases: <String>['Bantam III'],
      recipe: <String, int>{
        'bantam_ii': 1,
        'mechanical_components': 3,
        'simple_gun_parts': 1,
      },
      recyclesInto: <String, int>{},
      salvagesInto: <String, int>{},
    ),
    ArcItemIntelligenceItem(
      id: 'bantam_iv',
      name: 'Bantam IV',
      type: 'Hand Cannon',
      rarity: 'Uncommon',
      imageAsset: 'assets/arc_raiders/blueprints/bantam.webp',
      primaryStation: 'Gunsmith',
      stationIds: <String>['weapon_bench'],
      stationLevel: 1,
      aliases: <String>['Bantam IV'],
      recipe: <String, int>{
        'bantam_iii': 1,
        'mechanical_components': 4,
        'heavy_gun_parts': 1,
      },
      recyclesInto: <String, int>{},
      salvagesInto: <String, int>{},
    ),
    ArcItemIntelligenceItem(
      id: 'stiletto_blueprint',
      name: 'Stiletto Blueprint',
      type: 'Blueprint',
      rarity: 'Rare',
      imageAsset: 'assets/arc_raiders/blueprints/stiletto.webp',
      primaryStation: 'Research Station',
      stationIds: <String>['research_station'],
      stationLevel: 1,
      aliases: <String>['Stiletto Blueprint'],
      recipe: <String, int>{'research_points': 3000, 'wasp_drivers': 15},
      recyclesInto: <String, int>{},
      salvagesInto: <String, int>{},
    ),
    ArcItemIntelligenceItem(
      id: 'stiletto_i',
      name: 'Stiletto I',
      type: 'Battle Rifle',
      rarity: 'Uncommon',
      imageAsset: 'assets/arc_raiders/blueprints/stiletto.webp',
      primaryStation: 'Gunsmith',
      stationIds: <String>['weapon_bench'],
      stationLevel: 1,
      aliases: <String>['Stiletto I', 'Stiletto'],
      recipe: <String, int>{'simple_gun_parts': 4, 'mechanical_components': 4},
      recyclesInto: <String, int>{},
      salvagesInto: <String, int>{},
    ),
    ArcItemIntelligenceItem(
      id: 'stiletto_ii',
      name: 'Stiletto II',
      type: 'Battle Rifle',
      rarity: 'Uncommon',
      imageAsset: 'assets/arc_raiders/blueprints/stiletto.webp',
      primaryStation: 'Gunsmith',
      stationIds: <String>['weapon_bench'],
      stationLevel: 1,
      aliases: <String>['Stiletto II'],
      recipe: <String, int>{
        'stiletto_i': 1,
        'mechanical_components': 3,
        'simple_gun_parts': 1,
      },
      recyclesInto: <String, int>{},
      salvagesInto: <String, int>{},
    ),
    ArcItemIntelligenceItem(
      id: 'stiletto_iii',
      name: 'Stiletto III',
      type: 'Battle Rifle',
      rarity: 'Uncommon',
      imageAsset: 'assets/arc_raiders/blueprints/stiletto.webp',
      primaryStation: 'Gunsmith',
      stationIds: <String>['weapon_bench'],
      stationLevel: 1,
      aliases: <String>['Stiletto III'],
      recipe: <String, int>{
        'stiletto_ii': 1,
        'mechanical_components': 3,
        'simple_gun_parts': 1,
      },
      recyclesInto: <String, int>{},
      salvagesInto: <String, int>{},
    ),
    ArcItemIntelligenceItem(
      id: 'stiletto_iv',
      name: 'Stiletto IV',
      type: 'Battle Rifle',
      rarity: 'Uncommon',
      imageAsset: 'assets/arc_raiders/blueprints/stiletto.webp',
      primaryStation: 'Gunsmith',
      stationIds: <String>['weapon_bench'],
      stationLevel: 1,
      aliases: <String>['Stiletto IV'],
      recipe: <String, int>{
        'stiletto_iii': 1,
        'mechanical_components': 4,
        'light_gun_parts': 1,
      },
      recyclesInto: <String, int>{},
      salvagesInto: <String, int>{},
    ),
  ];

  static ArcItemIntelligenceItem currentItem(ArcItemIntelligenceItem item) {
    // Splitter is a legacy sell/recycle item. The old recycle quantities are
    // invalid for 2.0; do not fabricate an Amplified Fragments yield.
    if (item.id == 'anvil_splitter') {
      return ArcItemIntelligenceItem(
        id: item.id,
        name: item.name,
        type: item.type,
        rarity: item.rarity,
        imageAsset: item.imageAsset,
        primaryStation: item.primaryStation,
        stationIds: item.stationIds,
        stationLevel: item.stationLevel,
        aliases: item.aliases,
        recipe: item.recipe,
        recyclesInto: <String, int>{},
        salvagesInto: <String, int>{},
      );
    }
    // Official 2.0 patch: Anvil changed from Uncommon to Rare.
    if (!const <String>{
      'anvil_i',
      'anvil_ii',
      'anvil_iii',
      'anvil_iv',
    }.contains(item.id)) {
      return item;
    }
    return ArcItemIntelligenceItem(
      id: item.id,
      name: item.name,
      type: item.type,
      rarity: 'Rare',
      imageAsset: item.imageAsset,
      primaryStation: item.primaryStation,
      stationIds: item.stationIds,
      stationLevel: item.stationLevel,
      aliases: item.aliases,
      recipe: item.recipe,
      recyclesInto: item.recyclesInto,
      salvagesInto: item.salvagesInto,
    );
  }

  static String? unlockNoteFor(String id) {
    if (id.startsWith('bantam_') && id != 'bantam_blueprint') {
      return 'Learn Bantam Blueprint first. Research Station Lv.1: 3,000 Research Points + 8 Hornet Drivers. Blueprint is not consumed per weapon.';
    }
    if (id.startsWith('stiletto_') && id != 'stiletto_blueprint') {
      return 'Learn Stiletto Blueprint first. Research Station Lv.1: 3,000 Research Points + 15 Wasp Drivers. Blueprint is not consumed per weapon.';
    }
    return null;
  }
}
