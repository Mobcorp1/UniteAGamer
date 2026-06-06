import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';

class ArcLoadoutSeedData {
  const ArcLoadoutSeedData._();

  static const List<ArcLoadoutWeaponSpec> weapons = [
    ArcLoadoutWeaponSpec(
      name: 'Anvil',
      category: 'Hand Cannon',
      role: 'High-impact raider stopping power',
      slots: ['Muzzle', 'Tech Mod'],
      blueprintBased: true,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Stitcher',
      category: 'SMG',
      role: 'Close-range ARC and raider pressure',
      slots: ['Muzzle', 'Underbarrel', 'Light Magazine', 'Stock'],
      craftable: true,
      gunsmithLevel: 2,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Rattler',
      category: 'Assault Rifle',
      role: 'Reliable automatic mid-range control',
      slots: ['Muzzle', 'Underbarrel', 'Stock'],
      craftable: true,
      gunsmithLevel: 2,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Ferro',
      category: 'Battle Rifle',
      role: 'Heavy precision damage',
      slots: ['Muzzle', 'Underbarrel', 'Stock'],
      craftable: true,
      gunsmithLevel: 2,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Harpy',
      category: 'Pistol',
      role: 'Early craftable sidearm option',
      slots: ['Muzzle', 'Magazine'],
      craftable: true,
      gunsmithLevel: 1,
      notes: 'Bench level to verify against live data.',
    ),
    ArcLoadoutWeaponSpec(
      name: 'Kettle',
      category: 'Assault Rifle',
      role: 'Starter-friendly semi-auto control',
      slots: ['Muzzle', 'Underbarrel', 'Light Magazine', 'Stock'],
    ),
    ArcLoadoutWeaponSpec(
      name: 'Tempest',
      category: 'Assault Rifle',
      role: 'Aggressive automatic PvP pressure',
      slots: ['Muzzle', 'Underbarrel', 'Medium Magazine'],
      blueprintBased: true,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Bettina',
      category: 'Assault Rifle',
      role: 'Heavy automatic damage',
      slots: ['Muzzle', 'Underbarrel', 'Stock'],
      blueprintBased: true,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Burletta',
      category: 'Pistol',
      role: 'Light backup sidearm',
      slots: ['Muzzle', 'Light Magazine'],
    ),
    ArcLoadoutWeaponSpec(
      name: 'Venator',
      category: 'Pistol',
      role: 'Medium sidearm pressure',
      slots: ['Underbarrel', 'Medium Magazine'],
      blueprintBased: true,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Il Toro',
      category: 'Shotgun',
      role: 'Close-range burst threat',
      slots: ['Shotgun Muzzle', 'Underbarrel', 'Shotgun Magazine', 'Stock'],
      blueprintBased: true,
    ),
    ArcLoadoutWeaponSpec(
      name: 'Osprey',
      category: 'Sniper Rifle',
      role: 'Long-range precision',
      slots: ['Muzzle', 'Underbarrel', 'Medium Magazine', 'Stock'],
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
