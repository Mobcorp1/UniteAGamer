import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_weapon_attachment_database.dart';
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

  static final List<ArcLoadoutAttachmentSpec> attachments =
      ArcWeaponAttachmentDatabase.attachments;

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
