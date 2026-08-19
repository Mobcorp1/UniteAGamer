import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';

class ArcMapFilterTaxonomyEntry {
  const ArcMapFilterTaxonomyEntry({
    required this.id,
    required this.label,
    required this.groupId,
    required this.groupLabel,
    required this.kind,
    required this.iconKey,
    this.description = '',
  });

  final String id;
  final String label;
  final String groupId;
  final String groupLabel;
  final ArcAdminMapMarkerKind kind;
  final String iconKey;
  final String description;
}

class ArcMapFilterTaxonomyGroup {
  const ArcMapFilterTaxonomyGroup({
    required this.id,
    required this.label,
    required this.entries,
  });

  final String id;
  final String label;
  final List<ArcMapFilterTaxonomyEntry> entries;
}

class ArcMapFilterTaxonomy {
  const ArcMapFilterTaxonomy._();

  static const List<ArcMapFilterTaxonomyEntry> extraction = [
    ArcMapFilterTaxonomyEntry(
      id: 'cargo_elevator',
      label: 'Cargo Elevator',
      groupId: 'extraction',
      groupLabel: 'Extraction',
      kind: ArcAdminMapMarkerKind.extraction,
      iconKey: 'extract_cargo_elevator',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'metro_station',
      label: 'Metro Station',
      groupId: 'extraction',
      groupLabel: 'Extraction',
      kind: ArcAdminMapMarkerKind.extraction,
      iconKey: 'extract_metro_station',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'airshaft',
      label: 'Airshaft',
      groupId: 'extraction',
      groupLabel: 'Extraction',
      kind: ArcAdminMapMarkerKind.extraction,
      iconKey: 'extract_airshaft',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'standard_extraction',
      label: 'Standard Extraction',
      groupId: 'extraction',
      groupLabel: 'Extraction',
      kind: ArcAdminMapMarkerKind.extraction,
      iconKey: 'extract_standard',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'raider_hatch',
      label: 'Raider Hatch',
      groupId: 'extraction',
      groupLabel: 'Extraction',
      kind: ArcAdminMapMarkerKind.raiderHatch,
      iconKey: 'extract_raider_hatch',
    ),
  ];

  static const List<ArcMapFilterTaxonomyEntry> infrastructure = [
    ArcMapFilterTaxonomyEntry(
      id: 'field_depot',
      label: 'Field Depot',
      groupId: 'infrastructure',
      groupLabel: 'Raider Infrastructure',
      kind: ArcAdminMapMarkerKind.poi,
      iconKey: 'infra_field_depot',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'supply_station',
      label: 'Supply Station',
      groupId: 'infrastructure',
      groupLabel: 'Raider Infrastructure',
      kind: ArcAdminMapMarkerKind.poi,
      iconKey: 'infra_supply_station',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'raider_camp',
      label: 'Raider Camp',
      groupId: 'infrastructure',
      groupLabel: 'Raider Infrastructure',
      kind: ArcAdminMapMarkerKind.poi,
      iconKey: 'infra_raider_camp',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'player_spawn',
      label: 'Player Spawn',
      groupId: 'infrastructure',
      groupLabel: 'Raider Infrastructure',
      kind: ArcAdminMapMarkerKind.poi,
      iconKey: 'infra_player_spawn',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'zipline',
      label: 'Zipline',
      groupId: 'infrastructure',
      groupLabel: 'Raider Infrastructure',
      kind: ArcAdminMapMarkerKind.poi,
      iconKey: 'infra_zipline',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'antenna',
      label: 'Antenna',
      groupId: 'infrastructure',
      groupLabel: 'Raider Infrastructure',
      kind: ArcAdminMapMarkerKind.poi,
      iconKey: 'infra_antenna',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'generator',
      label: 'Generator',
      groupId: 'infrastructure',
      groupLabel: 'Raider Infrastructure',
      kind: ArcAdminMapMarkerKind.poi,
      iconKey: 'infra_generator',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'puzzle_console',
      label: 'Puzzle Console',
      groupId: 'infrastructure',
      groupLabel: 'Raider Infrastructure',
      kind: ArcAdminMapMarkerKind.poi,
      iconKey: 'infra_puzzle_console',
    ),
  ];

  static const List<ArcMapFilterTaxonomyEntry> loot = [
    ArcMapFilterTaxonomyEntry(
      id: 'weapon_case',
      label: 'Weapon Case',
      groupId: 'loot',
      groupLabel: 'Loot & Containers',
      kind: ArcAdminMapMarkerKind.weaponCase,
      iconKey: 'loot_weapon_case',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'weapon_tube',
      label: 'Weapon Tube',
      groupId: 'loot',
      groupLabel: 'Loot & Containers',
      kind: ArcAdminMapMarkerKind.weaponCase,
      iconKey: 'firearm',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'weapon_cache',
      label: 'Weapon Cache',
      groupId: 'loot',
      groupLabel: 'Loot & Containers',
      kind: ArcAdminMapMarkerKind.weaponCache,
      iconKey: 'loot_weapon_cache',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'security_locker',
      label: 'Security Locker',
      groupId: 'loot',
      groupLabel: 'Loot & Containers',
      kind: ArcAdminMapMarkerKind.securityRoom,
      iconKey: 'loot_security_locker',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'raider_cache',
      label: 'Raider Cache',
      groupId: 'loot',
      groupLabel: 'Loot & Containers',
      kind: ArcAdminMapMarkerKind.raiderCache,
      iconKey: 'loot_raider_cache',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'first_wave_cache',
      label: 'First Wave Cache',
      groupId: 'loot',
      groupLabel: 'Loot & Containers',
      kind: ArcAdminMapMarkerKind.firstWaveCache,
      iconKey: 'loot_first_wave_cache',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'field_crate',
      label: 'Field Crate',
      groupId: 'loot',
      groupLabel: 'Loot & Containers',
      kind: ArcAdminMapMarkerKind.fieldCrate,
      iconKey: 'loot_field_crate',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'ammo_case',
      label: 'Ammo Case',
      groupId: 'loot',
      groupLabel: 'Loot & Containers',
      kind: ArcAdminMapMarkerKind.lootContainer,
      iconKey: 'loot_ammo_case',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'medical_container',
      label: 'Medical Container',
      groupId: 'loot',
      groupLabel: 'Loot & Containers',
      kind: ArcAdminMapMarkerKind.lootContainer,
      iconKey: 'loot_medical_container',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'mechanical_crate',
      label: 'Mechanical Crate',
      groupId: 'loot',
      groupLabel: 'Loot & Containers',
      kind: ArcAdminMapMarkerKind.lootContainer,
      iconKey: 'loot_mechanical_crate',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'industrial_container',
      label: 'Industrial Container',
      groupId: 'loot',
      groupLabel: 'Loot & Containers',
      kind: ArcAdminMapMarkerKind.lootContainer,
      iconKey: 'loot_industrial_container',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'electrical_container',
      label: 'Electrical Container',
      groupId: 'loot',
      groupLabel: 'Loot & Containers',
      kind: ArcAdminMapMarkerKind.lootContainer,
      iconKey: 'loot_electrical_container',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'residential_container',
      label: 'Residential Container',
      groupId: 'loot',
      groupLabel: 'Loot & Containers',
      kind: ArcAdminMapMarkerKind.lootContainer,
      iconKey: 'loot_residential_container',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'special_container',
      label: 'Special Container',
      groupId: 'loot',
      groupLabel: 'Loot & Containers',
      kind: ArcAdminMapMarkerKind.lootContainer,
      iconKey: 'loot_special_container',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'high_value_loot',
      label: 'High-Value Loot',
      groupId: 'loot',
      groupLabel: 'Loot & Containers',
      kind: ArcAdminMapMarkerKind.highValueLoot,
      iconKey: 'loot_high_value',
    ),
  ];

  static const List<ArcMapFilterTaxonomyEntry> access = [
    ArcMapFilterTaxonomyEntry(
      id: 'locked_room',
      label: 'Locked Room',
      groupId: 'access',
      groupLabel: 'Locked & Access Areas',
      kind: ArcAdminMapMarkerKind.lockedRoom,
      iconKey: 'access_locked_room',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'security_room',
      label: 'Security Room',
      groupId: 'access',
      groupLabel: 'Locked & Access Areas',
      kind: ArcAdminMapMarkerKind.securityRoom,
      iconKey: 'access_security_room',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'key_room',
      label: 'Key Room',
      groupId: 'access',
      groupLabel: 'Locked & Access Areas',
      kind: ArcAdminMapMarkerKind.keyRequiredLocation,
      iconKey: 'access_key_room',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'breachable_door',
      label: 'Breachable Door',
      groupId: 'access',
      groupLabel: 'Locked & Access Areas',
      kind: ArcAdminMapMarkerKind.lockedRoom,
      iconKey: 'access_breachable_door',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'power_rod_room',
      label: 'Power Rod Room',
      groupId: 'access',
      groupLabel: 'Locked & Access Areas',
      kind: ArcAdminMapMarkerKind.keyRequiredLocation,
      iconKey: 'access_power_rod_room',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'bunker_entrance',
      label: 'Bunker Entrance',
      groupId: 'access',
      groupLabel: 'Locked & Access Areas',
      kind: ArcAdminMapMarkerKind.keyRequiredLocation,
      iconKey: 'access_bunker_entrance',
    ),
  ];

  static const List<ArcMapFilterTaxonomyEntry> arc = [
    ArcMapFilterTaxonomyEntry(
      id: 'snitch',
      label: 'Snitch',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_snitch',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'wasp',
      label: 'Wasp',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_wasp',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'hornet',
      label: 'Hornet',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_hornet',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'pop',
      label: 'Pop',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_pop',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'fireball',
      label: 'Fireball',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_fireball',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'tick',
      label: 'Tick',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_tick',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'turbine',
      label: 'Turbine',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_turbine',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'turret',
      label: 'Turret',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_turret',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'spotter',
      label: 'Spotter',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_spotter',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'surveyor',
      label: 'Surveyor',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_surveyor',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'sentinel',
      label: 'Sentinel',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_sentinel',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'rocketeer',
      label: 'Rocketeer',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_rocketeer',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'leaper',
      label: 'Leaper',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_leaper',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'bastion',
      label: 'Bastion',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_bastion',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'bombardier',
      label: 'Bombardier',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_bombardier',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'queen',
      label: 'The Queen',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_queen',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'matriarch',
      label: 'Matriarch',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_matriarch',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'shredder',
      label: 'Shredder',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_shredder',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'comet',
      label: 'Comet',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_comet',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'firefly',
      label: 'Firefly',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_firefly',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'vaporizer',
      label: 'Vaporizer',
      groupId: 'arc',
      groupLabel: 'ARC Enemies',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_vaporizer',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'arc_probe',
      label: 'ARC Probe',
      groupId: 'arc_world',
      groupLabel: 'ARC Remains & Machines',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_probe',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'arc_courier',
      label: 'ARC Courier',
      groupId: 'arc_world',
      groupLabel: 'ARC Remains & Machines',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_courier',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'arc_harvester',
      label: 'ARC Harvester',
      groupId: 'arc_world',
      groupLabel: 'ARC Remains & Machines',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_harvester',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'arc_assessor',
      label: 'ARC Assessor',
      groupId: 'arc_world',
      groupLabel: 'ARC Remains & Machines',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_assessor',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'arc_husk',
      label: 'ARC Husk',
      groupId: 'arc_world',
      groupLabel: 'ARC Remains & Machines',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_husk',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'baron_husk',
      label: 'Baron Husk',
      groupId: 'arc_world',
      groupLabel: 'ARC Remains & Machines',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      iconKey: 'arc_baron_husk',
    ),
  ];

  static const List<ArcMapFilterTaxonomyEntry> nature = [
    ArcMapFilterTaxonomyEntry(
      id: 'agave',
      label: 'Agave',
      groupId: 'nature',
      groupLabel: 'Natural Resources',
      kind: ArcAdminMapMarkerKind.naturalResource,
      iconKey: 'nature_agave',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'apricot',
      label: 'Apricot',
      groupId: 'nature',
      groupLabel: 'Natural Resources',
      kind: ArcAdminMapMarkerKind.naturalResource,
      iconKey: 'nature_apricot',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'great_mullein',
      label: 'Great Mullein',
      groupId: 'nature',
      groupLabel: 'Natural Resources',
      kind: ArcAdminMapMarkerKind.naturalResource,
      iconKey: 'nature_great_mullein',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'lemon',
      label: 'Lemon',
      groupId: 'nature',
      groupLabel: 'Natural Resources',
      kind: ArcAdminMapMarkerKind.naturalResource,
      iconKey: 'nature_lemon',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'mushroom',
      label: 'Mushroom',
      groupId: 'nature',
      groupLabel: 'Natural Resources',
      kind: ArcAdminMapMarkerKind.naturalResource,
      iconKey: 'nature_mushroom',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'olives',
      label: 'Olives',
      groupId: 'nature',
      groupLabel: 'Natural Resources',
      kind: ArcAdminMapMarkerKind.naturalResource,
      iconKey: 'nature_olives',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'prickly_pear',
      label: 'Prickly Pear',
      groupId: 'nature',
      groupLabel: 'Natural Resources',
      kind: ArcAdminMapMarkerKind.naturalResource,
      iconKey: 'nature_prickly_pear',
    ),
  ];

  static const List<ArcMapFilterTaxonomyEntry> objectives = [
    ArcMapFilterTaxonomyEntry(
      id: 'quest_area',
      label: 'Quest Area',
      groupId: 'objectives',
      groupLabel: 'Quests & Objectives',
      kind: ArcAdminMapMarkerKind.questLocation,
      iconKey: 'quest_area',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'quest_item',
      label: 'Quest Item',
      groupId: 'objectives',
      groupLabel: 'Quests & Objectives',
      kind: ArcAdminMapMarkerKind.questLocation,
      iconKey: 'quest_item',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'quest_objective',
      label: 'Quest Objective',
      groupId: 'objectives',
      groupLabel: 'Quests & Objectives',
      kind: ArcAdminMapMarkerKind.questLocation,
      iconKey: 'quest_objective',
    ),
    ArcMapFilterTaxonomyEntry(
      id: 'dead_drop',
      label: 'Dead Drop',
      groupId: 'objectives',
      groupLabel: 'Quests & Objectives',
      kind: ArcAdminMapMarkerKind.questLocation,
      iconKey: 'quest_dead_drop',
    ),
  ];

  static const List<ArcMapFilterTaxonomyEntry> all = [
    ...extraction,
    ...infrastructure,
    ...loot,
    ...access,
    ...arc,
    ...nature,
    ...objectives,
  ];

  static const List<ArcMapFilterTaxonomyGroup> groups = [
    ArcMapFilterTaxonomyGroup(
      id: 'extraction',
      label: 'Extraction',
      entries: extraction,
    ),
    ArcMapFilterTaxonomyGroup(
      id: 'infrastructure',
      label: 'Raider Infrastructure',
      entries: infrastructure,
    ),
    ArcMapFilterTaxonomyGroup(
      id: 'loot',
      label: 'Loot & Containers',
      entries: loot,
    ),
    ArcMapFilterTaxonomyGroup(
      id: 'access',
      label: 'Locked & Access Areas',
      entries: access,
    ),
    ArcMapFilterTaxonomyGroup(
      id: 'arc',
      label: 'ARC Enemies & World Objects',
      entries: arc,
    ),
    ArcMapFilterTaxonomyGroup(
      id: 'nature',
      label: 'Natural Resources',
      entries: nature,
    ),
    ArcMapFilterTaxonomyGroup(
      id: 'objectives',
      label: 'Quests & Objectives',
      entries: objectives,
    ),
  ];

  static List<ArcMapFilterTaxonomyEntry> forKind(ArcAdminMapMarkerKind kind) =>
      all.where((entry) => entry.kind == kind).toList(growable: false);

  static ArcMapFilterTaxonomyEntry? byId(String? id) {
    final normalized = id?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    for (final entry in all) {
      if (entry.id == normalized) return entry;
    }
    return null;
  }

  static String? iconKeyFor(String? subtypeId) => byId(subtypeId)?.iconKey;
}
