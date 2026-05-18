import 'package:flutter/foundation.dart';

enum ArcMapConditionType { neutral, weather, event }

@immutable
class ArcMapCondition {
  const ArcMapCondition({
    required this.id,
    required this.label,
    required this.type,
    this.isMapSpecific = false,
    this.supportedMaps,
  });

  final String id;
  final String label;
  final ArcMapConditionType type;
  final bool isMapSpecific;
  final List<String>? supportedMaps;

  bool get isNeutral => type == ArcMapConditionType.neutral;
  bool get isWeather => type == ArcMapConditionType.weather;
  bool get isEvent => type == ArcMapConditionType.event;

  bool supportsMap(String mapName) {
    if (supportedMaps == null || supportedMaps!.isEmpty) return true;
    return supportedMaps!.contains(mapName);
  }
}

class ArcMapConditions {
  ArcMapConditions._();

  static const String buriedCityMap = 'Buried City';
  static const String damBattlegroundsMap = 'Dam Battlegrounds';
  static const String stellaMontisMap = 'Stella Montis';
  static const String blueGateMap = 'The Blue Gate';
  static const String spaceportMap = 'Spaceport';
  static const String rivenTidesMap = 'Riven Tides';

  static const ArcMapCondition noSpecialCondition = ArcMapCondition(
    id: 'none',
    label: 'No Map Event / Condition',
    type: ArcMapConditionType.neutral,
  );

  static const ArcMapCondition nightRaid = ArcMapCondition(
    id: 'night_raid',
    label: 'Night Raid',
    type: ArcMapConditionType.event,
  );

  static const ArcMapCondition electromagneticStorm = ArcMapCondition(
    id: 'electromagnetic_storm',
    label: 'Electromagnetic Storm',
    type: ArcMapConditionType.weather,
  );

  static const ArcMapCondition bloom = ArcMapCondition(
    id: 'bloom',
    label: 'Bloom',
    type: ArcMapConditionType.weather,
  );

  static const ArcMapCondition coldSnap = ArcMapCondition(
    id: 'cold_snap',
    label: 'Cold Snap',
    type: ArcMapConditionType.weather,
  );

  static const ArcMapCondition hurricane = ArcMapCondition(
    id: 'hurricane',
    label: 'Hurricane',
    type: ArcMapConditionType.weather,
  );

  static const ArcMapCondition closeScrutiny = ArcMapCondition(
    id: 'close_scrutiny',
    label: 'Close Scrutiny',
    type: ArcMapConditionType.event,
  );

  static const ArcMapCondition harvester = ArcMapCondition(
    id: 'harvester',
    label: 'Harvester',
    type: ArcMapConditionType.event,
  );

  static const ArcMapCondition matriarch = ArcMapCondition(
    id: 'matriarch',
    label: 'Matriarch',
    type: ArcMapConditionType.event,
  );

  static const ArcMapCondition prospectingProbes = ArcMapCondition(
    id: 'prospecting_probes',
    label: 'Prospecting Probes',
    type: ArcMapConditionType.event,
  );

  static const ArcMapCondition uncoveredCaches = ArcMapCondition(
    id: 'uncovered_caches',
    label: 'Uncovered Caches',
    type: ArcMapConditionType.event,
  );

  static const ArcMapCondition huskGraveyard = ArcMapCondition(
    id: 'husk_graveyard',
    label: 'Husk Graveyard',
    type: ArcMapConditionType.event,
  );

  static const ArcMapCondition lushBlooms = ArcMapCondition(
    id: 'lush_blooms',
    label: 'Lush Blooms',
    type: ArcMapConditionType.event,
  );

  static const ArcMapCondition birdCity = ArcMapCondition(
    id: 'bird_city',
    label: 'Bird City',
    type: ArcMapConditionType.event,
    isMapSpecific: true,
    supportedMaps: [buriedCityMap],
  );

  static const ArcMapCondition lockedGate = ArcMapCondition(
    id: 'locked_gate',
    label: 'Locked Gate',
    type: ArcMapConditionType.event,
    isMapSpecific: true,
    supportedMaps: [blueGateMap],
  );

  static const ArcMapCondition hiddenBunker = ArcMapCondition(
    id: 'hidden_bunker',
    label: 'Hidden Bunker',
    type: ArcMapConditionType.event,
    isMapSpecific: true,
    supportedMaps: [spaceportMap],
  );

  static const ArcMapCondition launchTowerLoot = ArcMapCondition(
    id: 'launch_tower_loot',
    label: 'Launch Tower Loot',
    type: ArcMapConditionType.event,
    isMapSpecific: true,
    supportedMaps: [spaceportMap],
  );

  static const ArcMapCondition beachcombing = ArcMapCondition(
    id: 'beachcombing',
    label: 'Beachcombing',
    type: ArcMapConditionType.event,
    isMapSpecific: true,
    supportedMaps: [rivenTidesMap],
  );

  static const ArcMapCondition lastResort = ArcMapCondition(
    id: 'last_resort',
    label: 'Last Resort',
    type: ArcMapConditionType.event,
    isMapSpecific: true,
    supportedMaps: [rivenTidesMap],
  );

  static const List<ArcMapCondition> _allConditions = [
    noSpecialCondition,
    nightRaid,
    electromagneticStorm,
    bloom,
    coldSnap,
    hurricane,
    closeScrutiny,
    harvester,
    matriarch,
    prospectingProbes,
    uncoveredCaches,
    huskGraveyard,
    lushBlooms,
    birdCity,
    lockedGate,
    hiddenBunker,
    launchTowerLoot,
    beachcombing,
    lastResort,
  ];

  static List<ArcMapCondition> combinedOptionsForMap(String mapName) {
    return _allConditions
        .where((item) => item.supportsMap(mapName))
        .toList(growable: false);
  }

  static List<ArcMapCondition> eventsForMap(String mapName) {
    return combinedOptionsForMap(
      mapName,
    ).where((item) => item.isEvent || item.isNeutral).toList(growable: false);
  }

  static List<ArcMapCondition> weatherForMap(String mapName) {
    return combinedOptionsForMap(
      mapName,
    ).where((item) => item.isWeather || item.isNeutral).toList(growable: false);
  }

  static ArcMapCondition? byId(String? id) {
    final trimmed = id?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    for (final condition in _allConditions) {
      if (condition.id == trimmed) return condition;
    }
    return null;
  }
}
