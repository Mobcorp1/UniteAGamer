import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_intel_seed.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_availability.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';

class ArcConditionTargetRule {
  final String id;
  final String label;
  final List<String> conditions;
  final List<String> maps;
  final bool verifiedConditionLink;
  final String reason;

  const ArcConditionTargetRule({
    required this.id,
    required this.label,
    required this.conditions,
    this.maps = const <String>[],
    this.verifiedConditionLink = false,
    required this.reason,
  });
}

class ArcRegionalOpportunity {
  final ArcConditionTargetRule target;
  final ArcRegionalMapConditionEntry condition;
  final ArcServerRegion region;
  final ArcRegionalConditionWindow window;
  final bool insideSavedPlaytime;
  final bool homeRegion;
  final bool live;

  const ArcRegionalOpportunity({
    required this.target,
    required this.condition,
    required this.region,
    required this.window,
    required this.insideSavedPlaytime,
    required this.homeRegion,
    required this.live,
  });

  bool get shouldSwitchRegion => !homeRegion;

  Duration timeUntil(DateTime utcNow) => window.startUtc.difference(utcNow);
}

class ArcRegionalOpportunityEngine {
  static const List<ArcConditionTargetRule> itemRules = [
    ArcConditionTargetRule(
      id: 'matriarch-reactor',
      label: 'Matriarch Reactor / Matriarch Parts',
      conditions: ['Matriarch'],
      verifiedConditionLink: true,
      reason: 'Matriarch-specific ARC parts require a Matriarch opportunity.',
    ),
    ArcConditionTargetRule(
      id: 'queen-reactor',
      label: 'Queen Reactor / Queen Parts',
      conditions: ['Harvester'],
      verifiedConditionLink: true,
      reason:
          'Harvester is the tracked condition for Queen encounters and Harvester-linked Queen materials.',
    ),
    ArcConditionTargetRule(
      id: 'harvester-rewards',
      label: 'Harvester Rewards / Reactor Materials',
      conditions: ['Harvester'],
      verifiedConditionLink: true,
      reason: 'Targets the Harvester condition and its guarded reward loop.',
    ),
    ArcConditionTargetRule(
      id: 'arc-assessor-loot',
      label: 'ARC Assessor Loot',
      conditions: ['Close Scrutiny'],
      verifiedConditionLink: true,
      reason:
          'Close Scrutiny is the target condition for ARC Assessor farming.',
    ),
  ];

  static const Map<String, ArcConditionTargetRule> _verifiedBlueprintRules = {
    'dolabra': ArcConditionTargetRule(
      id: 'dolabra',
      label: 'Dolabra',
      conditions: ['Close Scrutiny'],
      verifiedConditionLink: true,
      reason: 'Condition-specific Blueprint target: Close Scrutiny.',
    ),
    'surge-coil': ArcConditionTargetRule(
      id: 'surge-coil',
      label: 'Surge Coil',
      conditions: ['Electromagnetic Storm'],
      verifiedConditionLink: true,
      reason: 'Condition-specific Blueprint target: Electromagnetic Storm.',
    ),
    'snap-hook': ArcConditionTargetRule(
      id: 'snap-hook',
      label: 'Snap Hook',
      conditions: ['Electromagnetic Storm'],
      verifiedConditionLink: true,
      reason: 'Condition-specific Blueprint target: Electromagnetic Storm.',
    ),
    'equalizer': ArcConditionTargetRule(
      id: 'equalizer',
      label: 'Equalizer',
      conditions: ['Harvester'],
      verifiedConditionLink: true,
      reason: 'Condition-specific Blueprint target: Harvester.',
    ),
    'jupiter': ArcConditionTargetRule(
      id: 'jupiter',
      label: 'Jupiter',
      conditions: ['Harvester'],
      verifiedConditionLink: true,
      reason: 'Condition-specific Blueprint target: Harvester.',
    ),
    'canto': ArcConditionTargetRule(
      id: 'canto',
      label: 'Canto',
      conditions: ['Hurricane'],
      verifiedConditionLink: true,
      reason: 'Condition-specific Blueprint target: Hurricane.',
    ),
    'wolfpack': ArcConditionTargetRule(
      id: 'wolfpack',
      label: 'Wolfpack',
      conditions: ['Night Raid'],
      verifiedConditionLink: true,
      reason: 'Condition-specific Blueprint target: Night Raid.',
    ),
    'vulcano': ArcConditionTargetRule(
      id: 'vulcano',
      label: 'Vulcano',
      conditions: ['Hidden Bunker', 'Hurricane'],
      verifiedConditionLink: true,
      reason: 'Tracked condition targets: Hidden Bunker or Hurricane.',
    ),
    'bobcat': ArcConditionTargetRule(
      id: 'bobcat',
      label: 'Bobcat',
      conditions: ['Locked Gate', 'Hurricane'],
      verifiedConditionLink: true,
      reason: 'Tracked condition targets: Locked Gate or Hurricane.',
    ),
    'tempest': ArcConditionTargetRule(
      id: 'tempest',
      label: 'Tempest',
      conditions: ['Night Raid', 'Hurricane'],
      verifiedConditionLink: true,
      reason: 'Tracked condition targets: Night Raid or Hurricane.',
    ),
    'angled-grip-iii': ArcConditionTargetRule(
      id: 'angled-grip-iii',
      label: 'Angled Grip III',
      conditions: ['Electromagnetic Storm', 'Locked Gate', 'Night Raid'],
      verifiedConditionLink: true,
      reason: 'High-tier attachment condition pool.',
    ),
    'compensator-iii': ArcConditionTargetRule(
      id: 'compensator-iii',
      label: 'Compensator III',
      conditions: ['Electromagnetic Storm', 'Locked Gate', 'Night Raid'],
      verifiedConditionLink: true,
      reason: 'High-tier attachment condition pool.',
    ),
    'extended-barrel-iii': ArcConditionTargetRule(
      id: 'extended-barrel-iii',
      label: 'Extended Barrel III',
      conditions: ['Electromagnetic Storm', 'Locked Gate', 'Night Raid'],
      verifiedConditionLink: true,
      reason: 'High-tier attachment condition pool.',
    ),
    'extended-light-mag-iii': ArcConditionTargetRule(
      id: 'extended-light-mag-iii',
      label: 'Extended Light Mag III',
      conditions: ['Electromagnetic Storm', 'Locked Gate', 'Night Raid'],
      verifiedConditionLink: true,
      reason: 'High-tier attachment condition pool.',
    ),
    'extended-medium-mag-iii': ArcConditionTargetRule(
      id: 'extended-medium-mag-iii',
      label: 'Extended Medium Mag III',
      conditions: ['Electromagnetic Storm', 'Locked Gate', 'Night Raid'],
      verifiedConditionLink: true,
      reason: 'High-tier attachment condition pool.',
    ),
    'extended-shotgun-mag-iii': ArcConditionTargetRule(
      id: 'extended-shotgun-mag-iii',
      label: 'Extended Shotgun Mag III',
      conditions: ['Electromagnetic Storm', 'Locked Gate', 'Night Raid'],
      verifiedConditionLink: true,
      reason: 'High-tier attachment condition pool.',
    ),
    'lightweight-stock': ArcConditionTargetRule(
      id: 'lightweight-stock',
      label: 'Lightweight Stock',
      conditions: ['Electromagnetic Storm', 'Locked Gate', 'Night Raid'],
      verifiedConditionLink: true,
      reason: 'High-tier attachment condition pool.',
    ),
    'muzzle-brake-iii': ArcConditionTargetRule(
      id: 'muzzle-brake-iii',
      label: 'Muzzle Brake III',
      conditions: ['Electromagnetic Storm', 'Locked Gate', 'Night Raid'],
      verifiedConditionLink: true,
      reason: 'High-tier attachment condition pool.',
    ),
    'stable-stock-iii': ArcConditionTargetRule(
      id: 'stable-stock-iii',
      label: 'Stable Stock III',
      conditions: ['Electromagnetic Storm', 'Locked Gate', 'Night Raid'],
      verifiedConditionLink: true,
      reason: 'High-tier attachment condition pool.',
    ),
    'vertical-grip-iii': ArcConditionTargetRule(
      id: 'vertical-grip-iii',
      label: 'Vertical Grip III',
      conditions: ['Electromagnetic Storm', 'Locked Gate', 'Night Raid'],
      verifiedConditionLink: true,
      reason: 'High-tier attachment condition pool.',
    ),
    'shotgun-choke-iii': ArcConditionTargetRule(
      id: 'shotgun-choke-iii',
      label: 'Shotgun Choke III',
      conditions: ['Electromagnetic Storm', 'Locked Gate', 'Night Raid'],
      verifiedConditionLink: true,
      reason: 'High-tier attachment condition pool.',
    ),
  };

  static List<ArcConditionTargetRule> missingBlueprintRules(
    Map<String, ArcBlueprintState> states,
  ) {
    final result = <ArcConditionTargetRule>[];
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (states[blueprint.id]?.owned ?? false) continue;

      final verified = _verifiedBlueprintRules[blueprint.id];
      if (verified != null) {
        result.add(verified);
        continue;
      }

      final hint = ArcBlueprintIntelLibrary.resolve(blueprint);
      final conditions = ArcBlueprintIntelLibrary.playableConditions(
        hint.bestConditions,
      ).where((value) => value.trim().isNotEmpty).toList(growable: false);
      if (conditions.isEmpty) continue;

      final maps = ArcBlueprintIntelLibrary.isAllMaps(hint.likelyMaps)
          ? const <String>[]
          : hint.likelyMaps;

      result.add(
        ArcConditionTargetRule(
          id: blueprint.id,
          label: blueprint.name,
          conditions: conditions,
          maps: maps,
          reason:
              'Uses the Blueprint Tracker seed/community condition and map intelligence.',
        ),
      );
    }
    return result;
  }

  static List<ArcRegionalOpportunity> blueprintRecommendations({
    required ArcRegionalMapConditionsSnapshot snapshot,
    required Map<String, ArcBlueprintState> states,
    required ArcAvailability availability,
    required ArcServerRegion homeRegion,
    DateTime? nowUtc,
    int limit = 12,
  }) {
    return recommendationsForTargets(
      snapshot: snapshot,
      targets: missingBlueprintRules(states),
      availability: availability,
      homeRegion: homeRegion,
      nowUtc: nowUtc,
      limit: limit,
    );
  }

  static List<ArcRegionalOpportunity> itemRecommendations({
    required ArcRegionalMapConditionsSnapshot snapshot,
    required String itemId,
    required ArcAvailability availability,
    required ArcServerRegion homeRegion,
    DateTime? nowUtc,
    int limit = 8,
  }) {
    final targets = itemRules.where((item) => item.id == itemId).toList();
    return recommendationsForTargets(
      snapshot: snapshot,
      targets: targets,
      availability: availability,
      homeRegion: homeRegion,
      nowUtc: nowUtc,
      limit: limit,
    );
  }

  static List<ArcRegionalOpportunity> recommendationsForTargets({
    required ArcRegionalMapConditionsSnapshot snapshot,
    required List<ArcConditionTargetRule> targets,
    required ArcAvailability availability,
    required ArcServerRegion homeRegion,
    DateTime? nowUtc,
    int limit = 12,
  }) {
    final now = nowUtc ?? DateTime.now().toUtc();
    final results = <ArcRegionalOpportunity>[];

    for (final target in targets) {
      for (final entry in snapshot.entries) {
        if (!_matchesAny(entry.conditionName, target.conditions)) continue;
        if (target.maps.isNotEmpty &&
            !_matchesAnyMap(entry.mapDisplayName, target.maps)) {
          continue;
        }

        for (final region in ArcServerRegion.values) {
          final window = entry.windowFor(region);
          if (window == null || !window.endUtc.isAfter(now)) continue;

          results.add(
            ArcRegionalOpportunity(
              target: target,
              condition: entry,
              region: region,
              window: window,
              insideSavedPlaytime: _overlapsSavedAvailability(
                window,
                availability,
              ),
              homeRegion: region == homeRegion,
              live: window.isActiveAt(now),
            ),
          );
        }
      }
    }

    results.sort((a, b) {
      final rankCompare = _rank(a).compareTo(_rank(b));
      if (rankCompare != 0) return rankCompare;
      final timeCompare = a.window.startUtc.compareTo(b.window.startUtc);
      if (timeCompare != 0) return timeCompare;
      final targetCompare = a.target.label.compareTo(b.target.label);
      if (targetCompare != 0) return targetCompare;
      return a.region.index.compareTo(b.region.index);
    });

    final seen = <String>{};
    final deduped = <ArcRegionalOpportunity>[];
    for (final result in results) {
      final key =
          '${result.target.id}|${result.condition.conditionName}|${result.condition.mapDisplayName}|${result.region.key}|${result.window.startUtc.millisecondsSinceEpoch}';
      if (!seen.add(key)) continue;
      deduped.add(result);
      if (deduped.length >= limit) break;
    }
    return deduped;
  }

  static List<ArcRegionalMapConditionEntry> findConditions({
    required ArcRegionalMapConditionsSnapshot snapshot,
    required String query,
  }) {
    final normalized = _normalize(query);
    if (normalized.length < 2) return const <ArcRegionalMapConditionEntry>[];

    final matches = snapshot.entries
        .where((entry) {
          final condition = _normalize(entry.conditionName);
          final map = _normalize(entry.mapDisplayName);
          return condition.contains(normalized) ||
              map.contains(normalized) ||
              '$condition $map'.contains(normalized) ||
              '$map $condition'.contains(normalized);
        })
        .toList(growable: false);

    matches.sort((a, b) {
      final aStart = a.regionWindows.values
          .map((item) => item.startUtc)
          .reduce((x, y) => x.isBefore(y) ? x : y);
      final bStart = b.regionWindows.values
          .map((item) => item.startUtc)
          .reduce((x, y) => x.isBefore(y) ? x : y);
      return aStart.compareTo(bStart);
    });
    return matches;
  }

  static int _rank(ArcRegionalOpportunity item) {
    if (item.live && item.homeRegion) return 0;
    if (item.live) return 1;
    if (item.insideSavedPlaytime && item.homeRegion) return 2;
    if (item.insideSavedPlaytime) return 3;
    if (item.homeRegion) return 4;
    return 5;
  }

  static bool _matchesAny(String actual, List<String> expected) {
    final normalized = _normalize(actual);
    return expected.any((value) => _normalize(value) == normalized);
  }

  static bool _matchesAnyMap(String actual, List<String> expected) {
    final normalized = _normalizeMap(actual);
    return expected.any((value) => _normalizeMap(value) == normalized);
  }

  static String _normalizeMap(String value) {
    final normalized = _normalize(value);
    if (normalized == 'blue gate') return 'the blue gate';
    return normalized;
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _overlapsSavedAvailability(
    ArcRegionalConditionWindow condition,
    ArcAvailability availability,
  ) {
    final localStart = condition.startUtc.toLocal();
    final localEnd = condition.endUtc.toLocal();

    for (var dayOffset = -1; dayOffset <= 1; dayOffset++) {
      final localDay = DateTime(
        localStart.year,
        localStart.month,
        localStart.day + dayOffset,
      );
      final slot = _slotForDate(availability, localDay);
      if (slot == null || !slot.enabled) continue;

      final start = _dateTime(localDay, slot.fromTime);
      var end = _dateTime(localDay, slot.toTime);
      if (start == null || end == null) continue;
      if (!end.isAfter(start)) {
        end = end.add(const Duration(days: 1));
      }

      if (localStart.isBefore(end) && localEnd.isAfter(start)) return true;
    }
    return false;
  }

  static ArcAvailabilitySlot? _slotForDate(
    ArcAvailability availability,
    DateTime localDate,
  ) {
    if (availability.weeks.isEmpty) return null;
    final dayKey = _dayKey(localDate.weekday);

    ArcAvailabilityWeek week;
    if (availability.useEveryWeek || availability.weeks.length == 1) {
      week = availability.weeks.first;
    } else {
      final anchor = DateTime(2026, 1, 5);
      final day = DateTime(localDate.year, localDate.month, localDate.day);
      final weeksSinceAnchor = day.difference(anchor).inDays ~/ 7;
      final index =
          ((weeksSinceAnchor % availability.weeks.length) +
              availability.weeks.length) %
          availability.weeks.length;
      week = availability.weeks[index];
    }

    for (final slot in week.slots) {
      if (slot.dayKey == dayKey) return slot;
    }
    return null;
  }

  static String _dayKey(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'mon';
      case DateTime.tuesday:
        return 'tue';
      case DateTime.wednesday:
        return 'wed';
      case DateTime.thursday:
        return 'thu';
      case DateTime.friday:
        return 'fri';
      case DateTime.saturday:
        return 'sat';
      case DateTime.sunday:
        return 'sun';
      default:
        return 'mon';
    }
  }

  static DateTime? _dateTime(DateTime day, String time) {
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }
}
