import 'package:flutter/foundation.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';

enum ArcIntelConfidence { starter, community, confirmed }

@immutable
class ArcBlueprintHintData {
  const ArcBlueprintHintData({
    required this.blueprintId,
    required this.tip,
    required this.likelyContainers,
    required this.likelyMaps,
    required this.bestConditions,
    required this.confidence,
    this.specialSource,
  });

  final String blueprintId;
  final String tip;
  final List<String> likelyContainers;
  final List<String> likelyMaps;
  final List<String> bestConditions;
  final ArcIntelConfidence confidence;
  final String? specialSource;

  String get confidenceLabel {
    switch (confidence) {
      case ArcIntelConfidence.starter:
        return 'Seeded Rule';
      case ArcIntelConfidence.community:
        return 'Community Led';
      case ArcIntelConfidence.confirmed:
        return 'Confirmed';
    }
  }
}

@immutable
class _HintSeed {
  const _HintSeed({
    this.tip,
    this.likelyContainers = const <String>[],
    this.likelyMaps = const <String>[],
    this.bestConditions = const <String>[],
    this.specialSource,
    this.confidence,
  });

  final String? tip;
  final List<String> likelyContainers;
  final List<String> likelyMaps;
  final List<String> bestConditions;
  final String? specialSource;
  final ArcIntelConfidence? confidence;
}

class ArcBlueprintIntelLibrary {
  ArcBlueprintIntelLibrary._();

  static const List<String> allMapMarker = <String>['All maps'];

  static ArcBlueprintHintData resolve(ArcBlueprint blueprint) {
    final categorySeed =
        _categorySeeds[blueprint.category] ?? const _HintSeed();
    final specificSeed = _specificSeeds[blueprint.id];

    return ArcBlueprintHintData(
      blueprintId: blueprint.id,
      tip: specificSeed?.tip ?? categorySeed.tip ?? blueprint.intelHint,
      likelyContainers: _mergeUnique(
        categorySeed.likelyContainers,
        specificSeed?.likelyContainers,
      ),
      likelyMaps: _mergeUnique(
        categorySeed.likelyMaps,
        specificSeed?.likelyMaps,
      ),
      bestConditions: _mergeUnique(
        categorySeed.bestConditions,
        specificSeed?.bestConditions,
      ),
      specialSource: specificSeed?.specialSource ?? categorySeed.specialSource,
      confidence:
          specificSeed?.confidence ??
          categorySeed.confidence ??
          ArcIntelConfidence.starter,
    );
  }

  static bool isAllMaps(List<String> maps) {
    return maps.isEmpty ||
        maps.any(
          (map) =>
              map.toLowerCase() == 'all maps' || map.toLowerCase() == 'all',
        );
  }

  static bool isAnyCondition(String condition) {
    final value = condition.toLowerCase();
    return value == 'any' || value == 'any condition' || value == 'day raid';
  }

  static List<String> playableConditions(List<String> conditions) {
    return conditions
        .where(
          (condition) =>
              !isAnyCondition(condition) && condition.toLowerCase() != 'quest',
        )
        .toList(growable: false);
  }

  static List<String> _mergeUnique(List<String> base, List<String>? overrides) {
    final values = <String>{...base};
    if (overrides != null) values.addAll(overrides);
    final out = values.toList(growable: false)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }

  static const Map<String, _HintSeed> _categorySeeds = {
    'Attachments': _HintSeed(
      tip:
          'Attachment baseline. Use seeded container/category rules first, then let community intel narrow the best map and route.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Weapons': _HintSeed(
      tip:
          'Weapon baseline. Use seeded raider-container rules first, then let community intel narrow the best route.',
      likelyContainers: <String>['Raider Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Gadgets': _HintSeed(
      tip:
          'Gadget baseline. Use seeded industrial/general loot rules first, then let community intel narrow the best route.',
      likelyContainers: <String>['Industrial Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Utility': _HintSeed(
      tip: 'Utility baseline. Broad loot until community intel narrows it.',
      likelyContainers: <String>['General Containers', 'Utility Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Consumables': _HintSeed(
      tip: 'Consumable baseline. Search medical/support containers first.',
      likelyContainers: <String>['Medical Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Support': _HintSeed(
      tip: 'Support baseline. Search medical/support containers first.',
      likelyContainers: <String>['Medical Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Parts': _HintSeed(
      tip: 'Parts baseline. Search raider and weapon-part containers first.',
      likelyContainers: <String>['Raider Containers', 'Weapon Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Grenades': _HintSeed(
      tip:
          'Grenade baseline. Search industrial/electrical/tactical loot first depending on grenade type.',
      likelyContainers: <String>[
        'Industrial Containers',
        'Electrical Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Deployables': _HintSeed(
      tip:
          'Deployable baseline. Use the seeded condition rule first, then let community intel narrow exact containers.',
      likelyContainers: <String>['General Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Tactical Mods': _HintSeed(
      tip:
          'Mk.3 tactical baseline. Prioritise high-tier medical/security routes, especially during Night Raid.',
      likelyContainers: <String>[
        'Medical Containers',
        'Security Containers',
        'High-Tier Containers',
      ],
      likelyMaps: <String>['Stella Montis', 'The Blue Gate'],
      bestConditions: <String>['Night Raid'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Combat Mods': _HintSeed(
      tip:
          'Mk.3 combat baseline. Prioritise high-tier medical/security routes, especially during Night Raid.',
      likelyContainers: <String>[
        'Medical Containers',
        'Security Containers',
        'High-Tier Containers',
      ],
      likelyMaps: <String>['Stella Montis', 'The Blue Gate'],
      bestConditions: <String>['Night Raid'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Looting Mods': _HintSeed(
      tip:
          'Mk.3 looting baseline. Search medical/security routes and high-tier containers, with Night Raid as the safest seeded boost.',
      likelyContainers: <String>[
        'Medical Containers',
        'Security Containers',
        'High-Tier Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Night Raid'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Riven Tides': _HintSeed(
      tip:
          'Riven Tides baseline. Keep map-linked to Riven Tides; Beachcombing is a boost, not a requirement.',
      likelyContainers: <String>[
        'Standard Loot Containers',
        'Crates',
        'Cabinets',
        'Drawers',
        'Green Containers',
      ],
      likelyMaps: <String>['Riven Tides'],
      bestConditions: <String>['Beachcombing'],
      confidence: ArcIntelConfidence.starter,
    ),
  };

  static const Map<String, _HintSeed> _specificSeeds = {
    'angled-grip-ii': _HintSeed(
      tip:
          'Standard attachment baseline. Search residential/attachment containers on any map.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'angled-grip-iii': _HintSeed(
      tip:
          'Condition-boosted attachment blueprint. Start with residential/attachment loot and prioritise storm, locked-gate, and night windows.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>[
        'Electromagnetic Storm',
        'Locked Gate',
        'Night Raid',
      ],
      confidence: ArcIntelConfidence.starter,
    ),
    'anvil': _HintSeed(
      tip: 'Weapon blueprint baseline. Search raider containers on any map.',
      likelyContainers: <String>['Raider Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'aphelion': _HintSeed(
      tip:
          'Stella Montis baseline. Treat as Stella Montis-only until community reports prove otherwise.',
      likelyContainers: <String>['General Containers', 'High-Value Containers'],
      likelyMaps: <String>['Stella Montis'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'barricade-kit': _HintSeed(
      tip:
          'Electrical utility baseline. Search electrical containers on any map.',
      likelyContainers: <String>['Electrical Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'bettina': _HintSeed(
      tip: 'Weapon blueprint baseline. Search raider containers on any map.',
      likelyContainers: <String>['Raider Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'blaze-grenade': _HintSeed(
      tip:
          'Industrial grenade baseline. Search industrial containers on any map.',
      likelyContainers: <String>['Industrial Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'blue-light-stick': _HintSeed(
      tip:
          'Common utility baseline. Can appear broadly, so planner should not force a single map or event.',
      likelyContainers: <String>['General Containers', 'Utility Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'bobcat': _HintSeed(
      tip:
          'Condition-linked weapon baseline. Prioritise Hurricane and Locked Gate windows; First Wave Cache is a strong source when available.',
      likelyContainers: <String>['First Wave Cache', 'General Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Hurricane', 'Locked Gate'],
      confidence: ArcIntelConfidence.starter,
    ),
    'burletta': _HintSeed(
      tip:
          'Quest baseline. Treat as quest/progression source rather than normal loot until app intel confirms repeat drops.',
      likelyContainers: <String>['Quest Reward'],
      likelyMaps: <String>[],
      bestConditions: <String>['Quest'],
      specialSource: 'Industrial Espionage quest.',
      confidence: ArcIntelConfidence.starter,
    ),
    'canto': _HintSeed(
      tip:
          'Hurricane baseline. Prioritise Hurricane windows and First Wave Cache routes.',
      likelyContainers: <String>['First Wave Cache'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Hurricane'],
      confidence: ArcIntelConfidence.starter,
    ),
    'combat-mk-3-aggressive': _HintSeed(
      tip:
          'Mk.3 augment baseline. Prioritise Stella Montis and Blue Gate, with Night Raid as the best seeded boost.',
      likelyContainers: <String>[
        'Medical Containers',
        'Security Containers',
        'High-Tier Containers',
      ],
      likelyMaps: <String>['Stella Montis', 'The Blue Gate'],
      bestConditions: <String>['Night Raid'],
      confidence: ArcIntelConfidence.starter,
    ),
    'combat-mk-3-flanking': _HintSeed(
      tip:
          'Mk.3 augment baseline. Prioritise Stella Montis and Blue Gate, with Night Raid as the best seeded boost.',
      likelyContainers: <String>[
        'Medical Containers',
        'Security Containers',
        'High-Tier Containers',
      ],
      likelyMaps: <String>['Stella Montis', 'The Blue Gate'],
      bestConditions: <String>['Night Raid'],
      confidence: ArcIntelConfidence.starter,
    ),
    'compensator-ii': _HintSeed(
      tip:
          'Standard attachment baseline. Search residential/attachment containers on any map.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'compensator-iii': _HintSeed(
      tip:
          'Condition-boosted attachment baseline. Search residential/attachment containers during storm, locked-gate, or night windows.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>[
        'Electromagnetic Storm',
        'Locked Gate',
        'Night Raid',
      ],
      confidence: ArcIntelConfidence.starter,
    ),
    'complex-gun-parts': _HintSeed(
      tip: 'Gun-parts baseline. Search raider/weapon-part routes on any map.',
      likelyContainers: <String>['Raider Containers', 'Weapon Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'crash-mat': _HintSeed(
      tip:
          'Riven Tides baseline. Map-linked to Riven Tides; Beachcombing is a useful boost, not a requirement.',
      likelyContainers: <String>[
        'Standard Loot Containers',
        'Crates',
        'Cabinets',
        'Drawers',
        'Green Containers',
      ],
      likelyMaps: <String>['Riven Tides'],
      bestConditions: <String>['Beachcombing'],
      confidence: ArcIntelConfidence.starter,
    ),
    'deadline': _HintSeed(
      tip:
          'Stella Montis baseline. Treat as Stella Montis-only until community reports prove otherwise.',
      likelyContainers: <String>['General Containers', 'High-Value Containers'],
      likelyMaps: <String>['Stella Montis'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'defibrillator': _HintSeed(
      tip: 'Medical support baseline. Search medical containers on any map.',
      likelyContainers: <String>['Medical Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'dolabra': _HintSeed(
      tip:
          'Close Scrutiny baseline. This is source-linked to ARC Assessor during Close Scrutiny; do not route it through normal generic loot.',
      likelyContainers: <String>['ARC Assessor'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Close Scrutiny'],
      specialSource: 'ARC Assessor source during Close Scrutiny.',
      confidence: ArcIntelConfidence.starter,
    ),
    'equalizer': _HintSeed(
      tip:
          'Harvester-linked baseline. Prioritise Harvester windows and Harvester sources.',
      likelyContainers: <String>['Harvester'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Harvester'],
      specialSource: 'Harvester source.',
      confidence: ArcIntelConfidence.starter,
    ),
    'explosive-mine': _HintSeed(
      tip:
          'Industrial gadget baseline. Search industrial containers on any map.',
      likelyContainers: <String>['Industrial Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'extended-barrel': _HintSeed(
      tip:
          'Condition-boosted attachment baseline. Search residential/attachment containers during storm, locked-gate, or night windows.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>[
        'Electromagnetic Storm',
        'Locked Gate',
        'Night Raid',
      ],
      confidence: ArcIntelConfidence.starter,
    ),
    'extended-light-mag-ii': _HintSeed(
      tip:
          'Standard attachment baseline. Search residential/attachment containers on any map.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'extended-light-mag-iii': _HintSeed(
      tip:
          'Condition-boosted attachment baseline. Search residential/attachment containers during storm, locked-gate, or night windows.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>[
        'Electromagnetic Storm',
        'Locked Gate',
        'Night Raid',
      ],
      confidence: ArcIntelConfidence.starter,
    ),
    'extended-medium-mag-ii': _HintSeed(
      tip:
          'Standard attachment baseline. Search residential/attachment containers on any map; Night Raid can still be used as a general boost.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any', 'Night Raid'],
      confidence: ArcIntelConfidence.starter,
    ),
    'extended-medium-mag-iii': _HintSeed(
      tip:
          'Condition-boosted attachment baseline. Search residential/attachment containers during storm, locked-gate, or night windows.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>[
        'Electromagnetic Storm',
        'Locked Gate',
        'Night Raid',
      ],
      confidence: ArcIntelConfidence.starter,
    ),
    'extended-shotgun-mag-ii': _HintSeed(
      tip:
          'Standard attachment baseline. Search residential/attachment containers on any map.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'extended-shotgun-mag-iii': _HintSeed(
      tip:
          'Condition-boosted attachment blueprint. Use the seeded baseline first: residential/attachment loot, then prioritise active storm, locked-gate, or night windows until community reports narrow it.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>[
        'Electromagnetic Storm',
        'Locked Gate',
        'Night Raid',
      ],
      confidence: ArcIntelConfidence.starter,
    ),
    'fireworks-box': _HintSeed(
      tip:
          'Cold Snap baseline. Prioritise Cold Snap when available; otherwise keep this as broad utility intel until reports narrow it.',
      likelyContainers: <String>['General Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Cold Snap'],
      specialSource: 'Also appears via Test Case quest.',
      confidence: ArcIntelConfidence.starter,
    ),
    'gas-mine': _HintSeed(
      tip:
          'Stella Montis baseline. Treat as Stella Montis-only until community reports prove otherwise.',
      likelyContainers: <String>['General Containers', 'High-Value Containers'],
      likelyMaps: <String>['Stella Montis'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'green-light-stick': _HintSeed(
      tip:
          'Common utility baseline. Can appear broadly, so planner should not force a single map or event.',
      likelyContainers: <String>['General Containers', 'Utility Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'heavy-gun-parts': _HintSeed(
      tip: 'Gun-parts baseline. Search raider/weapon-part routes on any map.',
      likelyContainers: <String>['Raider Containers', 'Weapon Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'hullcracker': _HintSeed(
      tip:
          'Quest baseline. Treat as quest/progression source rather than normal loot until app intel confirms repeat drops.',
      likelyContainers: <String>['Quest Reward'],
      likelyMaps: <String>[],
      bestConditions: <String>['Quest'],
      specialSource: "The Major's Footlocker quest.",
      confidence: ArcIntelConfidence.starter,
    ),
    'il-toro': _HintSeed(
      tip: 'Weapon blueprint baseline. Search raider containers on any map.',
      likelyContainers: <String>['Raider Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'jolt-mine': _HintSeed(
      tip:
          'Industrial gadget baseline. Search industrial containers on any map.',
      likelyContainers: <String>['Industrial Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'jupiter': _HintSeed(
      tip:
          'Harvester-linked baseline. Prioritise Harvester windows and Harvester sources.',
      likelyContainers: <String>['Harvester'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Harvester'],
      specialSource: 'Harvester source.',
      confidence: ArcIntelConfidence.starter,
    ),
    'light-gun-parts': _HintSeed(
      tip: 'Gun-parts baseline. Search raider/weapon-part routes on any map.',
      likelyContainers: <String>['Raider Containers', 'Weapon Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'lightweight-stock': _HintSeed(
      tip:
          'Condition-boosted attachment baseline. Search residential/attachment containers during storm, locked-gate, or night windows.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>[
        'Electromagnetic Storm',
        'Locked Gate',
        'Night Raid',
      ],
      confidence: ArcIntelConfidence.starter,
    ),
    'looting-mk-3-safekeeper': _HintSeed(
      tip:
          'Mk.3 looting augment baseline. Search medical/security containers on any map, with Night Raid as a useful seeded boost.',
      likelyContainers: <String>[
        'Medical Containers',
        'Security Containers',
        'High-Tier Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Night Raid'],
      confidence: ArcIntelConfidence.starter,
    ),
    'looting-mk-3-survivor': _HintSeed(
      tip:
          'Mk.3 looting augment baseline. Search medical/security containers on any map, with Night Raid as a useful seeded boost.',
      likelyContainers: <String>[
        'Medical Containers',
        'Security Containers',
        'High-Tier Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Night Raid'],
      confidence: ArcIntelConfidence.starter,
    ),
    'lure-grenade': _HintSeed(
      tip:
          'Quest baseline. Treat as quest/progression source rather than normal loot until app intel confirms repeat drops.',
      likelyContainers: <String>['Quest Reward'],
      likelyMaps: <String>[],
      bestConditions: <String>['Quest'],
      specialSource: 'Greasing Her Palms quest.',
      confidence: ArcIntelConfidence.starter,
    ),
    'medium-gun-parts': _HintSeed(
      tip: 'Gun-parts baseline. Search raider/weapon-part routes on any map.',
      likelyContainers: <String>['Raider Containers', 'Weapon Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'muzzle-brake-ii': _HintSeed(
      tip:
          'Standard attachment baseline. Search residential/attachment containers on any map.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'muzzle-brake-iii': _HintSeed(
      tip:
          'Condition-boosted attachment blueprint. Search residential/attachment containers during storm, locked-gate, or night windows.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>[
        'Electromagnetic Storm',
        'Locked Gate',
        'Night Raid',
      ],
      confidence: ArcIntelConfidence.starter,
    ),
    'osprey': _HintSeed(
      tip: 'Weapon blueprint baseline. Search raider containers on any map.',
      likelyContainers: <String>['Raider Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'padded-stock': _HintSeed(
      tip:
          'Condition-boosted attachment baseline. Search residential/attachment containers during storm, locked-gate, night, or hidden bunker windows.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>[
        'Electromagnetic Storm',
        'Locked Gate',
        'Night Raid',
        'Hidden Bunker',
      ],
      confidence: ArcIntelConfidence.starter,
    ),
    'powered-descender': _HintSeed(
      tip:
          'Riven Tides baseline. Map-linked to Riven Tides; Beachcombing is a useful boost, not a requirement.',
      likelyContainers: <String>[
        'Standard Loot Containers',
        'Crates',
        'Cabinets',
        'Drawers',
        'Green Containers',
      ],
      likelyMaps: <String>['Riven Tides'],
      bestConditions: <String>['Beachcombing'],
      confidence: ArcIntelConfidence.starter,
    ),
    'pulse-mine': _HintSeed(
      tip:
          'Stella Montis baseline. Treat as a Stella Montis blueprint until community reports prove wider drops.',
      likelyContainers: <String>['General Containers', 'High-Value Containers'],
      likelyMaps: <String>['Stella Montis'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'red-light-stick': _HintSeed(
      tip:
          'Common utility baseline. Can appear broadly, so planner should not force a single map or event.',
      likelyContainers: <String>['General Containers', 'Utility Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'remote-raider-flare': _HintSeed(
      tip:
          'Electrical utility baseline. Search electrical containers on any map.',
      likelyContainers: <String>['Electrical Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'seeker-grenade': _HintSeed(
      tip:
          'Stella Montis baseline. Treat as Stella Montis-only until community reports prove otherwise.',
      likelyContainers: <String>['General Containers', 'High-Value Containers'],
      likelyMaps: <String>['Stella Montis'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'shotgun-choke-ii': _HintSeed(
      tip:
          'Standard attachment baseline. Search residential/attachment containers on any map.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'shotgun-choke-iii': _HintSeed(
      tip:
          'Condition-boosted attachment baseline. Search residential/attachment containers during storm, locked-gate, or night windows.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>[
        'Electromagnetic Storm',
        'Locked Gate',
        'Night Raid',
      ],
      confidence: ArcIntelConfidence.starter,
    ),
    'shotgun-silencer': _HintSeed(
      tip:
          'Condition-boosted attachment baseline. Search residential/attachment containers during storm, locked-gate, night, or hidden bunker windows.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>[
        'Electromagnetic Storm',
        'Locked Gate',
        'Night Raid',
        'Hidden Bunker',
      ],
      confidence: ArcIntelConfidence.starter,
    ),
    'showstopper': _HintSeed(
      tip:
          'Industrial gadget baseline. Search industrial containers on any map.',
      likelyContainers: <String>['Industrial Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'silencer-i': _HintSeed(
      tip:
          'Standard attachment baseline. Search residential/attachment containers on any map.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'silencer-ii': _HintSeed(
      tip:
          'Standard attachment baseline. Search residential/attachment containers on any map, then let community reports refine the best route.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'smoke-grenade': _HintSeed(
      tip:
          'Residential utility baseline. Search residential containers on any map.',
      likelyContainers: <String>['Residential Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'snap-hook': _HintSeed(
      tip:
          'Electromagnetic Storm baseline. Prioritise storm windows on any map.',
      likelyContainers: <String>['General Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Electromagnetic Storm'],
      confidence: ArcIntelConfidence.starter,
    ),
    'stable-stock-ii': _HintSeed(
      tip:
          'Standard attachment baseline. Search residential/attachment containers on any map.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'stable-stock-iii': _HintSeed(
      tip:
          'Condition-boosted attachment baseline. Search residential/attachment containers during storm, locked-gate, or night windows.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>[
        'Electromagnetic Storm',
        'Locked Gate',
        'Night Raid',
      ],
      confidence: ArcIntelConfidence.starter,
    ),
    'surge-coil': _HintSeed(
      tip:
          'Electromagnetic Storm baseline. Prioritise storm windows; exact container should remain community-driven until confirmed by app reports.',
      likelyContainers: <String>['General Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Electromagnetic Storm'],
      confidence: ArcIntelConfidence.starter,
    ),
    'tactical-mk-3-defensive': _HintSeed(
      tip:
          'Mk.3 augment baseline. Prioritise Stella Montis and Blue Gate, with Night Raid as the best seeded boost.',
      likelyContainers: <String>[
        'Medical Containers',
        'Security Containers',
        'High-Tier Containers',
      ],
      likelyMaps: <String>['Stella Montis', 'The Blue Gate'],
      bestConditions: <String>['Night Raid'],
      confidence: ArcIntelConfidence.starter,
    ),
    'tactical-mk-3-healing': _HintSeed(
      tip:
          'Mk.3 augment baseline. Prioritise Stella Montis and Blue Gate, with Night Raid as the best seeded boost.',
      likelyContainers: <String>[
        'Medical Containers',
        'Security Containers',
        'High-Tier Containers',
      ],
      likelyMaps: <String>['Stella Montis', 'The Blue Gate'],
      bestConditions: <String>['Night Raid'],
      confidence: ArcIntelConfidence.starter,
    ),
    'tactical-mk-3-revival': _HintSeed(
      tip:
          'Mk.3 augment baseline. Prioritise Stella Montis and Blue Gate, with Night Raid as the best seeded boost.',
      likelyContainers: <String>[
        'Medical Containers',
        'Security Containers',
        'High-Tier Containers',
      ],
      likelyMaps: <String>['Stella Montis', 'The Blue Gate'],
      bestConditions: <String>['Night Raid'],
      confidence: ArcIntelConfidence.starter,
    ),
    'tactical-mk-3-smoke': _HintSeed(
      tip:
          'Mk.3 smoke baseline. Treat as high-tier Mk.3 loot, not Riven-only. Prioritise Stella Montis and Blue Gate with Night Raid as the strongest seeded boost.',
      likelyContainers: <String>[
        'Medical Containers',
        'Security Containers',
        'High-Tier Containers',
      ],
      likelyMaps: <String>['Stella Montis', 'The Blue Gate'],
      bestConditions: <String>['Night Raid'],
      confidence: ArcIntelConfidence.starter,
    ),
    'tagging-grenade': _HintSeed(
      tip:
          'Electrical utility baseline. Search electrical containers on any map.',
      likelyContainers: <String>['Electrical Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'tempest': _HintSeed(
      tip:
          'Condition-linked weapon baseline. Prioritise Night Raid and Hurricane windows; First Wave Cache is a strong source when available.',
      likelyContainers: <String>['Residential Containers', 'First Wave Cache'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Night Raid', 'Hurricane'],
      confidence: ArcIntelConfidence.starter,
    ),
    'torrente': _HintSeed(
      tip: 'Weapon blueprint baseline. Search raider containers on any map.',
      likelyContainers: <String>['Raider Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'trailblazer': _HintSeed(
      tip:
          'Stella Montis baseline. Treat as Stella Montis-only until community reports prove otherwise.',
      likelyContainers: <String>['General Containers', 'High-Value Containers'],
      likelyMaps: <String>['Stella Montis'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'trigger-nade': _HintSeed(
      tip:
          'Grenade baseline. Search broad grenade/tactical loot first; keep Sparks Fly quest as a progression source.',
      likelyContainers: <String>[
        'General Containers',
        'Grenade Containers',
        'Tactical Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      specialSource: 'Also appears via Sparks Fly quest.',
      confidence: ArcIntelConfidence.starter,
    ),
    'venator': _HintSeed(
      tip: 'Weapon blueprint baseline. Search raider containers on any map.',
      likelyContainers: <String>['Raider Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'vertical-grip-ii': _HintSeed(
      tip:
          'Standard attachment baseline. Search residential/attachment containers on any map.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'vertical-grip-iii': _HintSeed(
      tip:
          'Condition-boosted attachment baseline. Search residential/attachment containers during storm, locked-gate, or night windows.',
      likelyContainers: <String>[
        'Residential Containers',
        'Attachment Containers',
      ],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>[
        'Electromagnetic Storm',
        'Locked Gate',
        'Night Raid',
      ],
      confidence: ArcIntelConfidence.starter,
    ),
    'vita-shot': _HintSeed(
      tip:
          'Medical consumable baseline. Search medical containers and ARC Surveyor sources on any map.',
      likelyContainers: <String>['Medical Containers', 'ARC Surveyor'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
    'vita-spray': _HintSeed(
      tip:
          'Medical consumable baseline. Search medical containers and ARC Surveyor sources; any map unless community intel narrows it.',
      likelyContainers: <String>['Medical Containers', 'ARC Surveyor'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      specialSource: 'Also appears via Worth Your Salt quest.',
      confidence: ArcIntelConfidence.starter,
    ),
    'vulcano': _HintSeed(
      tip:
          'Condition-linked weapon baseline. Prioritise Hurricane and Hidden Bunker windows.',
      likelyContainers: <String>['First Wave Cache', 'High-Value Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Hurricane', 'Hidden Bunker'],
      confidence: ArcIntelConfidence.starter,
    ),
    'white-flag': _HintSeed(
      tip:
          'Riven Tides baseline. Map-linked to Riven Tides; Beachcombing is a useful boost, not a requirement.',
      likelyContainers: <String>[
        'Standard Loot Containers',
        'Crates',
        'Cabinets',
        'Drawers',
        'Green Containers',
      ],
      likelyMaps: <String>['Riven Tides'],
      bestConditions: <String>['Beachcombing'],
      confidence: ArcIntelConfidence.starter,
    ),
    'wolfpack': _HintSeed(
      tip: 'Night Raid baseline. Prioritise Night Raid residential routes.',
      likelyContainers: <String>['Residential Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Night Raid'],
      confidence: ArcIntelConfidence.starter,
    ),
    'yellow-light-stick': _HintSeed(
      tip:
          'Common utility baseline. Can appear broadly, so planner should not force a single map or event.',
      likelyContainers: <String>['General Containers', 'Utility Containers'],
      likelyMaps: <String>['All maps'],
      bestConditions: <String>['Any'],
      confidence: ArcIntelConfidence.starter,
    ),
  };
}
