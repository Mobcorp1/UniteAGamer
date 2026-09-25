import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_intel_seed.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raider_goal_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/raid_planner_blueprint_rules.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/raid_planner_event_schedule.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/models/raid_planner_models.dart';

class ArcQuestRouteHint {
  const ArcQuestRouteHint({
    required this.questId,
    required this.mapNames,
    this.conditionNames = const <String>[],
    this.poiIds = const <String>[],
    this.conditionFit = ArcRaiderGoalConditionFit.none,
    this.confidence = ArcRaiderGoalRouteConfidence.verified,
  });

  final String questId;
  final List<String> mapNames;
  final List<String> conditionNames;
  final List<String> poiIds;
  final ArcRaiderGoalConditionFit conditionFit;
  final ArcRaiderGoalRouteConfidence confidence;
}

class ArcRaiderGoalBridge {
  const ArcRaiderGoalBridge._();

  static List<ArcRaiderGoal> blueprintGoals(List<RaidBlueprintTarget> targets) {
    final output = <ArcRaiderGoal>[];

    for (final target in targets) {
      final blueprint = RaidPlannerEngineLookup.blueprint(target.blueprintId);
      if (blueprint == null) continue;

      final hint = ArcBlueprintIntelLibrary.resolve(blueprint);
      final exactRule = RaidPlannerBlueprintRules.byBlueprintId(
        target.blueprintId,
      );
      final conditions = exactRule != null
          ? <String>[exactRule.eventName]
          : ArcBlueprintIntelLibrary.playableConditions(
              hint.bestConditions,
            ).toList(growable: false);
      final mapNames = hint.likelyMaps.isEmpty
          ? const <String>[]
          : List<String>.unmodifiable(hint.likelyMaps);
      final mapSpecific = !ArcBlueprintIntelLibrary.isAllMaps(hint.likelyMaps);
      final conditionFit = exactRule != null
          ? ArcRaiderGoalConditionFit.required
          : conditions.isNotEmpty
          ? ArcRaiderGoalConditionFit.preferred
          : ArcRaiderGoalConditionFit.none;
      final confidence = exactRule != null
          ? ArcRaiderGoalRouteConfidence.verified
          : (mapSpecific || conditions.isNotEmpty)
          ? ArcRaiderGoalRouteConfidence.strong
          : ArcRaiderGoalRouteConfidence.provisional;

      output.add(
        ArcRaiderGoal(
          id: 'blueprint:${target.blueprintId}',
          label: blueprint.name,
          source: ArcRaiderGoalSource.blueprint,
          cooperation: ArcRaiderGoalCooperation.scarceSharedLoot,
          priority: _targetPriority(target),
          mapNames: mapNames,
          conditionNames: conditions,
          conditionFit: conditionFit,
          routeConfidence: confidence,
          reason: exactRule?.reason ?? hint.tip,
        ),
      );
    }

    return List<ArcRaiderGoal>.unmodifiable(output);
  }

  static List<ArcRaiderGoal> questGoals(
    ArcQuestProgressionSnapshot snapshot, {
    Map<String, ArcQuestRouteHint> routeHints =
        const <String, ArcQuestRouteHint>{},
  }) {
    final output = <ArcRaiderGoal>[];

    for (final entry in snapshot.entries) {
      if (entry.completed ||
          entry.status == ArcProgressionStatus.archived ||
          entry.locked) {
        continue;
      }
      if (snapshot.trackedQuestIds.isNotEmpty &&
          !snapshot.trackedQuestIds.contains(entry.questId)) {
        continue;
      }

      final route = routeHints[entry.questId];
      final catalogueNode = ArcQuestCatalogue.byId[entry.questId];
      final catalogueMaps = catalogueNode?.mapNames ?? const <String>[];
      output.add(
        ArcRaiderGoal(
          id: 'quest:${entry.questId}',
          label: entry.questName,
          source: ArcRaiderGoalSource.quest,
          // Current quest-specific interactions/pickups are treated as
          // cooperative alignment: squadmates can pursue the same quest route
          // without a matchmaking competition penalty.
          cooperation: ArcRaiderGoalCooperation.cooperative,
          priority: entry.readyToComplete ? 5 : 4,
          mapNames: route?.mapNames ?? catalogueMaps,
          conditionNames: route?.conditionNames ?? const <String>[],
          poiIds: route?.poiIds ?? const <String>[],
          conditionFit: route?.conditionFit ?? ArcRaiderGoalConditionFit.none,
          routeConfidence:
              route?.confidence ??
              (catalogueMaps.isNotEmpty
                  ? ArcRaiderGoalRouteConfidence.strong
                  : ArcRaiderGoalRouteConfidence.unrouted),
          reason: route != null
              ? 'Verified quest route can be combined with other active goals.'
              : catalogueMaps.isNotEmpty
              ? 'Current quest map is catalogued; exact POIs are not invented.'
              : 'Active quest is tracked, but route data is not verified yet.',
        ),
      );
    }

    return List<ArcRaiderGoal>.unmodifiable(output);
  }

  static List<ArcRaidCandidate> scheduleCandidates({
    DateTime? nowUtc,
    int horizonDays = 2,
    bool includeStandard = true,
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final candidates = <ArcRaidCandidate>[];

    if (includeStandard) {
      for (final mapName in _standardMaps) {
        candidates.add(
          ArcRaidCandidate(
            mapName: mapName,
            conditionName: ArcMapConditions.noSpecialCondition.label,
            isLive: true,
          ),
        );
      }
    }

    final baseDay = DateTime.utc(now.year, now.month, now.day);
    for (final slot in RaidPlannerEventSchedule.slots) {
      for (var dayOffset = 0; dayOffset <= horizonDays; dayOffset++) {
        final day = baseDay.add(Duration(days: dayOffset));
        final start = slot.startForDay(day);
        final end = slot.endForStart(start);
        if (!end.isAfter(now)) continue;
        candidates.add(
          ArcRaidCandidate(
            mapName: slot.mapName,
            conditionName: slot.eventName,
            startUtc: start,
            endUtc: end,
            isLive: !now.isBefore(start) && now.isBefore(end),
          ),
        );
      }
    }

    return List<ArcRaidCandidate>.unmodifiable(candidates);
  }

  static int _targetPriority(RaidBlueprintTarget target) {
    switch (target.tier) {
      case RaidTargetTier.activeHunt:
        return (5 - target.rank).clamp(3, 5).toInt();
      case RaidTargetTier.nextUp:
        return (4 - target.rank).clamp(2, 4).toInt();
      case RaidTargetTier.later:
        return 1;
    }
  }

  static const List<String> _standardMaps = <String>[
    ArcMapConditions.damBattlegroundsMap,
    ArcMapConditions.spaceportMap,
    ArcMapConditions.buriedCityMap,
    ArcMapConditions.blueGateMap,
    ArcMapConditions.stellaMontisMap,
    ArcMapConditions.rivenTidesMap,
  ];
}

class RaidPlannerEngineLookup {
  const RaidPlannerEngineLookup._();

  static ArcBlueprint? blueprint(String blueprintId) {
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (blueprint.id == blueprintId) return blueprint;
    }
    return null;
  }
}
