import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_intelligence_models.dart';

class ArcLoadoutIntelligenceCatalog {
  const ArcLoadoutIntelligenceCatalog._();

  static const String version = '2026.08.03-v1';
  static final DateTime researchedAt = DateTime.utc(2026, 8, 3);

  static const List<ArcLoadoutWeaponIntelligenceProfile> profiles = [
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Anvil',
      rangeBand: ArcWeaponRangeBand.medium,
      pvpScore: 9,
      pveScore: 8,
      valueScore: 9,
      roleSummary:
          'High-impact heavy-ammo sidearm with strong armour pressure and excellent value.',
      pvpSecondaries: ['Stitcher', 'Bobcat', 'Vulcano'],
      balancedSecondaries: ['Stitcher', 'Kettle', 'Bettina'],
      pveSecondaries: ['Stitcher', 'Tempest', 'Kettle'],
      notes: ['Strong value anchor; pair with sustained close-range fire.'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Aphelion',
      rangeBand: ArcWeaponRangeBand.specialist,
      pvpScore: 6,
      pveScore: 8,
      valueScore: 5,
      roleSummary:
          'Specialist platform best paired with a dependable Raider-fighting secondary.',
      pvpSecondaries: ['Venator', 'Stitcher', 'Bobcat'],
      balancedSecondaries: ['Venator', 'Kettle', 'Arpeggio'],
      pveSecondaries: ['Anvil', 'Kettle', 'Tempest'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Arpeggio',
      rangeBand: ArcWeaponRangeBand.medium,
      pvpScore: 8,
      pveScore: 7,
      valueScore: 7,
      roleSummary:
          'Flexible medium-range rifle that benefits heavily from dispersion, magazine and recovery mods.',
      pvpSecondaries: ['Venator', 'Vulcano', 'Stitcher'],
      balancedSecondaries: ['Venator', 'Anvil', 'Il Toro'],
      pveSecondaries: ['Anvil', 'Hullcracker', 'Stitcher'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Bettina',
      rangeBand: ArcWeaponRangeBand.medium,
      pvpScore: 9,
      pveScore: 9,
      valueScore: 6,
      roleSummary:
          'Premium versatile rifle with strong armour damage and broad PvPvE usefulness.',
      pvpSecondaries: ['Venator', 'Vulcano', 'Bobcat'],
      balancedSecondaries: ['Venator', 'Anvil', 'Il Toro'],
      pveSecondaries: ['Hullcracker', 'Anvil', 'Stitcher'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Bobcat',
      rangeBand: ArcWeaponRangeBand.close,
      pvpScore: 8,
      pveScore: 6,
      valueScore: 5,
      roleSummary:
          'Mobile close-range pressure weapon; expensive relative to cheaper SMG alternatives.',
      pvpSecondaries: ['Anvil', 'Osprey', 'Ferro'],
      balancedSecondaries: ['Anvil', 'Kettle', 'Arpeggio'],
      pveSecondaries: ['Anvil', 'Hullcracker', 'Ferro'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Burletta',
      rangeBand: ArcWeaponRangeBand.close,
      pvpScore: 5,
      pveScore: 5,
      valueScore: 8,
      roleSummary:
          'Light economical backup that keeps weight and replacement cost low.',
      pvpSecondaries: ['Arpeggio', 'Bettina', 'Osprey'],
      balancedSecondaries: ['Kettle', 'Ferro', 'Arpeggio'],
      pveSecondaries: ['Hullcracker', 'Ferro', 'Anvil'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Canto',
      rangeBand: ArcWeaponRangeBand.medium,
      pvpScore: 7,
      pveScore: 7,
      valueScore: 6,
      roleSummary:
          'General-purpose rifle platform with a full attachment layout.',
      pvpSecondaries: ['Venator', 'Vulcano', 'Stitcher'],
      balancedSecondaries: ['Anvil', 'Venator', 'Il Toro'],
      pveSecondaries: ['Hullcracker', 'Anvil', 'Stitcher'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Equalizer',
      rangeBand: ArcWeaponRangeBand.specialist,
      pvpScore: 6,
      pveScore: 10,
      valueScore: 2,
      roleSummary:
          'Legendary ARC specialist with exceptional PvE output and high upkeep.',
      pvpSecondaries: ['Venator', 'Vulcano', 'Tempest'],
      balancedSecondaries: ['Venator', 'Bettina', 'Stitcher'],
      pveSecondaries: ['Venator', 'Stitcher', 'Anvil'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Ferro',
      rangeBand: ArcWeaponRangeBand.long,
      pvpScore: 7,
      pveScore: 8,
      valueScore: 10,
      roleSummary:
          'Cheap, hard-hitting precision rifle with excellent armour penetration and replacement value.',
      pvpSecondaries: ['Stitcher', 'Venator', 'Il Toro'],
      balancedSecondaries: ['Stitcher', 'Kettle', 'Venator'],
      pveSecondaries: ['Stitcher', 'Anvil', 'Kettle'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Hairpin',
      rangeBand: ArcWeaponRangeBand.close,
      pvpScore: 4,
      pveScore: 5,
      valueScore: 8,
      roleSummary:
          'Silent utility sidearm for low-risk stealth and finishing work.',
      pvpSecondaries: ['Arpeggio', 'Bettina', 'Tempest'],
      balancedSecondaries: ['Kettle', 'Ferro', 'Arpeggio'],
      pveSecondaries: ['Hullcracker', 'Ferro', 'Anvil'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Hullcracker',
      rangeBand: ArcWeaponRangeBand.specialist,
      pvpScore: 3,
      pveScore: 10,
      valueScore: 4,
      roleSummary:
          'Top-tier anti-ARC specialist that needs a dedicated anti-Raider secondary.',
      pvpSecondaries: ['Venator', 'Tempest', 'Vulcano'],
      balancedSecondaries: ['Venator', 'Stitcher', 'Bettina'],
      pveSecondaries: ['Venator', 'Stitcher', 'Anvil'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Il Toro',
      rangeBand: ArcWeaponRangeBand.close,
      pvpScore: 8,
      pveScore: 6,
      valueScore: 7,
      roleSummary:
          'Close-range shotgun pressure with better value than premium alternatives.',
      pvpSecondaries: ['Ferro', 'Osprey', 'Arpeggio'],
      balancedSecondaries: ['Kettle', 'Ferro', 'Arpeggio'],
      pveSecondaries: ['Ferro', 'Anvil', 'Hullcracker'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Jupiter',
      rangeBand: ArcWeaponRangeBand.long,
      pvpScore: 8,
      pveScore: 8,
      valueScore: 2,
      roleSummary:
          'Legendary long-range precision weapon requiring close-range protection.',
      pvpSecondaries: ['Venator', 'Vulcano', 'Bobcat'],
      balancedSecondaries: ['Venator', 'Stitcher', 'Il Toro'],
      pveSecondaries: ['Anvil', 'Stitcher', 'Venator'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Kettle',
      rangeBand: ArcWeaponRangeBand.medium,
      pvpScore: 7,
      pveScore: 7,
      valueScore: 10,
      roleSummary:
          'Starter-friendly, controllable and inexpensive all-round rifle.',
      pvpSecondaries: ['Anvil', 'Stitcher', 'Il Toro'],
      balancedSecondaries: ['Anvil', 'Stitcher', 'Ferro'],
      pveSecondaries: ['Anvil', 'Ferro', 'Stitcher'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Osprey',
      rangeBand: ArcWeaponRangeBand.long,
      pvpScore: 8,
      pveScore: 7,
      valueScore: 7,
      roleSummary:
          'Long-range precision rifle that should be paired with immediate close-range defence.',
      pvpSecondaries: ['Venator', 'Stitcher', 'Vulcano'],
      balancedSecondaries: ['Venator', 'Stitcher', 'Il Toro'],
      pveSecondaries: ['Anvil', 'Stitcher', 'Kettle'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Rascal',
      rangeBand: ArcWeaponRangeBand.close,
      pvpScore: 5,
      pveScore: 5,
      valueScore: 7,
      roleSummary: 'Simple no-mod backup suited to low-investment runs.',
      pvpSecondaries: ['Arpeggio', 'Tempest', 'Ferro'],
      balancedSecondaries: ['Kettle', 'Arpeggio', 'Ferro'],
      pveSecondaries: ['Hullcracker', 'Ferro', 'Anvil'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Rattler',
      rangeBand: ArcWeaponRangeBand.medium,
      pvpScore: 7,
      pveScore: 7,
      valueScore: 9,
      roleSummary:
          'Reliable automatic rifle with a compact mod path and strong economy.',
      pvpSecondaries: ['Anvil', 'Venator', 'Il Toro'],
      balancedSecondaries: ['Anvil', 'Venator', 'Ferro'],
      pveSecondaries: ['Anvil', 'Ferro', 'Stitcher'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Renegade',
      rangeBand: ArcWeaponRangeBand.medium,
      pvpScore: 8,
      pveScore: 8,
      valueScore: 6,
      roleSummary:
          'Heavy sustained pressure platform that benefits from recoil control and recovery.',
      pvpSecondaries: ['Venator', 'Vulcano', 'Stitcher'],
      balancedSecondaries: ['Venator', 'Anvil', 'Il Toro'],
      pveSecondaries: ['Hullcracker', 'Anvil', 'Stitcher'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Stitcher',
      rangeBand: ArcWeaponRangeBand.close,
      pvpScore: 8,
      pveScore: 7,
      valueScore: 10,
      roleSummary:
          'Cheap fast-firing SMG and one of the strongest value secondaries.',
      pvpSecondaries: ['Anvil', 'Osprey', 'Ferro'],
      balancedSecondaries: ['Anvil', 'Kettle', 'Ferro'],
      pveSecondaries: ['Anvil', 'Hullcracker', 'Ferro'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Tempest',
      rangeBand: ArcWeaponRangeBand.medium,
      pvpScore: 9,
      pveScore: 7,
      valueScore: 5,
      roleSummary:
          'Aggressive premium automatic rifle with high PvP pressure but weaker cost efficiency.',
      pvpSecondaries: ['Venator', 'Vulcano', 'Bobcat'],
      balancedSecondaries: ['Venator', 'Anvil', 'Il Toro'],
      pveSecondaries: ['Hullcracker', 'Anvil', 'Stitcher'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Torrente',
      rangeBand: ArcWeaponRangeBand.medium,
      pvpScore: 8,
      pveScore: 8,
      valueScore: 5,
      roleSummary:
          'Sustained squad suppression platform with strong magazine and recovery synergy.',
      pvpSecondaries: ['Venator', 'Il Toro', 'Stitcher'],
      balancedSecondaries: ['Venator', 'Anvil', 'Il Toro'],
      pveSecondaries: ['Anvil', 'Hullcracker', 'Stitcher'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Venator',
      rangeBand: ArcWeaponRangeBand.close,
      pvpScore: 10,
      pveScore: 7,
      valueScore: 8,
      roleSummary:
          'Elite PvP sidearm with excellent close-to-medium versatility.',
      pvpSecondaries: ['Osprey', 'Ferro', 'Bettina'],
      balancedSecondaries: ['Bettina', 'Arpeggio', 'Hullcracker'],
      pveSecondaries: ['Hullcracker', 'Equalizer', 'Ferro'],
    ),
    ArcLoadoutWeaponIntelligenceProfile(
      weaponName: 'Vulcano',
      rangeBand: ArcWeaponRangeBand.close,
      pvpScore: 10,
      pveScore: 7,
      valueScore: 4,
      roleSummary:
          'Premium close-range burst shotgun; devastating but costly to replace.',
      pvpSecondaries: ['Osprey', 'Ferro', 'Arpeggio'],
      balancedSecondaries: ['Bettina', 'Ferro', 'Arpeggio'],
      pveSecondaries: ['Ferro', 'Hullcracker', 'Anvil'],
    ),
  ];

  static ArcLoadoutWeaponIntelligenceProfile profileFor(String weaponName) {
    final normalised = weaponName.trim().toLowerCase();
    return profiles.firstWhere(
      (profile) => profile.weaponName.toLowerCase() == normalised,
      orElse: () => profiles.first,
    );
  }
}
