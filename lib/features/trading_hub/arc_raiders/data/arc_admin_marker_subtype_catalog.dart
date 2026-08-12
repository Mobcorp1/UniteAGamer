import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_container_types.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_filter_taxonomy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

class ArcAdminMapMarkerSubtype {
  const ArcAdminMapMarkerSubtype({
    required this.id,
    required this.label,
    required this.kind,
    required this.groupLabel,
    this.iconKey,
  });

  final String id;
  final String label;
  final ArcAdminMapMarkerKind kind;
  final String groupLabel;
  final String? iconKey;
}

class ArcAdminMapMarkerSubtypeCatalog {
  const ArcAdminMapMarkerSubtypeCatalog._();

  static const List<ArcAdminMapMarkerSubtype> nature = [
    ArcAdminMapMarkerSubtype(
      id: 'agave',
      label: 'Agave',
      kind: ArcAdminMapMarkerKind.naturalResource,
      groupLabel: 'Nature',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'apricot',
      label: 'Apricot',
      kind: ArcAdminMapMarkerKind.naturalResource,
      groupLabel: 'Nature',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'candleberries',
      label: 'Candleberries',
      kind: ArcAdminMapMarkerKind.naturalResource,
      groupLabel: 'Nature',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'fertilizer',
      label: 'Fertilizer',
      kind: ArcAdminMapMarkerKind.naturalResource,
      groupLabel: 'Nature',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'great_mullein',
      label: 'Great Mullein',
      kind: ArcAdminMapMarkerKind.naturalResource,
      groupLabel: 'Nature',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'lemon',
      label: 'Lemon',
      kind: ArcAdminMapMarkerKind.naturalResource,
      groupLabel: 'Nature',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'moss',
      label: 'Moss',
      kind: ArcAdminMapMarkerKind.naturalResource,
      groupLabel: 'Nature',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'mushroom',
      label: 'Mushroom',
      kind: ArcAdminMapMarkerKind.naturalResource,
      groupLabel: 'Nature',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'olives',
      label: 'Olives',
      kind: ArcAdminMapMarkerKind.naturalResource,
      groupLabel: 'Nature',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'prickly_pear',
      label: 'Prickly Pear',
      kind: ArcAdminMapMarkerKind.naturalResource,
      groupLabel: 'Nature',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'roots',
      label: 'Roots',
      kind: ArcAdminMapMarkerKind.naturalResource,
      groupLabel: 'Nature',
    ),
  ];

  static const List<ArcAdminMapMarkerSubtype> arc = [
    ArcAdminMapMarkerSubtype(
      id: 'arc_husk',
      label: 'ARC Husk',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'arc_probe',
      label: 'ARC Probe',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'baron_husk',
      label: 'Baron Husk',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'bastion',
      label: 'Bastion',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'bombardier',
      label: 'Bombardier',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'fireball',
      label: 'Fireball',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'hornet',
      label: 'Hornet',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'leaper',
      label: 'Leaper',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'matriarch',
      label: 'Matriarch',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'pop',
      label: 'Pop',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'rocketeer',
      label: 'Rocketeer',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'sentinel',
      label: 'Sentinel',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'snitch',
      label: 'Snitch',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'spotter',
      label: 'Spotter',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'surveyor',
      label: 'Surveyor',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'tick',
      label: 'Tick',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'turret',
      label: 'Turret',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'wasp',
      label: 'Wasp',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'queen',
      label: 'The Queen',
      kind: ArcAdminMapMarkerKind.arcSpawn,
      groupLabel: 'ARC',
    ),
  ];

  static const List<ArcAdminMapMarkerSubtype> quest = [
    ArcAdminMapMarkerSubtype(
      id: 'quest_area',
      label: 'Quest Area',
      kind: ArcAdminMapMarkerKind.questLocation,
      groupLabel: 'Quests',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'quest_item',
      label: 'Quest Item',
      kind: ArcAdminMapMarkerKind.questLocation,
      groupLabel: 'Quests',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'quest_objective',
      label: 'Quest Objective',
      kind: ArcAdminMapMarkerKind.questLocation,
      groupLabel: 'Quests',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'quest_start',
      label: 'Quest Start',
      kind: ArcAdminMapMarkerKind.questLocation,
      groupLabel: 'Quests',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'quest_turn_in',
      label: 'Quest Turn-in',
      kind: ArcAdminMapMarkerKind.questLocation,
      groupLabel: 'Quests',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'dead_drop',
      label: 'Dead Drop',
      kind: ArcAdminMapMarkerKind.questLocation,
      groupLabel: 'Quests',
    ),
  ];

  static const List<ArcAdminMapMarkerSubtype> location = [
    ArcAdminMapMarkerSubtype(
      id: 'antenna',
      label: 'Antenna',
      kind: ArcAdminMapMarkerKind.poi,
      groupLabel: 'Locations',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'button',
      label: 'Button',
      kind: ArcAdminMapMarkerKind.poi,
      groupLabel: 'Locations',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'elevator',
      label: 'Elevator',
      kind: ArcAdminMapMarkerKind.poi,
      groupLabel: 'Locations',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'extraction',
      label: 'Extraction',
      kind: ArcAdminMapMarkerKind.extraction,
      groupLabel: 'Locations',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'fuel_cell',
      label: 'Fuel Cell',
      kind: ArcAdminMapMarkerKind.poi,
      groupLabel: 'Locations',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'generator',
      label: 'Generator',
      kind: ArcAdminMapMarkerKind.poi,
      groupLabel: 'Locations',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'metro_entrance',
      label: 'Metro Entrance',
      kind: ArcAdminMapMarkerKind.poi,
      groupLabel: 'Locations',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'metro_station',
      label: 'Metro Station',
      kind: ArcAdminMapMarkerKind.poi,
      groupLabel: 'Locations',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'player_spawn',
      label: 'Player Spawn',
      kind: ArcAdminMapMarkerKind.poi,
      groupLabel: 'Locations',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'puzzle_console',
      label: 'Puzzle Console',
      kind: ArcAdminMapMarkerKind.poi,
      groupLabel: 'Locations',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'raider_hatch',
      label: 'Raider Hatch',
      kind: ArcAdminMapMarkerKind.raiderHatch,
      groupLabel: 'Locations',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'supply_station',
      label: 'Supply Station',
      kind: ArcAdminMapMarkerKind.poi,
      groupLabel: 'Locations',
    ),
  ];

  static const List<ArcAdminMapMarkerSubtype> hazard = [
    ArcAdminMapMarkerSubtype(
      id: 'danger_zone',
      label: 'Danger Zone',
      kind: ArcAdminMapMarkerKind.hazard,
      groupLabel: 'Hazards',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'extraction_danger',
      label: 'Extraction Danger',
      kind: ArcAdminMapMarkerKind.extractionDanger,
      groupLabel: 'Hazards',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'radiation',
      label: 'Radiation',
      kind: ArcAdminMapMarkerKind.hazard,
      groupLabel: 'Hazards',
    ),
    ArcAdminMapMarkerSubtype(
      id: 'toxic_water',
      label: 'Toxic Water',
      kind: ArcAdminMapMarkerKind.hazard,
      groupLabel: 'Hazards',
    ),
  ];

  static final List<ArcAdminMapMarkerSubtype> events = [
    for (final condition in const <ArcMapCondition>[
      ArcMapConditions.nightRaid,
      ArcMapConditions.electromagneticStorm,
      ArcMapConditions.bloom,
      ArcMapConditions.coldSnap,
      ArcMapConditions.hurricane,
      ArcMapConditions.closeScrutiny,
      ArcMapConditions.harvester,
      ArcMapConditions.matriarch,
      ArcMapConditions.prospectingProbes,
      ArcMapConditions.uncoveredCaches,
      ArcMapConditions.huskGraveyard,
      ArcMapConditions.lushBlooms,
      ArcMapConditions.birdCity,
      ArcMapConditions.lockedGate,
      ArcMapConditions.hiddenBunker,
      ArcMapConditions.launchTowerLoot,
      ArcMapConditions.beachcombing,
      ArcMapConditions.lastResort,
    ])
      ArcAdminMapMarkerSubtype(
        id: condition.id,
        label: condition.label,
        kind: ArcAdminMapMarkerKind.mapEvent,
        groupLabel: condition.isWeather ? 'Weather' : 'Events',
      ),
  ];

  static final List<ArcAdminMapMarkerSubtype> containers = [
    for (final container in ArcContainerTypes.reportable)
      if (container.id != ArcContainerTypes.unknown.id)
        ArcAdminMapMarkerSubtype(
          id: container.id,
          label: container.label,
          kind: _kindForContainer(container.id),
          groupLabel: 'Containers',
        ),
  ];

  static const Map<String, List<String>> _eventIdsByMap = {
    'dam_battlegrounds': [
      'prospecting_probes',
      'harvester',
      'uncovered_caches',
      'husk_graveyard',
      'lush_blooms',
      'matriarch',
      'night_raid',
    ],
    'spaceport': [
      'prospecting_probes',
      'harvester',
      'uncovered_caches',
      'husk_graveyard',
      'launch_tower_loot',
      'lush_blooms',
      'matriarch',
      'hidden_bunker',
      'night_raid',
    ],
    'buried_city': [
      'prospecting_probes',
      'uncovered_caches',
      'husk_graveyard',
      'lush_blooms',
      'night_raid',
    ],
    'blue_gate': [
      'prospecting_probes',
      'harvester',
      'uncovered_caches',
      'husk_graveyard',
      'lush_blooms',
      'matriarch',
      'locked_gate',
      'night_raid',
    ],
    'stella_montis': ['night_raid'],
    'riven_tides': ['beachcombing', 'night_raid'],
  };

  static List<ArcAdminMapMarkerSubtype> _canonicalForKind(
    ArcAdminMapMarkerKind kind,
  ) {
    return [
      for (final entry in ArcMapFilterTaxonomy.forKind(kind))
        ArcAdminMapMarkerSubtype(
          id: entry.id,
          label: entry.label,
          kind: entry.kind,
          groupLabel: entry.groupLabel,
          iconKey: entry.iconKey,
        ),
    ];
  }

  static List<ArcAdminMapMarkerSubtype> forKind(
    ArcAdminMapMarkerKind kind, {
    String? mapName,
  }) {
    final existing = switch (kind) {
      ArcAdminMapMarkerKind.mapEvent => eventsForMap(mapName),
      ArcAdminMapMarkerKind.questLocation => quest,
      ArcAdminMapMarkerKind.resourceNode ||
      ArcAdminMapMarkerKind.naturalResource => nature,
      ArcAdminMapMarkerKind.arcSpawn || ArcAdminMapMarkerKind.arcThreat => arc,
      ArcAdminMapMarkerKind.weaponCase ||
      ArcAdminMapMarkerKind.weaponCache ||
      ArcAdminMapMarkerKind.firstWaveCache ||
      ArcAdminMapMarkerKind.raiderCache ||
      ArcAdminMapMarkerKind.fieldCrate ||
      ArcAdminMapMarkerKind.lootContainer ||
      ArcAdminMapMarkerKind.containerCluster ||
      ArcAdminMapMarkerKind.lockedRoom ||
      ArcAdminMapMarkerKind.securityRoom ||
      ArcAdminMapMarkerKind.highValueLoot ||
      ArcAdminMapMarkerKind.keyRequiredLocation => containers,
      ArcAdminMapMarkerKind.poi => locationsForMap(mapName),
      ArcAdminMapMarkerKind.extraction => extractionsForMap(mapName),
      ArcAdminMapMarkerKind.raiderHatch => hatchesForMap(mapName),
      ArcAdminMapMarkerKind.surfaceTransition => layerTransitionsForMap(
        ArcAdminMapMarkerKind.surfaceTransition,
        mapName,
      ),
      ArcAdminMapMarkerKind.undergroundTransition => layerTransitionsForMap(
        ArcAdminMapMarkerKind.undergroundTransition,
        mapName,
      ),
      ArcAdminMapMarkerKind.key => location,
      ArcAdminMapMarkerKind.hazard ||
      ArcAdminMapMarkerKind.extractionDanger => hazard,
      ArcAdminMapMarkerKind.blueprint ||
      ArcAdminMapMarkerKind.customIntel => const <ArcAdminMapMarkerSubtype>[],
    };
    return _dedupe([..._canonicalForKind(kind), ...existing]);
  }

  static ArcAdminMapMarkerSubtype? resolve(
    ArcAdminMapMarkerKind kind,
    String? value, {
    String? mapName,
  }) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    final normalized = slug(raw);
    final options = forKind(kind, mapName: mapName);
    for (final option in options) {
      if (option.id == normalized || slug(option.label) == normalized) {
        return option;
      }
    }
    return ArcAdminMapMarkerSubtype(
      id: normalized,
      label: _labelFromSlug(normalized),
      kind: kind,
      groupLabel: _groupForKind(kind),
    );
  }

  static List<ArcAdminMapMarkerSubtype> eventsForMap(String? mapName) {
    final key = _mapKey(mapName);
    final ids = _eventIdsByMap[key];
    if (ids == null) return events;
    final byId = <String, ArcAdminMapMarkerSubtype>{
      for (final event in events) event.id: event,
    };
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  static List<ArcAdminMapMarkerSubtype> locationsForMap(String? mapName) {
    final map = _mapForName(mapName);
    if (map == null) return location;
    return _dedupe([
      ...location.where((item) => item.kind == ArcAdminMapMarkerKind.poi),
      for (final region in map.regions)
        ArcAdminMapMarkerSubtype(
          id: 'region_${region.id}',
          label: region.name,
          kind: ArcAdminMapMarkerKind.poi,
          groupLabel: '${map.displayName} Regions',
        ),
      for (final poi in map.pois)
        ArcAdminMapMarkerSubtype(
          id: 'poi_${poi.id}',
          label: poi.name,
          kind: ArcAdminMapMarkerKind.poi,
          groupLabel: '${map.displayName} POIs',
        ),
      for (final spawn in map.spawnRegions)
        ArcAdminMapMarkerSubtype(
          id: 'spawn_${spawn.id}',
          label: spawn.name,
          kind: ArcAdminMapMarkerKind.poi,
          groupLabel: '${map.displayName} Spawns',
        ),
    ]);
  }

  static List<ArcAdminMapMarkerSubtype> extractionsForMap(String? mapName) {
    final map = _mapForName(mapName);
    if (map == null) {
      return const [
        ArcAdminMapMarkerSubtype(
          id: 'extraction',
          label: 'Extraction',
          kind: ArcAdminMapMarkerKind.extraction,
          groupLabel: 'Locations',
        ),
      ];
    }
    return _dedupe([
      for (final extraction in map.extractions)
        ArcAdminMapMarkerSubtype(
          id: 'extraction_${extraction.id}',
          label: extraction.name,
          kind: ArcAdminMapMarkerKind.extraction,
          groupLabel: '${map.displayName} Extractions',
        ),
    ]);
  }

  static List<ArcAdminMapMarkerSubtype> hatchesForMap(String? mapName) {
    final map = _mapForName(mapName);
    if (map == null) {
      return const [
        ArcAdminMapMarkerSubtype(
          id: 'raider_hatch',
          label: 'Raider Hatch',
          kind: ArcAdminMapMarkerKind.raiderHatch,
          groupLabel: 'Locations',
        ),
      ];
    }
    return _dedupe([
      for (final hatch in map.hatches)
        ArcAdminMapMarkerSubtype(
          id: 'hatch_${hatch.id}',
          label: hatch.name,
          kind: ArcAdminMapMarkerKind.raiderHatch,
          groupLabel: '${map.displayName} Raider Hatches',
        ),
    ]);
  }

  static List<ArcAdminMapMarkerSubtype> layerTransitionsForMap(
    ArcAdminMapMarkerKind kind,
    String? mapName,
  ) {
    final map = _mapForName(mapName);
    final fallbackLabel = kind == ArcAdminMapMarkerKind.surfaceTransition
        ? 'Surface Transition'
        : 'Underground Transition';
    final fallbackId = kind == ArcAdminMapMarkerKind.surfaceTransition
        ? 'surface_transition'
        : 'underground_transition';
    if (map == null) {
      return [
        ArcAdminMapMarkerSubtype(
          id: fallbackId,
          label: fallbackLabel,
          kind: kind,
          groupLabel: 'Locations',
        ),
      ];
    }
    final layers = kind == ArcAdminMapMarkerKind.surfaceTransition
        ? const [ArcRaidMapLayer.surface]
        : const [ArcRaidMapLayer.underground, ArcRaidMapLayer.transition];
    return _dedupe([
      for (final layer in map.availableLayers.where(layers.contains))
        ArcAdminMapMarkerSubtype(
          id: '${layer.name}_access',
          label: '${layer.label} Access',
          kind: kind,
          groupLabel: '${map.displayName} Levels',
        ),
    ]);
  }

  static String slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static String _mapKey(String? value) {
    final normalized = slug(value ?? '');
    return switch (normalized) {
      'dam' ||
      'the_dam' ||
      'dam_battleground' ||
      'dam_battlegrounds' ||
      'the_dam_battlegrounds' => 'dam_battlegrounds',
      'spaceport' || 'the_spaceport' || 'acerra_spaceport' => 'spaceport',
      'buried_city' => 'buried_city',
      'blue_gate' || 'the_blue_gate' => 'blue_gate',
      'stella_montis' => 'stella_montis',
      'riven_tides' => 'riven_tides',
      _ => normalized,
    };
  }

  static ArcRaidMap? _mapForName(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    return ArcRaidIntelligenceSeedData.mapById(raw);
  }

  static List<ArcAdminMapMarkerSubtype> _dedupe(
    Iterable<ArcAdminMapMarkerSubtype> values,
  ) {
    final seen = <String>{};
    final result = <ArcAdminMapMarkerSubtype>[];
    for (final value in values) {
      if (!seen.add('${value.kind.name}:${value.id}')) continue;
      result.add(value);
    }
    return result;
  }

  static ArcAdminMapMarkerKind _kindForContainer(String id) {
    return switch (id) {
      'field_crate' => ArcAdminMapMarkerKind.fieldCrate,
      'first_wave_cache' => ArcAdminMapMarkerKind.firstWaveCache,
      'locked_room' || 'breachable_door' => ArcAdminMapMarkerKind.lockedRoom,
      'raider_cache' || 'hidden_cache' => ArcAdminMapMarkerKind.raiderCache,
      'security_locker' ||
      'black_crate_security_container' => ArcAdminMapMarkerKind.securityRoom,
      'weapon_cache' => ArcAdminMapMarkerKind.weaponCache,
      _ => ArcAdminMapMarkerKind.lootContainer,
    };
  }

  static String _groupForKind(ArcAdminMapMarkerKind kind) {
    return switch (kind) {
      ArcAdminMapMarkerKind.mapEvent => 'Events',
      ArcAdminMapMarkerKind.questLocation => 'Quests',
      ArcAdminMapMarkerKind.resourceNode ||
      ArcAdminMapMarkerKind.naturalResource => 'Nature',
      ArcAdminMapMarkerKind.arcSpawn ||
      ArcAdminMapMarkerKind.arcThreat => 'ARC',
      ArcAdminMapMarkerKind.hazard ||
      ArcAdminMapMarkerKind.extractionDanger => 'Hazards',
      ArcAdminMapMarkerKind.weaponCase ||
      ArcAdminMapMarkerKind.weaponCache ||
      ArcAdminMapMarkerKind.firstWaveCache ||
      ArcAdminMapMarkerKind.raiderCache ||
      ArcAdminMapMarkerKind.fieldCrate ||
      ArcAdminMapMarkerKind.lootContainer ||
      ArcAdminMapMarkerKind.containerCluster ||
      ArcAdminMapMarkerKind.lockedRoom ||
      ArcAdminMapMarkerKind.securityRoom ||
      ArcAdminMapMarkerKind.highValueLoot ||
      ArcAdminMapMarkerKind.keyRequiredLocation => 'Containers',
      _ => 'Locations',
    };
  }

  static String _labelFromSlug(String value) {
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part.length == 1
              ? part.toUpperCase()
              : '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}
