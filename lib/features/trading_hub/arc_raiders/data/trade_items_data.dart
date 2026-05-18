import 'package:flutter/foundation.dart';

enum ArcTradeItemCategory {
  blueprint,
  weapon,
  ammunition,
  attachment,
  quickUse,
  key,
  valuable,
  trinket,
  craftingMaterial,
  topsideMaterial,
  recyclable,
  fineMaterial,
  arcComponent,
  bossComponent,
  eventMaterial,
  containerIntel,
}

enum ArcTradeValueTier { low, mid, high, elite }

enum ArcTradeItemRarity { common, uncommon, rare, epic, legendary, unknown }

@immutable
class ArcTradeItem {
  const ArcTradeItem({
    required this.id,
    required this.name,
    required this.category,
    required this.tradeValue,
    required this.rarity,
    required this.stackable,
    this.sourceHints = const <String>[],
    this.notes = '',
  });

  final String id;
  final String name;
  final ArcTradeItemCategory category;
  final ArcTradeValueTier tradeValue;
  final ArcTradeItemRarity rarity;
  final bool stackable;
  final List<String> sourceHints;
  final String notes;

  String get categoryLabel {
    switch (category) {
      case ArcTradeItemCategory.blueprint:
        return 'Blueprint';
      case ArcTradeItemCategory.weapon:
        return 'Weapon';
      case ArcTradeItemCategory.ammunition:
        return 'Ammunition';
      case ArcTradeItemCategory.attachment:
        return 'Attachment';
      case ArcTradeItemCategory.quickUse:
        return 'Quick Use';
      case ArcTradeItemCategory.key:
        return 'Key';
      case ArcTradeItemCategory.valuable:
        return 'Valuable';
      case ArcTradeItemCategory.trinket:
        return 'Trinket';
      case ArcTradeItemCategory.craftingMaterial:
        return 'Crafting Material';
      case ArcTradeItemCategory.topsideMaterial:
        return 'Topside Material';
      case ArcTradeItemCategory.recyclable:
        return 'Recyclable';
      case ArcTradeItemCategory.fineMaterial:
        return 'Fine Material';
      case ArcTradeItemCategory.arcComponent:
        return 'ARC Component';
      case ArcTradeItemCategory.bossComponent:
        return 'Boss Component';
      case ArcTradeItemCategory.eventMaterial:
        return 'Event Material';
      case ArcTradeItemCategory.containerIntel:
        return 'Container / Searchable';
    }
  }

  String get tradeValueLabel {
    switch (tradeValue) {
      case ArcTradeValueTier.low:
        return 'Low';
      case ArcTradeValueTier.mid:
        return 'Mid';
      case ArcTradeValueTier.high:
        return 'High';
      case ArcTradeValueTier.elite:
        return 'Elite';
    }
  }

  String get rarityLabel {
    switch (rarity) {
      case ArcTradeItemRarity.common:
        return 'Common';
      case ArcTradeItemRarity.uncommon:
        return 'Uncommon';
      case ArcTradeItemRarity.rare:
        return 'Rare';
      case ArcTradeItemRarity.epic:
        return 'Epic';
      case ArcTradeItemRarity.legendary:
        return 'Legendary';
      case ArcTradeItemRarity.unknown:
        return 'Unknown';
    }
  }
}

class ArcTradeItemsData {
  ArcTradeItemsData._();

  static const List<ArcTradeItem> items = <ArcTradeItem>[
    // Weapons / weapon value placeholders used for trade listings.
    ArcTradeItem(
      id: 'l4-weapon',
      name: 'L4 Weapon',
      category: ArcTradeItemCategory.weapon,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.epic,
      stackable: false,
      notes:
          'Use when listing a high-level weapon without choosing a specific gun.',
    ),
    ArcTradeItem(
      id: 'modded-weapon',
      name: 'Modded Weapon',
      category: ArcTradeItemCategory.weapon,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.rare,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'high-durability-weapon',
      name: 'High Durability Weapon',
      category: ArcTradeItemCategory.weapon,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.rare,
      stackable: false,
    ),

    // Ammunition.
    ArcTradeItem(
      id: 'power-clips',
      name: 'Power Clips',
      category: ArcTradeItemCategory.ammunition,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.rare,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'standard-ammo',
      name: 'Standard Ammo',
      category: ArcTradeItemCategory.ammunition,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'energy-ammo',
      name: 'Energy Ammo',
      category: ArcTradeItemCategory.ammunition,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),

    // Quick use / consumable trade options.
    ArcTradeItem(
      id: 'adrenaline-shot',
      name: 'Adrenaline Shot',
      category: ArcTradeItemCategory.quickUse,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'agave-juice',
      name: 'Agave Juice',
      category: ArcTradeItemCategory.quickUse,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'antiseptic',
      name: 'Antiseptic',
      category: ArcTradeItemCategory.quickUse,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'syringe',
      name: 'Syringe',
      category: ArcTradeItemCategory.quickUse,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'medical-kit',
      name: 'Medical Kit',
      category: ArcTradeItemCategory.quickUse,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'rusted-shut-medical-kit',
      name: 'Rusted Shut Medical Kit',
      category: ArcTradeItemCategory.quickUse,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: false,
    ),

    // Keys / access items.
    ArcTradeItem(
      id: 'locked-room-key',
      name: 'Locked Room Key',
      category: ArcTradeItemCategory.key,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.rare,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'breach-room-key',
      name: 'Breach Room Key',
      category: ArcTradeItemCategory.key,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.rare,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'high-security-key',
      name: 'High Security Key',
      category: ArcTradeItemCategory.key,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.rare,
      stackable: false,
    ),

    // Core crafting materials.
    ArcTradeItem(
      id: 'metal-parts',
      name: 'Metal Parts',
      category: ArcTradeItemCategory.craftingMaterial,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'plastic-parts',
      name: 'Plastic Parts',
      category: ArcTradeItemCategory.craftingMaterial,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'rubber-parts',
      name: 'Rubber Parts',
      category: ArcTradeItemCategory.craftingMaterial,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'mechanical-components',
      name: 'Mechanical Components',
      category: ArcTradeItemCategory.craftingMaterial,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'electrical-components',
      name: 'Electrical Components',
      category: ArcTradeItemCategory.craftingMaterial,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'advanced-mechanical-components',
      name: 'Advanced Mechanical Components',
      category: ArcTradeItemCategory.fineMaterial,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.rare,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'advanced-electrical-components',
      name: 'Advanced Electrical Components',
      category: ArcTradeItemCategory.fineMaterial,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.rare,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'wires',
      name: 'Wires',
      category: ArcTradeItemCategory.craftingMaterial,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'duct-tape',
      name: 'Duct Tape',
      category: ArcTradeItemCategory.craftingMaterial,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'steel-springs',
      name: 'Steel Springs',
      category: ArcTradeItemCategory.craftingMaterial,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'magnet',
      name: 'Magnet',
      category: ArcTradeItemCategory.craftingMaterial,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'oil',
      name: 'Oil',
      category: ArcTradeItemCategory.craftingMaterial,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'fabric',
      name: 'Fabric',
      category: ArcTradeItemCategory.craftingMaterial,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'chemicals',
      name: 'Chemicals',
      category: ArcTradeItemCategory.craftingMaterial,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),

    // Gun / attachment parts.
    ArcTradeItem(
      id: 'simple-gun-parts',
      name: 'Simple Gun Parts',
      category: ArcTradeItemCategory.fineMaterial,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'light-gun-parts',
      name: 'Light Gun Parts',
      category: ArcTradeItemCategory.fineMaterial,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'medium-gun-parts',
      name: 'Medium Gun Parts',
      category: ArcTradeItemCategory.fineMaterial,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.rare,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'heavy-gun-parts',
      name: 'Heavy Gun Parts',
      category: ArcTradeItemCategory.fineMaterial,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.rare,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'complex-gun-parts',
      name: 'Complex Gun Parts',
      category: ArcTradeItemCategory.fineMaterial,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.epic,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'mod-components',
      name: 'Mod Components',
      category: ArcTradeItemCategory.fineMaterial,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'shredder-gyro',
      name: 'Shredder Gyro',
      category: ArcTradeItemCategory.fineMaterial,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.rare,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'magnetic-accelerator',
      name: 'Magnetic Accelerator',
      category: ArcTradeItemCategory.fineMaterial,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.rare,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'damaged-heat-sink',
      name: 'Damaged Heat Sink',
      category: ArcTradeItemCategory.recyclable,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),

    // ARC / power / enemy components.
    ArcTradeItem(
      id: 'micro-arc-reactor',
      name: 'Micro ARC Reactor',
      category: ArcTradeItemCategory.arcComponent,
      tradeValue: ArcTradeValueTier.elite,
      rarity: ArcTradeItemRarity.legendary,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'arc-powercell',
      name: 'ARC Powercell',
      category: ArcTradeItemCategory.arcComponent,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.rare,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'advanced-arc-powercell',
      name: 'Advanced ARC Powercell',
      category: ArcTradeItemCategory.arcComponent,
      tradeValue: ArcTradeValueTier.elite,
      rarity: ArcTradeItemRarity.epic,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'arc-alloy',
      name: 'ARC Alloy',
      category: ArcTradeItemCategory.arcComponent,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.rare,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'arc-circuitry',
      name: 'ARC Circuitry',
      category: ArcTradeItemCategory.arcComponent,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.rare,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'arc-motion-core',
      name: 'ARC Motion Core',
      category: ArcTradeItemCategory.arcComponent,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.rare,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'queen-reactor',
      name: 'Queen Reactor',
      category: ArcTradeItemCategory.bossComponent,
      tradeValue: ArcTradeValueTier.elite,
      rarity: ArcTradeItemRarity.legendary,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'matriarch-components',
      name: 'Matriarch Components',
      category: ArcTradeItemCategory.bossComponent,
      tradeValue: ArcTradeValueTier.elite,
      rarity: ArcTradeItemRarity.legendary,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'harvester-components',
      name: 'Harvester Components',
      category: ArcTradeItemCategory.bossComponent,
      tradeValue: ArcTradeValueTier.elite,
      rarity: ArcTradeItemRarity.legendary,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'vortex-components',
      name: 'Vortex Components',
      category: ArcTradeItemCategory.bossComponent,
      tradeValue: ArcTradeValueTier.elite,
      rarity: ArcTradeItemRarity.legendary,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'turbine-compressor',
      name: 'Turbine Compressor',
      category: ArcTradeItemCategory.arcComponent,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.epic,
      stackable: false,
      sourceHints: <String>['Riven Tides', 'ARC Turbine'],
    ),
    ArcTradeItem(
      id: 'vaporizer-regulator',
      name: 'Vaporizer Regulator',
      category: ArcTradeItemCategory.arcComponent,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.rare,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'comet-igniter',
      name: 'Comet Igniter',
      category: ArcTradeItemCategory.eventMaterial,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.epic,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'tick-pod-canister',
      name: 'Tick Pod Canister',
      category: ArcTradeItemCategory.arcComponent,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'canister',
      name: 'Canister',
      category: ArcTradeItemCategory.craftingMaterial,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'exodus-module',
      name: 'Exodus Module',
      category: ArcTradeItemCategory.arcComponent,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.epic,
      stackable: false,
    ),

    // Nature / topside.
    ArcTradeItem(
      id: 'agave',
      name: 'Agave',
      category: ArcTradeItemCategory.topsideMaterial,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'apricot',
      name: 'Apricot',
      category: ArcTradeItemCategory.topsideMaterial,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'great-mullein',
      name: 'Great Mullein',
      category: ArcTradeItemCategory.topsideMaterial,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'lemon',
      name: 'Lemon',
      category: ArcTradeItemCategory.topsideMaterial,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'mushroom',
      name: 'Mushroom',
      category: ArcTradeItemCategory.topsideMaterial,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'olives',
      name: 'Olives',
      category: ArcTradeItemCategory.topsideMaterial,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'prickly-pear',
      name: 'Prickly Pear',
      category: ArcTradeItemCategory.topsideMaterial,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'roots',
      name: 'Roots',
      category: ArcTradeItemCategory.topsideMaterial,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'moss',
      name: 'Moss',
      category: ArcTradeItemCategory.topsideMaterial,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'fertiliser',
      name: 'Fertiliser',
      category: ArcTradeItemCategory.topsideMaterial,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),

    // Recyclables / utility loot.
    ArcTradeItem(
      id: 'fried-motherboard',
      name: 'Fried Motherboard',
      category: ArcTradeItemCategory.recyclable,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'crude-explosives',
      name: 'Crude Explosives',
      category: ArcTradeItemCategory.recyclable,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'explosive-compound',
      name: 'Explosive Compound',
      category: ArcTradeItemCategory.fineMaterial,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'industrial-battery',
      name: 'Industrial Battery',
      category: ArcTradeItemCategory.fineMaterial,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'laboratory-reagents',
      name: 'Laboratory Reagents',
      category: ArcTradeItemCategory.fineMaterial,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'motor',
      name: 'Motor',
      category: ArcTradeItemCategory.fineMaterial,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'pop-trigger',
      name: 'Pop Trigger',
      category: ArcTradeItemCategory.fineMaterial,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'power-cable',
      name: 'Power Cable',
      category: ArcTradeItemCategory.fineMaterial,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'power-rod',
      name: 'Power Rod',
      category: ArcTradeItemCategory.fineMaterial,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'rusted-tools',
      name: 'Rusted Tools',
      category: ArcTradeItemCategory.recyclable,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'synthesized-fuel',
      name: 'Synthesized Fuel',
      category: ArcTradeItemCategory.fineMaterial,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.rare,
      stackable: true,
    ),

    // Trinkets / valuables.
    ArcTradeItem(
      id: 'red-coral-jewelry',
      name: 'Red Coral Jewelry',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.epic,
      stackable: false,
      sourceHints: <String>['Riven Tides'],
    ),
    ArcTradeItem(
      id: 'leviathans-crown-ship-model',
      name: 'Leviathan's Crown Ship Model',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.elite,
      rarity: ArcTradeItemRarity.legendary,
      stackable: false,
      sourceHints: <String>['Riven Tides', 'Beachcombing'],
    ),
    ArcTradeItem(
      id: 'twilight-compass-ship-model',
      name: 'Twilight Compass Ship Model',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.elite,
      rarity: ArcTradeItemRarity.legendary,
      stackable: false,
      sourceHints: <String>['Riven Tides', 'Beachcombing'],
    ),
    ArcTradeItem(
      id: 'velocity-ship-model',
      name: 'Velocity Ship Model',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.epic,
      stackable: false,
      sourceHints: <String>['Riven Tides', 'Beachcombing'],
    ),
    ArcTradeItem(
      id: 'sorena-dorata-ship-model',
      name: 'Sorena Dorata Ship Model',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.epic,
      stackable: false,
      sourceHints: <String>['Riven Tides', 'Beachcombing'],
    ),
    ArcTradeItem(
      id: 'wind-sprite-ship-model',
      name: 'Wind Sprite Ship Model',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.epic,
      stackable: false,
      sourceHints: <String>['Riven Tides', 'Beachcombing'],
    ),
    ArcTradeItem(
      id: 'acoustic-guitar',
      name: 'Acoustic Guitar',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'alien-duck',
      name: 'Alien Duck',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.rare,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'rubber-duck',
      name: 'Rubber Duck',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'fine-wristwatch',
      name: 'Fine Wristwatch',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.rare,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'music-box',
      name: 'Music Box',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.rare,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'statuette',
      name: 'Statuette',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.rare,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'vase',
      name: 'Vase',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.rare,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'water-filter',
      name: 'Water Filter',
      category: ArcTradeItemCategory.valuable,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),
    ArcTradeItem(
      id: 'chip-pods',
      name: 'Chip Pods',
      category: ArcTradeItemCategory.valuable,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
    ),

    // Quest collection items added for tracker/trading surplus. Fixed-location special quest items are intentionally excluded.
    ArcTradeItem(
      id: 'battery',
      name: 'Battery',
      category: ArcTradeItemCategory.recyclable,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: true,
      sourceHints: <String>['Electrical', 'Technological'],
    ),
    ArcTradeItem(
      id: 'great-mullein',
      name: 'Great Mullein',
      category: ArcTradeItemCategory.topsideMaterial,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
      sourceHints: <String>['Submerged areas', 'Swampy areas'],
    ),
    ArcTradeItem(
      id: 'faded-photograph',
      name: 'Faded Photograph',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: false,
      sourceHints: <String>['Residential'],
    ),
    ArcTradeItem(
      id: 'camera-lens',
      name: 'Camera Lens',
      category: ArcTradeItemCategory.recyclable,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: false,
      sourceHints: <String>['Security'],
    ),
    ArcTradeItem(
      id: 'film-reel',
      name: 'Film Reel',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: false,
      sourceHints: <String>['Residential', 'Old World'],
    ),
    ArcTradeItem(
      id: 'recorder',
      name: 'Recorder',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: false,
      sourceHints: <String>['Residential'],
    ),
    ArcTradeItem(
      id: 'empty-wine-bottle',
      name: 'Empty Wine Bottle',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: false,
      sourceHints: <String>['Residential', 'Commercial'],
    ),
    ArcTradeItem(
      id: 'light-impact-grenade',
      name: 'Light Impact Grenade',
      category: ArcTradeItemCategory.quickUse,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
      sourceHints: <String>['Weapon Caches'],
    ),
    ArcTradeItem(
      id: 'sensors',
      name: 'Sensors',
      category: ArcTradeItemCategory.recyclable,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
      sourceHints: <String>['Security', 'Technological'],
    ),
    ArcTradeItem(
      id: 'tick-pod',
      name: 'Tick Pod',
      category: ArcTradeItemCategory.arcComponent,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
      sourceHints: <String>['Tick ARC'],
    ),
    ArcTradeItem(
      id: 'wasp-driver',
      name: 'Wasp Driver',
      category: ArcTradeItemCategory.arcComponent,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
      sourceHints: <String>['Wasp ARC'],
    ),
    ArcTradeItem(
      id: 'hornet-driver',
      name: 'Hornet Driver',
      category: ArcTradeItemCategory.arcComponent,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
      sourceHints: <String>['Hornet ARC'],
    ),
    ArcTradeItem(
      id: 'snitch-scanner',
      name: 'Snitch Scanner',
      category: ArcTradeItemCategory.arcComponent,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
      sourceHints: <String>['Snitch ARC'],
    ),
    ArcTradeItem(
      id: 'bicycle-pump',
      name: 'Bicycle Pump',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: false,
      sourceHints: <String>['Residential'],
    ),
    ArcTradeItem(
      id: 'deflated-football',
      name: 'Deflated Football',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: false,
      sourceHints: <String>['Residential'],
    ),
    ArcTradeItem(
      id: 'portable-tv',
      name: 'Portable TV',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: false,
      sourceHints: <String>['Residential', 'Old World'],
    ),
    ArcTradeItem(
      id: 'stack-of-movie-tapes',
      name: 'Stack Of Movie Tapes',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: false,
      sourceHints: <String>['Residential', 'Old World'],
    ),
    ArcTradeItem(
      id: 'espresso-machine-parts',
      name: 'Espresso Machine Parts',
      category: ArcTradeItemCategory.recyclable,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'coffee-pot',
      name: 'Coffee Pot',
      category: ArcTradeItemCategory.trinket,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.common,
      stackable: false,
      sourceHints: <String>['Residential', 'Commercial'],
    ),
    ArcTradeItem(
      id: 'firefly-burner',
      name: 'Firefly Burner',
      category: ArcTradeItemCategory.arcComponent,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.uncommon,
      stackable: true,
      sourceHints: <String>['Firefly ARC'],
    ),

    // Containers/searchables for reporting and trade intel.
    ArcTradeItem(
      id: 'cool-box-on-wheels',
      name: 'Cool Box on Wheels',
      category: ArcTradeItemCategory.containerIntel,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.unknown,
      stackable: false,
      sourceHints: <String>['Riven Tides'],
    ),
    ArcTradeItem(
      id: 'beachcombing-cache',
      name: 'Beachcombing Cache',
      category: ArcTradeItemCategory.containerIntel,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.unknown,
      stackable: false,
      sourceHints: <String>['Riven Tides', 'Beachcombing'],
    ),
    ArcTradeItem(
      id: 'suitcase',
      name: 'Suitcase',
      category: ArcTradeItemCategory.containerIntel,
      tradeValue: ArcTradeValueTier.low,
      rarity: ArcTradeItemRarity.unknown,
      stackable: false,
      sourceHints: <String>['Spaceport', 'Arrivals / Departures'],
    ),
    ArcTradeItem(
      id: 'weapon-case',
      name: 'Weapon Case',
      category: ArcTradeItemCategory.containerIntel,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.unknown,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'raider-cache',
      name: 'Raider Cache',
      category: ArcTradeItemCategory.containerIntel,
      tradeValue: ArcTradeValueTier.mid,
      rarity: ArcTradeItemRarity.unknown,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'locked-room',
      name: 'Locked Room',
      category: ArcTradeItemCategory.containerIntel,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.unknown,
      stackable: false,
    ),
    ArcTradeItem(
      id: 'breach-room',
      name: 'Breach Room',
      category: ArcTradeItemCategory.containerIntel,
      tradeValue: ArcTradeValueTier.high,
      rarity: ArcTradeItemRarity.unknown,
      stackable: false,
    ),
  ];

  static List<ArcTradeItem> byCategory(ArcTradeItemCategory category) {
    return items
        .where((item) => item.category == category)
        .toList(growable: false);
  }

  static ArcTradeItem? byId(String id) {
    final normalized = id.trim().toLowerCase();
    for (final item in items) {
      if (item.id == normalized) return item;
    }
    return null;
  }

  static List<ArcTradeItem> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return items;
    return items
        .where((item) {
          return item.name.toLowerCase().contains(normalized) ||
              item.id.contains(normalized) ||
              item.categoryLabel.toLowerCase().contains(normalized) ||
              item.sourceHints.any(
                (hint) => hint.toLowerCase().contains(normalized),
              );
        })
        .toList(growable: false);
  }

  static List<String> get itemNames =>
      items.map((item) => item.name).toList(growable: false)..sort();

  static List<String> get tradeableItemNames =>
      items
          .where((item) => item.category != ArcTradeItemCategory.containerIntel)
          .map((item) => item.name)
          .toList(growable: false)
        ..sort();
}

