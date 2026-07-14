import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';

class ArcLoadoutSeedData {
  const ArcLoadoutSeedData._();

  static ArcLoadoutCategory recommendedForPlayStyle(ArcPlayerPlayStyle style) {
    switch (style) {
      case ArcPlayerPlayStyle.pvp:
        return ArcLoadoutCategory.pvp;
      case ArcPlayerPlayStyle.pve:
      case ArcPlayerPlayStyle.blueprintHunter:
      case ArcPlayerPlayStyle.lootRunner:
      case ArcPlayerPlayStyle.squadSupport:
      case ArcPlayerPlayStyle.soloSurvivor:
        return ArcLoadoutCategory.pve;
      case ArcPlayerPlayStyle.balanced:
      case ArcPlayerPlayStyle.trader:
        return ArcLoadoutCategory.balanced;
    }
  }

  static List<ArcSavedLoadoutSeed> recommendedLoadouts(
    ArcPlayerPlayStyle style,
  ) {
    final category = recommendedForPlayStyle(style);
    final matches = starterLoadouts
        .where((loadout) => loadout.category == category)
        .toList(growable: false);

    if (matches.isNotEmpty) return matches;

    return starterLoadouts
        .where((loadout) => loadout.category == ArcLoadoutCategory.balanced)
        .toList(growable: false);
  }

  static const List<ArcLoadoutWeaponSpec> weapons = [
    ArcLoadoutWeaponSpec(
      name: 'Anvil',
      category: 'Hand Cannon',
      role: 'High-impact raider stopping power',
      slots: ['Muzzle Mod', 'Tech Mod'],
      blueprintBased: true,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Aphelion',
      category: 'Weapon',
      role: 'Attachment layout verified in-game',
      slots: ['Underbarrel Mod', 'Stock Mod'],
    ),
    ArcLoadoutWeaponSpec(
      name: 'Arpeggio',
      category: 'Assault Rifle',
      role: 'Flexible medium-range rifle platform',
      slots: [
        'Muzzle Mod',
        'Underbarrel Mod',
        'Medium Magazine Mod',
        'Stock Mod',
      ],
      blueprintBased: true,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Bettina',
      category: 'Weapon',
      role: 'Attachment layout verified in-game',
      slots: ['Muzzle Mod', 'Underbarrel Mod', 'Stock Mod'],
    ),
    ArcLoadoutWeaponSpec(
      name: 'Bobcat',
      category: 'SMG',
      role: 'Light weapon sustain and mobility',
      slots: [
        'Muzzle Mod',
        'Underbarrel Mod',
        'Light Magazine Mod',
        'Stock Mod',
      ],
      blueprintBased: true,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Burletta',
      category: 'Pistol',
      role: 'Light backup sidearm',
      slots: ['Muzzle Mod', 'Light Magazine Mod'],
    ),
    ArcLoadoutWeaponSpec(
      name: 'Canto',
      category: 'Weapon',
      role: 'Attachment layout verified in-game',
      slots: [
        'Muzzle Mod',
        'Underbarrel Mod',
        'Medium Magazine Mod',
        'Stock Mod',
      ],
    ),
    ArcLoadoutWeaponSpec(
      name: 'Equalizer',
      category: 'Weapon',
      role: 'No attachment slots',
      slots: [],
    ),
    ArcLoadoutWeaponSpec(
      name: 'Ferro',
      category: 'Battle Rifle',
      role: 'Heavy precision damage',
      slots: ['Muzzle Mod', 'Underbarrel Mod', 'Stock Mod'],
      craftable: true,
      gunsmithLevel: 2,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Hairpin',
      category: 'Pistol',
      role: 'Compact sidearm',
      slots: ['Light Magazine Mod'],
    ),
    ArcLoadoutWeaponSpec(
      name: 'Hullcracker',
      category: 'Weapon',
      role: 'Attachment layout verified in-game',
      slots: ['Underbarrel Mod', 'Stock Mod'],
    ),
    ArcLoadoutWeaponSpec(
      name: 'Il Toro',
      category: 'Shotgun',
      role: 'Close-range burst threat',
      slots: [
        'Shotgun Muzzle Mod',
        'Underbarrel Mod',
        'Shotgun Magazine Mod',
        'Stock Mod',
      ],
      blueprintBased: true,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Jupiter',
      category: 'Weapon',
      role: 'No attachment slots',
      slots: [],
    ),
    ArcLoadoutWeaponSpec(
      name: 'Kettle',
      category: 'Assault Rifle',
      role: 'Starter-friendly semi-auto control',
      slots: [
        'Muzzle Mod',
        'Underbarrel Mod',
        'Light Magazine Mod',
        'Stock Mod',
      ],
      craftable: true,
      gunsmithLevel: 1,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Osprey',
      category: 'Sniper Rifle',
      role: 'Long-range precision',
      slots: [
        'Muzzle Mod',
        'Underbarrel Mod',
        'Medium Magazine Mod',
        'Stock Mod',
      ],
      blueprintBased: true,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Rascal',
      category: 'Weapon',
      role: 'No attachment slots',
      slots: [],
    ),
    ArcLoadoutWeaponSpec(
      name: 'Rattler',
      category: 'Assault Rifle',
      role: 'Reliable automatic mid-range control',
      slots: ['Stock Mod', 'Converter'],
      craftable: true,
      gunsmithLevel: 2,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Renegade',
      category: 'Battle Rifle',
      role: 'Heavy sustained raider pressure',
      slots: ['Muzzle Mod', 'Underbarrel Mod', 'Stock Mod'],
      blueprintBased: true,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Stitcher',
      category: 'SMG',
      role: 'Close-range ARC and raider pressure',
      slots: ['Muzzle Mod', 'Underbarrel Mod', 'Magazine Mod', 'Stock Mod'],
      craftable: true,
      gunsmithLevel: 2,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Tempest',
      category: 'Assault Rifle',
      role: 'Aggressive automatic PvP pressure',
      slots: ['Muzzle Mod', 'Underbarrel Mod', 'Medium Magazine Mod'],
      blueprintBased: true,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Torrente',
      category: 'LMG',
      role: 'Sustained squad suppression',
      slots: ['Muzzle Mod', 'Medium Magazine Mod', 'Stock Mod'],
      blueprintBased: true,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Venator',
      category: 'Pistol',
      role: 'Medium sidearm pressure',
      slots: ['Underbarrel Mod', 'Medium Magazine Mod'],
      blueprintBased: true,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Vulcano',
      category: 'Shotgun',
      role: 'Close-range control and burst pressure',
      slots: [
        'Shotgun Muzzle Mod',
        'Underbarrel Mod',
        'Shotgun Magazine Mod',
        'Stock Mod',
      ],
      blueprintBased: true,
    ),
  ];

  static const List<ArcLoadoutOption> augments = [
    ArcLoadoutOption(
      name: 'Survivor',
      type: ArcLoadoutSlotType.augment,
      description: 'Balanced survival-focused augment for PvP and PvE runs.',
    ),
    ArcLoadoutOption(
      name: 'Safekeeper',
      type: ArcLoadoutSlotType.augment,
      description: 'Safer progression-focused augment for controlled runs.',
    ),
    ArcLoadoutOption(
      name: 'Combat Augment',
      type: ArcLoadoutSlotType.augment,
      description: 'Aggressive combat-first setup.',
    ),
    ArcLoadoutOption(
      name: 'Mobility Augment',
      type: ArcLoadoutSlotType.augment,
      description: 'Movement-led build option.',
    ),
    ArcLoadoutOption(
      name: 'Utility Augment',
      type: ArcLoadoutSlotType.augment,
      description: 'Utility-heavy squad support option.',
    ),
  ];

  static const List<ArcLoadoutOption> equipment = [
    ArcLoadoutOption(
      name: 'Shield Level 2',
      type: ArcLoadoutSlotType.equipment,
      description: 'Core balanced protection target.',
      craftable: true,
    ),
    ArcLoadoutOption(
      name: 'Pulse Mine',
      type: ArcLoadoutSlotType.equipment,
      description: 'Area control and defensive warning utility.',
      blueprintBased: true,
    ),
    ArcLoadoutOption(
      name: 'Snap Hook',
      type: ArcLoadoutSlotType.equipment,
      description: 'Movement and extraction repositioning tool.',
    ),
    ArcLoadoutOption(
      name: 'Wolfpack',
      type: ArcLoadoutSlotType.equipment,
      description: 'Squad pressure and tactical utility.',
      blueprintBased: true,
    ),
  ];

  static const List<ArcLoadoutOption> consumables = [
    ArcLoadoutOption(
      name: 'Vita Shot',
      type: ArcLoadoutSlotType.consumables,
      description: 'Fast sustain option during pressure.',
    ),
    ArcLoadoutOption(
      name: 'Vita Spray',
      type: ArcLoadoutSlotType.consumables,
      description: 'Recovery option for longer runs.',
    ),
    ArcLoadoutOption(
      name: 'Lure Grenade',
      type: ArcLoadoutSlotType.consumables,
      description: 'ARC manipulation and repositioning utility.',
    ),
    ArcLoadoutOption(
      name: 'Triggernade',
      type: ArcLoadoutSlotType.consumables,
      description: 'Flexible offensive utility.',
      blueprintBased: true,
    ),
  ];

  static const List<ArcLoadoutAttachmentSpec> attachments = [
    ArcLoadoutAttachmentSpec(
      name: 'Compensator I',
      slotType: ArcAttachmentSlotType.muzzle,
      benchLevel: 1,
      materials: ['6x Metal Parts', '1x Wires'],
      effect: '25% reduced per-shot dispersion',
      compatibleWeapons: [
        'Ferro',
        'Torrente',
        'Tempest',
        'Arpeggio',
        'Bettina',
      ],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Muzzle Brake I',
      slotType: ArcAttachmentSlotType.muzzle,
      benchLevel: 1,
      materials: ['6x Metal Parts', '1x Wires'],
      effect: '15% reduced horizontal recoil • 15% reduced vertical recoil',
      compatibleWeapons: ['Arpeggio', 'Ferro'],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Shotgun Choke I',
      slotType: ArcAttachmentSlotType.shotgunMuzzle,
      benchLevel: 1,
      materials: ['6x Metal Parts', '1x Wires'],
      effect: '20% reduced base dispersion',
      compatibleWeapons: ['Vulcano', 'Il Toro'],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Angled Grip I',
      slotType: ArcAttachmentSlotType.underbarrel,
      benchLevel: 1,
      materials: ['6x Plastic Parts', '1x Duct Tape'],
      effect: '20% reduced horizontal recoil',
      compatibleWeapons: ['Vulcano', 'Osprey', 'Ferro', 'Venator', 'Il Toro'],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Vertical Grip I',
      slotType: ArcAttachmentSlotType.underbarrel,
      benchLevel: 1,
      materials: ['6x Plastic Parts', '1x Duct Tape'],
      effect: '20% reduced vertical recoil',
      compatibleWeapons: ['Vulcano', 'Ferro', 'Bobcat', 'Il Toro', 'Tempest'],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Extended Light Mag I',
      slotType: ArcAttachmentSlotType.lightMagazine,
      benchLevel: 1,
      materials: ['6x Plastic Parts', '1x Steel Spring'],
      effect: '+5 magazine size',
      compatibleWeapons: ['Bobcat'],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Extended Medium Mag I',
      slotType: ArcAttachmentSlotType.mediumMagazine,
      benchLevel: 1,
      materials: ['6x Plastic Parts', '1x Steel Spring'],
      effect: '+4 magazine size',
      compatibleWeapons: [
        'Arpeggio',
        'Venator',
        'Torrente',
        'Osprey',
        'Tempest',
      ],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Extended Shotgun Mag I',
      slotType: ArcAttachmentSlotType.shotgunMagazine,
      benchLevel: 1,
      materials: ['6x Plastic Parts', '1x Steel Spring'],
      effect: '+2 magazine size',
      compatibleWeapons: ['Il Toro', 'Vulcano'],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Stable Stock I',
      slotType: ArcAttachmentSlotType.stock,
      benchLevel: 1,
      materials: ['7x Rubber Parts', '1x Duct Tape'],
      effect: '40% reduced recoil and dispersion recovery time',
      compatibleWeapons: [
        'Vulcano',
        'Ferro',
        'Bobcat',
        'Il Toro',
        'Torrente',
        'Arpeggio',
        'Rattler',
      ],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Compensator II',
      slotType: ArcAttachmentSlotType.muzzle,
      benchLevel: 2,
      materials: ['8x Metal Parts', '1x Wires'],
      effect: '35% reduced per-shot dispersion',
      compatibleWeapons: [
        'Arpeggio',
        'Renegade',
        'Bobcat',
        'Torrente',
        'Burletta',
        'Anvil',
        'Osprey',
        'Ferro',
      ],
      imageAssetPath: 'assets/arc_raiders/blueprints/compensator-ii.webp',
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Muzzle Brake II',
      slotType: ArcAttachmentSlotType.muzzle,
      benchLevel: 2,
      materials: ['1x Mechanical Components', '1x Duct Tape'],
      effect: '20% reduced horizontal recoil • 20% reduced vertical recoil',
      compatibleWeapons: ['Arpeggio', 'Ferro', 'Tempest', 'Anvil', 'Osprey'],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Shotgun Choke II',
      slotType: ArcAttachmentSlotType.shotgunMuzzle,
      benchLevel: 2,
      materials: ['1x Mechanical Components', '1x Duct Tape'],
      effect: '30% reduced base dispersion',
      compatibleWeapons: ['Vulcano', 'Il Toro'],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Silencer I',
      slotType: ArcAttachmentSlotType.muzzle,
      benchLevel: 2,
      materials: ['1x Mechanical Components', '1x Wires'],
      effect: '20% reduced noise',
      compatibleWeapons: [
        'Bobcat',
        'Osprey',
        'Torrente',
        'Tempest',
        'Arpeggio',
        'Anvil',
        'Burletta',
        'Renegade',
      ],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Angled Grip II',
      slotType: ArcAttachmentSlotType.underbarrel,
      benchLevel: 2,
      materials: ['6x Plastic Parts', '1x Duct Tape'],
      effect: '30% reduced horizontal recoil',
      compatibleWeapons: ['Vulcano', 'Tempest', 'Osprey', 'Bobcat'],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Vertical Grip II',
      slotType: ArcAttachmentSlotType.underbarrel,
      benchLevel: 2,
      materials: ['6x Plastic Parts', '1x Duct Tape'],
      effect: '30% reduced vertical recoil',
      compatibleWeapons: ['Arpeggio', 'Kettle', 'Ferro', 'Stitcher', 'Venator'],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Extended Light Mag II',
      slotType: ArcAttachmentSlotType.lightMagazine,
      benchLevel: 2,
      materials: ['1x Mechanical Components', '1x Steel Spring'],
      effect: '+10 magazine size',
      compatibleWeapons: ['Burletta', 'Bobcat'],
      imageAssetPath:
          'assets/arc_raiders/blueprints/extended-light-mag-ii.webp',
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Extended Medium Mag II',
      slotType: ArcAttachmentSlotType.mediumMagazine,
      benchLevel: 2,
      materials: ['6x Plastic Parts', '1x Steel Spring'],
      effect: '+8 magazine size',
      compatibleWeapons: [
        'Arpeggio',
        'Venator',
        'Torrente',
        'Osprey',
        'Tempest',
      ],
      imageAssetPath:
          'assets/arc_raiders/blueprints/extended-medium-mag-ii.webp',
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Extended Shotgun Mag II',
      slotType: ArcAttachmentSlotType.shotgunMagazine,
      benchLevel: 2,
      materials: ['1x Mechanical Components', '1x Steel Spring'],
      effect: '+4 magazine size',
      compatibleWeapons: ['Il Toro', 'Vulcano'],
      imageAssetPath:
          'assets/arc_raiders/blueprints/extended-shotgun-mag-ii.webp',
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Stable Stock II',
      slotType: ArcAttachmentSlotType.stock,
      benchLevel: 2,
      materials: ['1x Mechanical Components', '1x Duct Tape'],
      effect: '60% reduced recoil and dispersion recovery time',
      compatibleWeapons: ['Renegade', 'Vulcano', 'Torrente'],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Compensator III',
      slotType: ArcAttachmentSlotType.muzzle,
      benchLevel: 3,
      materials: ['1x Mod Components', '6x Wires'],
      effect:
          '50% reduced per-shot dispersion • 20% increased durability burn time',
      compatibleWeapons: [
        'Arpeggio',
        'Renegade',
        'Anvil',
        'Burletta',
        'Osprey',
      ],
      imageAssetPath: 'assets/arc_raiders/blueprints/compensator-iii.webp',
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Muzzle Brake III',
      slotType: ArcAttachmentSlotType.muzzle,
      benchLevel: 3,
      materials: ['1x Mod Components', '6x Wires'],
      effect:
          '25% reduced horizontal recoil • 25% reduced vertical recoil • 20% increased durability burn time',
      compatibleWeapons: [
        'Arpeggio',
        'Anvil',
        'Ferro',
        'Bobcat',
        'Torrente',
        'Tempest',
        'Osprey',
        'Renegade',
      ],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Shotgun Choke III',
      slotType: ArcAttachmentSlotType.shotgunMuzzle,
      benchLevel: 3,
      materials: ['1x Mod Components', '9x Wires'],
      effect:
          '40% reduced base dispersion • 20% increased durability burn time',
      compatibleWeapons: ['Vulcano', 'Il Toro'],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Silencer II',
      slotType: ArcAttachmentSlotType.muzzle,
      benchLevel: 3,
      materials: ['1x Mod Components', '9x Wires'],
      effect: '40% reduced noise',
      compatibleWeapons: [
        'Bobcat',
        'Osprey',
        'Torrente',
        'Tempest',
        'Arpeggio',
        'Anvil',
        'Burletta',
        'Renegade',
      ],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Silencer III',
      slotType: ArcAttachmentSlotType.muzzle,
      benchLevel: 3,
      materials: ['3x Mod Components', '15x Wires'],
      effect: '60% reduced noise • 20% increased durability burn rate',
      compatibleWeapons: [
        'Bobcat',
        'Osprey',
        'Torrente',
        'Tempest',
        'Arpeggio',
        'Renegade',
      ],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Shotgun Silencer',
      slotType: ArcAttachmentSlotType.shotgunMuzzle,
      benchLevel: 3,
      materials: ['1x Mod Components', '9x Wires'],
      effect: '50% reduced noise',
      compatibleWeapons: ['Il Toro', 'Vulcano'],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Extended Barrel',
      slotType: ArcAttachmentSlotType.barrel,
      benchLevel: 3,
      materials: ['6x Metal Parts', '1x Steel Spring'],
      effect: '25% increased bullet velocity • 15% increased vertical recoil',
      compatibleWeapons: [],
      imageAssetPath: 'assets/arc_raiders/blueprints/extended-barrel.webp',
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Angled Grip III',
      slotType: ArcAttachmentSlotType.underbarrel,
      benchLevel: 3,
      materials: ['1x Mod Components', '6x Duct Tape'],
      effect: '40% reduced horizontal recoil • 30% reduced ADS speed',
      compatibleWeapons: ['Vulcano', 'Osprey', 'Ferro', 'Venator', 'Il Toro'],
      imageAssetPath: 'assets/arc_raiders/blueprints/angled-grip-iii.webp',
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Vertical Grip III',
      slotType: ArcAttachmentSlotType.underbarrel,
      benchLevel: 3,
      materials: ['1x Mod Components', '6x Duct Tape'],
      effect: '40% reduced vertical recoil • 30% reduced ADS speed',
      compatibleWeapons: ['Arpeggio', 'Il Toro', 'Vulcano'],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Horizontal Grip',
      slotType: ArcAttachmentSlotType.underbarrel,
      benchLevel: 3,
      materials: ['1x Mod Components', '6x Duct Tape'],
      effect:
          '30% reduced horizontal recoil • 30% reduced vertical recoil • 30% reduced ADS speed',
      compatibleWeapons: ['Tempest', 'Vulcano', 'Osprey'],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Extended Light Mag III',
      slotType: ArcAttachmentSlotType.lightMagazine,
      benchLevel: 3,
      materials: ['1x Mod Components', '6x Steel Spring'],
      effect: '+15 magazine size',
      compatibleWeapons: ['Burletta', 'Bobcat'],
      imageAssetPath:
          'assets/arc_raiders/blueprints/extended-light-mag-iii.webp',
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Extended Medium Mag III',
      slotType: ArcAttachmentSlotType.mediumMagazine,
      benchLevel: 3,
      materials: ['1x Mod Components', '6x Steel Spring'],
      effect: '+12 magazine size',
      compatibleWeapons: [
        'Arpeggio',
        'Venator',
        'Torrente',
        'Osprey',
        'Tempest',
      ],
      imageAssetPath:
          'assets/arc_raiders/blueprints/extended-medium-mag-iii.webp',
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Extended Shotgun Mag III',
      slotType: ArcAttachmentSlotType.shotgunMagazine,
      benchLevel: 3,
      materials: ['1x Mod Components', '6x Steel Spring'],
      effect: '+6 magazine size',
      compatibleWeapons: ['Il Toro', 'Vulcano'],
      imageAssetPath:
          'assets/arc_raiders/blueprints/extended-shotgun-mag-iii.webp',
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Stable Stock III',
      slotType: ArcAttachmentSlotType.stock,
      benchLevel: 3,
      materials: ['1x Mod Components', '6x Duct Tape'],
      effect:
          '50% reduced recoil and dispersion recovery time • 20% increased equip/unequip time',
      compatibleWeapons: [
        'Bobcat',
        'Vulcano',
        'Osprey',
        'Il Toro',
        'Ferro',
        'Renegade',
      ],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Lightweight Stock',
      slotType: ArcAttachmentSlotType.stock,
      benchLevel: 3,
      materials: ['1x Mod Components', '6x Duct Tape'],
      effect:
          '50% increased vertical recoil control • 30% reduced equip/unequip time • 200% increased ADS speed',
      compatibleWeapons: ['Renegade', 'Vulcano'],
      imageAssetPath: 'assets/arc_raiders/blueprints/lightweight-stock.webp',
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Padded Stock',
      slotType: ArcAttachmentSlotType.stock,
      benchLevel: 3,
      materials: ['1x Mod Components', '6x Duct Tape'],
      effect:
          '30% reduced horizontal recoil • 30% reduced vertical recoil • 30% reduced per-shot dispersion',
      compatibleWeapons: [
        'Rattler',
        'Il Toro',
        'Osprey',
        'Stitcher',
        'Ferro',
        'Arpeggio',
        'Renegade',
        'Vulcano',
      ],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Kinetic Converter',
      slotType: ArcAttachmentSlotType.converter,
      benchLevel: 0,
      materials: ['TBA'],
      effect:
          '15% increased fire rate • 20% increased horizontal recoil • 20% increased vertical recoil',
      compatibleWeapons: ['Rattler'],
    ),
    ArcLoadoutAttachmentSpec(
      name: 'Anvil Splitter',
      slotType: ArcAttachmentSlotType.special,
      benchLevel: 0,
      materials: ['TBA'],
      effect: '+3 projectiles per shot • 60% reduced projectile damage',
      compatibleWeapons: ['Anvil'],
    ),
  ];

  static const List<ArcSavedLoadoutSeed> starterLoadouts = [
    ArcSavedLoadoutSeed(
      name: 'Balanced Raider / ARC',
      category: ArcLoadoutCategory.balanced,
      description:
          'Survivor augment, level 2 shield, Anvil-style burst and Stitcher-style pressure.',
      augment: 'Survivor',
      primaryWeapon: 'Anvil',
      secondaryWeapon: 'Stitcher',
      equipment: ['Shield Level 2', 'Snap Hook'],
      consumables: ['Vita Shot', 'Lure Grenade'],
    ),
    ArcSavedLoadoutSeed(
      name: 'PvP Pressure',
      category: ArcLoadoutCategory.pvp,
      description:
          'Built around fast pressure, player fights and strong disengage options.',
      augment: 'Combat Augment',
      primaryWeapon: 'Tempest',
      secondaryWeapon: 'Anvil',
      equipment: ['Pulse Mine', 'Snap Hook'],
      consumables: ['Vita Shot', 'Triggernade'],
    ),
    ArcSavedLoadoutSeed(
      name: 'PvE Control',
      category: ArcLoadoutCategory.pve,
      description:
          'Reliable ARC control with safer sustain and flexible utility.',
      augment: 'Safekeeper',
      primaryWeapon: 'Rattler',
      secondaryWeapon: 'Stitcher',
      equipment: ['Shield Level 2', 'Wolfpack'],
      consumables: ['Vita Spray', 'Lure Grenade'],
    ),
    ArcSavedLoadoutSeed(
      name: 'Current Meta Watch',
      category: ArcLoadoutCategory.meta,
      description:
          'A placeholder meta slot ready for community-driven loadout trends.',
      augment: 'Survivor',
      primaryWeapon: 'Ferro',
      secondaryWeapon: 'Venator',
      equipment: ['Shield Level 2', 'Snap Hook'],
      consumables: ['Vita Shot', 'Triggernade'],
    ),
  ];
}
