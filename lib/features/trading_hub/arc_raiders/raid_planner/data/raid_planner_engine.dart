import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_intel_seed.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/raid_planner/data/raid_planner_blueprint_rules.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/raid_planner/data/raid_planner_event_schedule.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/raid_planner/models/raid_planner_models.dart';

class RaidPlannerEngine {
  static List<ArcBlueprint> get supportedBlueprints {
    final blueprints = List<ArcBlueprint>.from(ArcBlueprintSeedData.blueprints)
      ..sort((a, b) {
        final orderCompare = a.sortOrder.compareTo(b.sortOrder);
        if (orderCompare != 0) return orderCompare;
        return a.name.compareTo(b.name);
      });
    return blueprints;
  }

  static ArcBlueprint? findBlueprintById(String blueprintId) {
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (blueprint.id == blueprintId) return blueprint;
    }
    return null;
  }

  static List<RaidBlueprintTarget> effectiveTargets({
    required List<RaidBlueprintTarget> storedTargets,
    required Map<String, ArcBlueprintState> states,
    required RaidPlannerEntitlement entitlement,
  }) {
    final supportedIds = ArcBlueprintSeedData.blueprints.map((blueprint) => blueprint.id).toSet();
    final clean = storedTargets
        .where((target) => supportedIds.contains(target.blueprintId))
        .where((target) => !(states[target.blueprintId]?.owned ?? false))
        .toList(growable: false);

    final active = clean.where((target) => target.tier == RaidTargetTier.activeHunt).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
    final next = clean.where((target) => target.tier == RaidTargetTier.nextUp).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
    final later = clean.where((target) => target.tier == RaidTargetTier.later).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    final activeLimit = entitlement.activeHuntSlots.clamp(1, 5).toInt();
    final effective = <RaidBlueprintTarget>[];
    for (final item in active.take(activeLimit)) {
      effective.add(item.copyWith(tier: RaidTargetTier.activeHunt));
    }

    var promotedRank = effective.length;
    for (final item in next) {
      if (effective.length >= activeLimit) break;
      effective.add(item.copyWith(tier: RaidTargetTier.activeHunt, rank: promotedRank));
      promotedRank++;
    }

    final nonActive = <RaidBlueprintTarget>[];
    final promotedFromNext = (activeLimit - active.length).clamp(0, next.length).toInt();
    for (final item in active.skip(activeLimit)) {
      nonActive.add(item.copyWith(tier: RaidTargetTier.nextUp));
    }
    nonActive.addAll(next.skip(promotedFromNext));
    nonActive.addAll(later);

    return <RaidBlueprintTarget>[...effective, ...nonActive];
  }

  static RaidPlannerBlueprintRule _genericRuleForBlueprint(
    ArcBlueprint blueprint,
    String eventName,
  ) {
    final hint = ArcBlueprintIntelLibrary.resolve(blueprint);
    final containerText = hint.likelyContainers.isEmpty
        ? 'seeded containers'
        : hint.likelyContainers.take(3).join(', ');
    final mapText = ArcBlueprintIntelLibrary.isAllMaps(hint.likelyMaps)
        ? 'eligible maps'
        : hint.likelyMaps.join(', ');

    return RaidPlannerBlueprintRule(
      blueprintId: blueprint.id,
      blueprintName: blueprint.name,
      eventName: eventName,
      reason: 'Seeded baseline: run $mapText, prioritise $eventName, and focus $containerText until community intel creates a stronger route.',
    );
  }

  static Iterable<RaidPlannerEventSlot> _slotsForTarget(RaidBlueprintTarget target) {
    final blueprint = findBlueprintById(target.blueprintId);
    if (blueprint == null) return const <RaidPlannerEventSlot>[];

    final exactRule = RaidPlannerBlueprintRules.byBlueprintId(target.blueprintId);
    final hint = ArcBlueprintIntelLibrary.resolve(blueprint);
    final playableConditions = ArcBlueprintIntelLibrary.playableConditions(hint.bestConditions).toSet();
    final hasPlayableCondition = playableConditions.isNotEmpty;
    final mapRestricted = !ArcBlueprintIntelLibrary.isAllMaps(hint.likelyMaps);
    final allowedMaps = hint.likelyMaps.map(_normalizeMapName).toSet();

    return RaidPlannerEventSchedule.slots.where((slot) {
      if (mapRestricted && !allowedMaps.contains(_normalizeMapName(slot.mapName))) {
        return false;
      }

      if (exactRule != null) {
        return slot.eventName == exactRule.eventName;
      }

      if (hasPlayableCondition) {
        return playableConditions.any((condition) => _sameEvent(condition, slot.eventName));
      }

      return slot.lane == RaidPlannerEventSchedule.laneMajor && slot.eventName != 'Normal';
    });
  }

  static bool _sameEvent(String a, String b) {
    return _normalizeSearch(a) == _normalizeSearch(b);
  }

  static String _normalizeMapName(String value) {
    final normalized = _normalizeSearch(value);
    if (normalized == 'the blue gate') return 'blue gate';
    return normalized;
  }

  static List<RaidPlannerOpportunity> allOpportunities({
    required List<RaidBlueprintTarget> effectiveTargets,
    DateTime? nowUtc,
    int horizonDays = 7,
  }) {
    final utcNow = nowUtc ?? DateTime.now().toUtc();
    final activeTargets = effectiveTargets
        .where((target) => target.tier == RaidTargetTier.activeHunt)
        .toList(growable: false)
      ..sort((a, b) => a.rank.compareTo(b.rank));

    final opportunities = <RaidPlannerOpportunity>[];
    final baseDay = DateTime.utc(utcNow.year, utcNow.month, utcNow.day);

    for (final target in activeTargets) {
      final blueprint = findBlueprintById(target.blueprintId);
      if (blueprint == null) continue;
      final exactRule = RaidPlannerBlueprintRules.byBlueprintId(target.blueprintId);
      final matchingSlots = _slotsForTarget(target);

      for (final slot in matchingSlots) {
        final rule = exactRule ?? _genericRuleForBlueprint(blueprint, slot.eventName);
        for (var dayOffset = 0; dayOffset <= horizonDays; dayOffset++) {
          final day = baseDay.add(Duration(days: dayOffset));
          final start = slot.startForDay(day);
          final end = slot.endForStart(start);
          if (!end.isAfter(utcNow)) continue;

          opportunities.add(
            RaidPlannerOpportunity(
              rule: rule,
              slot: slot,
              startUtc: start,
              endUtc: end,
              isLive: !utcNow.isBefore(start) && utcNow.isBefore(end),
            ),
          );
        }
      }
    }

    opportunities.sort((a, b) {
      final liveCompare = (b.isLive ? 1 : 0).compareTo(a.isLive ? 1 : 0);
      if (liveCompare != 0) return liveCompare;

      final exactCompare = (b.rule.isExactEventRule ? 1 : 0).compareTo(a.rule.isExactEventRule ? 1 : 0);
      if (exactCompare != 0) return exactCompare;

      final startCompare = a.startUtc.compareTo(b.startUtc);
      if (startCompare != 0) return startCompare;
      final nameCompare = a.rule.blueprintName.compareTo(b.rule.blueprintName);
      if (nameCompare != 0) return nameCompare;
      return a.slot.mapName.compareTo(b.slot.mapName);
    });

    return opportunities;
  }


  static String _normalizeSearch(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _matchesEventQuery(RaidPlannerEventSlot slot, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return false;
    final event = _normalizeSearch(slot.eventName);
    final map = _normalizeSearch(slot.mapName);
    final lane = _normalizeSearch(slot.lane);
    final aliases = <String>{event, map, lane, '$event $map', '$map $event'};

    if (event == 'locked gate') {
      aliases.addAll({'lock gate', 'lockgate', 'lockedgate'});
    }
    if (event == 'electromagnetic storm') {
      aliases.addAll({'em storm', 'storm', 'electro storm'});
    }
    if (map == 'dam battlegrounds') {
      aliases.addAll({'dam', 'battlegrounds', 'dam battleground'});
    }
    if (map == 'blue gate') {
      aliases.addAll({'bluegate'});
    }
    if (map == 'buried city') {
      aliases.addAll({'buried', 'buriedcity'});
    }
    if (map == 'stella montis') {
      aliases.addAll({'stella', 'stellamontis', 'stella montes'});
    }
    if (map == 'riven tides') {
      aliases.addAll({'riven', 'riventides', 'riven tide', 'riventide'});
    }
    if (event == 'beachcombing') {
      aliases.addAll({'beach combing', 'beach', 'beachcombing'});
    }
    if (event == 'last resort') {
      aliases.addAll({'resort', 'lastresort'});
    }

    return aliases.any((alias) {
      final normalizedAlias = _normalizeSearch(alias);
      return normalizedAlias.contains(normalizedQuery) || normalizedQuery.contains(normalizedAlias);
    });
  }

  static List<RaidPlannerOpportunity> eventLookup({
    required String query,
    DateTime? nowUtc,
    int limit = 3,
  }) {
    final utcNow = nowUtc ?? DateTime.now().toUtc();
    final normalized = _normalizeSearch(query);
    if (normalized.length < 2) return <RaidPlannerOpportunity>[];

    final baseDay = DateTime.utc(utcNow.year, utcNow.month, utcNow.day);
    final matches = <RaidPlannerOpportunity>[];

    for (final slot in RaidPlannerEventSchedule.slots) {
      if (!_matchesEventQuery(slot, normalized)) continue;

      for (var dayOffset = 0; dayOffset <= 7; dayOffset++) {
        final day = baseDay.add(Duration(days: dayOffset));
        final start = slot.startForDay(day);
        final end = slot.endForStart(start);
        if (!end.isAfter(utcNow)) continue;

        matches.add(
          RaidPlannerOpportunity(
            rule: RaidPlannerBlueprintRule(
              blueprintId: 'event-finder',
              blueprintName: slot.eventName,
              eventName: slot.eventName,
              reason: 'Event Finder result.',
            ),
            slot: slot,
            startUtc: start,
            endUtc: end,
            isLive: !utcNow.isBefore(start) && utcNow.isBefore(end),
          ),
        );
      }
    }

    matches.sort((a, b) {
      final liveCompare = (b.isLive ? 1 : 0).compareTo(a.isLive ? 1 : 0);
      if (liveCompare != 0) return liveCompare;
      final startCompare = a.startUtc.compareTo(b.startUtc);
      if (startCompare != 0) return startCompare;
      final eventCompare = a.slot.eventName.compareTo(b.slot.eventName);
      if (eventCompare != 0) return eventCompare;
      return a.slot.mapName.compareTo(b.slot.mapName);
    });

    final unique = <String>{};
    final deduped = <RaidPlannerOpportunity>[];
    for (final match in matches) {
      final key = '${match.slot.eventName}|${match.slot.mapName}|${match.slot.lane}|${match.startUtc.toIso8601String()}';
      if (unique.add(key)) deduped.add(match);
      if (deduped.length >= limit) break;
    }

    return deduped;
  }

  static RaidPlannerSnapshot buildSnapshot({
    required List<RaidBlueprintTarget> effectiveTargets,
    DateTime? nowUtc,
  }) {
    final utcNow = nowUtc ?? DateTime.now().toUtc();
    final all = allOpportunities(
      effectiveTargets: effectiveTargets,
      nowUtc: utcNow,
      horizonDays: 2,
    );

    final live = all.where((opportunity) => opportunity.isLive).toList(growable: false);
    final upcoming = all.where((opportunity) => !opportunity.isLive).toList(growable: false);
    final today = all.where((opportunity) {
      final localStart = opportunity.startUtc.toLocal();
      final localNow = utcNow.toLocal();
      return localStart.year == localNow.year &&
          localStart.month == localNow.month &&
          localStart.day == localNow.day;
    }).toList(growable: false);

    return RaidPlannerSnapshot(
      live: live.take(8).toList(growable: false),
      upcoming: upcoming.take(12).toList(growable: false),
      today: today.take(24).toList(growable: false),
    );
  }
}
