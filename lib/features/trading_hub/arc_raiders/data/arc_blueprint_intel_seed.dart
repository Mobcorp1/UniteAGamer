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
        return 'Starter Hint';
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

  static ArcBlueprintHintData resolve(ArcBlueprint blueprint) {
    final categorySeed = _categorySeeds[blueprint.category] ?? const _HintSeed();
    final specificSeed = _specificSeeds[blueprint.id];

    return ArcBlueprintHintData(
      blueprintId: blueprint.id,
      tip: specificSeed?.tip ?? blueprint.intelHint,
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

  static List<String> _mergeUnique(List<String> base, List<String>? overrides) {
    final values = <String>{...base};
    if (overrides != null) values.addAll(overrides);
    final out = values.toList(growable: false)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }

  static const Map<String, _HintSeed> _categorySeeds = {
    'Attachments': _HintSeed(
      likelyContainers: ['Weapon Cases', 'Weapon Lockers', 'Duffel Bags', 'Residential Containers'],
      likelyMaps: ['Blue Gate', 'Buried City', 'Dam Battlegrounds'],
      bestConditions: ['Night Raid', 'Cold Snap', 'Electromagnetic Storm'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Weapons': _HintSeed(
      likelyContainers: ['Raider Caches', 'Weapon Cases', 'Locked Rooms', 'High-Value Containers'],
      likelyMaps: ['Dam Battlegrounds', 'Blue Gate', 'Spaceport'],
      bestConditions: ['Night Raid', 'Matriarch', 'Harvester'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Gadgets': _HintSeed(
      likelyContainers: ['Military Crates', 'Tool Lockers', 'Industrial Containers'],
      likelyMaps: ['Dam Battlegrounds', 'Spaceport', 'Stella Montis'],
      bestConditions: ['Night Raid', 'Electromagnetic Storm'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Utility': _HintSeed(
      likelyContainers: ['Lockers', 'Duffel Bags', 'Trash Containers', 'Civilian Containers'],
      likelyMaps: ['Blue Gate', 'Buried City', 'Dam Battlegrounds'],
      bestConditions: ['Night Raid', 'Cold Snap'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Consumables': _HintSeed(
      likelyContainers: ['Medical Cabinets', 'Support Containers', 'Clinic Rooms'],
      likelyMaps: ['Buried City', 'Stella Montis', 'Blue Gate'],
      bestConditions: ['Night Raid', 'Cold Snap'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Support': _HintSeed(
      likelyContainers: ['Medical Cabinets', 'Support Containers', 'Clinic Rooms'],
      likelyMaps: ['Buried City', 'Stella Montis'],
      bestConditions: ['Night Raid', 'Cold Snap'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Parts': _HintSeed(
      likelyContainers: ['Industrial Crates', 'Tool Lockers', 'Mechanical Containers'],
      likelyMaps: ['Dam Battlegrounds', 'Spaceport', 'Stella Montis'],
      bestConditions: ['Electromagnetic Storm', 'Hurricane', 'Night Raid'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Grenades': _HintSeed(
      likelyContainers: ['Military Crates', 'Tactical Cases', 'Industrial Containers'],
      likelyMaps: ['Dam Battlegrounds', 'Spaceport', 'Buried City'],
      bestConditions: ['Night Raid', 'Matriarch'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Tactical Mods': _HintSeed(
      likelyContainers: ['Support Containers', 'Weapon Cases', 'Locked Rooms'],
      likelyMaps: ['Blue Gate', 'Dam Battlegrounds', 'Stella Montis'],
      bestConditions: ['Night Raid', 'Cold Snap'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Combat Mods': _HintSeed(
      likelyContainers: ['Weapon Cases', 'Locked Rooms', 'Raider Caches'],
      likelyMaps: ['Dam Battlegrounds', 'Blue Gate', 'Spaceport'],
      bestConditions: ['Night Raid', 'Electromagnetic Storm'],
      confidence: ArcIntelConfidence.starter,
    ),
    'Looting Mods': _HintSeed(
      likelyContainers: ['Locked Rooms', 'Raider Caches', 'High-Value Containers'],
      likelyMaps: ['Blue Gate', 'Spaceport', 'Dam Battlegrounds'],
      bestConditions: ['Night Raid', 'Matriarch', 'Harvester'],
      confidence: ArcIntelConfidence.starter,
    ),
  };

  static const Map<String, _HintSeed> _specificSeeds = {
    'stable-stock-iii': _HintSeed(
      tip: 'Likely attachment-pool drop. Test residential containers, lockers, and weapon cases first, then compare Night Raid runs against Cold Snap routes.',
      likelyContainers: ['Residential Containers', 'Lockers', 'Weapon Cases'],
      likelyMaps: ['Blue Gate', 'Buried City', 'Dam Battlegrounds'],
      bestConditions: ['Night Raid', 'Cold Snap'],
      confidence: ArcIntelConfidence.community,
    ),
    'aphelion': _HintSeed(
      tip: 'This one is boss-linked rather than general loot-pool hunting. Prioritize Matriarch event runs and secure the boss core immediately.',
      likelyMaps: ['Blue Gate', 'Dam Battlegrounds', 'Spaceport'],
      bestConditions: ['Matriarch'],
      specialSource: 'Matriarch boss core. Known Matriarch locations include The Breach, Launch Towers, and the Blue Gate area between Ridgeline and Warehouse Complex.',
      confidence: ArcIntelConfidence.confirmed,
    ),
    'anvil': _HintSeed(
      tip: 'Best tested route is the raider container pocket on Dam Battlegrounds. If that route is contested, Buried City backup runs are worth testing.',
      likelyContainers: ['Raider Containers', 'Weapon Cases', 'Raider Backpacks'],
      likelyMaps: ['Dam Battlegrounds', 'Buried City'],
      bestConditions: ['Night Raid'],
      specialSource: 'Strong reported route: Dam Battlegrounds under the raised highway between Raider Outpost East and East Broken Bridge. Alt lead: Marano Station on Buried City.',
      confidence: ArcIntelConfidence.confirmed,
    ),
    'shotgun-silencer': _HintSeed(
      tip: 'Can still be tracked through community reports, but there is also a project-reward path worth prioritizing if you are progressing permanent unlocks.',
      likelyMaps: ['Spaceport', 'Buried City', 'Stella Montis'],
      specialSource: 'Also appears as a Trophy Display project reward.',
      confidence: ArcIntelConfidence.confirmed,
    ),
    'light-gun-parts': _HintSeed(
      tip: 'Industrial and weapon-part routes are still worth testing, but keep project rewards in mind because this one has a progression unlock path too.',
      specialSource: 'Also appears as a Trophy Display project reward.',
      confidence: ArcIntelConfidence.confirmed,
    ),
    'snap-hook': _HintSeed(
      tip: 'Keep this flagged as both a utility-route chase and a progression reward. If report volume is low, lean on the project path first.',
      likelyMaps: ['Blue Gate', 'Dam Battlegrounds'],
      bestConditions: ['Electromagnetic Storm'],
      specialSource: 'Also appears as a Trophy Display project reward.',
      confidence: ArcIntelConfidence.confirmed,
    ),
    'wolfpack': _HintSeed(
      tip: 'Prioritize Night Raid testing and compare rare weapon routes rather than broad container farming. This one is worth validating through community finds.',
      bestConditions: ['Night Raid'],
      confidence: ArcIntelConfidence.community,
    ),
    'equalizer': _HintSeed(
      tip: 'Treat this as a high-end chase blueprint. Focus boss/event-heavy sessions and only commit hard grind time when stronger community reports stack up.',
      likelyMaps: ['Dam Battlegrounds', 'Spaceport'],
      bestConditions: ['Harvester', 'Matriarch'],
      confidence: ArcIntelConfidence.community,
    ),
    'jupiter': _HintSeed(
      tip: 'This one is worth tracking through event-heavy weapon routes. If you get Matriarch-linked reports, prioritize them over generic weapon-case runs.',
      likelyMaps: ['Blue Gate', 'Dam Battlegrounds', 'Spaceport'],
      bestConditions: ['Matriarch'],
      confidence: ArcIntelConfidence.community,
    ),
    'vita-spray': _HintSeed(
      tip: 'Start with medical and support interiors. Compare hospital-style spaces against cleaner high-value research routes, especially on Night Raid.',
      likelyContainers: ['Medical Cabinets', 'Support Containers', 'Clinic Rooms'],
      likelyMaps: ['Buried City', 'Stella Montis'],
      bestConditions: ['Night Raid', 'Cold Snap'],
      confidence: ArcIntelConfidence.community,
    ),
    'defibrillator': _HintSeed(
      tip: 'Best treated as a support/medical chase. Test medical cabinets and support rooms before broad container routes.',
      likelyContainers: ['Medical Cabinets', 'Support Containers'],
      likelyMaps: ['Buried City', 'Stella Montis'],
      bestConditions: ['Night Raid', 'Cold Snap'],
      confidence: ArcIntelConfidence.community,
    ),
    'complex-gun-parts': _HintSeed(
      tip: 'Aim at industrial and mechanical loot routes first. This one is a good benchmark for Dam and Spaceport comparison testing.',
      likelyContainers: ['Industrial Crates', 'Tool Lockers', 'Mechanical Containers'],
      likelyMaps: ['Dam Battlegrounds', 'Spaceport', 'Stella Montis'],
      bestConditions: ['Electromagnetic Storm', 'Hurricane'],
      confidence: ArcIntelConfidence.community,
    ),
    'medium-gun-parts': _HintSeed(
      tip: 'Good test item for route quality. Run short industrial loops and compare Dam versus Spaceport before widening the search.',
      confidence: ArcIntelConfidence.community,
    ),
    'heavy-gun-parts': _HintSeed(
      tip: 'Stick to industrial and mechanical interiors. If you are not seeing parts there, your route is probably too broad.',
      confidence: ArcIntelConfidence.community,
    ),
    'hullcracker': _HintSeed(
      tip: 'Legendary chase. Focus rare-weapon routes, Raider caches, and event-active sessions rather than normal broad looting.',
      likelyMaps: ['Dam Battlegrounds', 'Blue Gate', 'Spaceport'],
      bestConditions: ['Matriarch', 'Harvester', 'Night Raid'],
      confidence: ArcIntelConfidence.community,
    ),
    'showstopper': _HintSeed(
      tip: 'Another high-end weapon chase. Only trust stronger report clusters and keep rare cache routes at the center of your testing.',
      confidence: ArcIntelConfidence.community,
    ),
    'venator': _HintSeed(
      tip: 'Treat as a confidence-based chase item. Event-active runs and confirmed cache reports matter more than generic weapon-case farming.',
      confidence: ArcIntelConfidence.community,
    ),
    'vulcano': _HintSeed(
      tip: 'High-tier weapon route. Test rare loot zones and boss/event sessions first, then compare against locked-room runs.',
      confidence: ArcIntelConfidence.community,
    ),
    'il-toro': _HintSeed(
      tip: 'Heavy legendary chase. Start with the best rare-weapon routes you know and only broaden out after a few event sessions.',
      confidence: ArcIntelConfidence.community,
    ),
  };
}
