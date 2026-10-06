import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_intel_seed.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_progression_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_recommendation_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raider_goal_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_raider_goal_bridge.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/raid_planner_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/models/raid_planner_models.dart';

/// Converges saved Raid Planner targets, priority Blueprint Tracker state,
/// active Quest progress and the official regional Map Conditions feed into the
/// recommendation engine used by Raid Intelligence.
class ArcLiveRaidRecommendationEngine {
  const ArcLiveRaidRecommendationEngine();

  ArcRaidRecommendationSet build({
    required List<RaidBlueprintTarget> storedTargets,
    required Map<String, ArcBlueprintState> blueprintStates,
    required RaidPlannerEntitlement entitlement,
    required ArcProgressionRecords progressionRecords,
    required Map<String, ArcScrappyState> scrappyStates,
    required ArcRegionalMapConditionsSnapshot regionalSnapshot,
    ArcServerRegion region = ArcServerRegion.europe,
    DateTime? nowUtc,
  }) {
    final now = _effectiveNow(regionalSnapshot, nowUtc: nowUtc);
    final effectiveTargets = RaidPlannerEngine.effectiveTargets(
      storedTargets: storedTargets,
      states: blueprintStates,
      entitlement: entitlement,
    );
    final targetedIds = effectiveTargets
        .map((target) => target.blueprintId)
        .toSet();
    final progression = const ArcProgressionEngine().build(
      scrappyStates: scrappyStates,
      records: progressionRecords,
    );
    final goals = <ArcRaiderGoal>[
      ...ArcRaiderGoalBridge.blueprintGoals(effectiveTargets),
      ..._priorityBlueprintGoals(blueprintStates, excludedIds: targetedIds),
      ...ArcRaiderGoalBridge.questGoals(progression.quest),
    ];
    final candidates = _regionalCandidates(
      regionalSnapshot,
      region: region,
      nowUtc: now,
    );
    return const ArcRaidRecommendationEngine().build(
      goals: goals,
      candidates: candidates,
      nowUtc: now,
    );
  }

  String activeConditionLabelForMap({
    required ArcRegionalMapConditionsSnapshot regionalSnapshot,
    required ArcServerRegion region,
    required String mapDisplayName,
    DateTime? nowUtc,
  }) {
    final now = _effectiveNow(regionalSnapshot, nowUtc: nowUtc);
    final mapKey = _normalizeMap(mapDisplayName);
    final active =
        regionalSnapshot.entries
            .where((entry) => _normalizeMap(entry.mapDisplayName) == mapKey)
            .where((entry) => entry.windowFor(region)?.isActiveAt(now) == true)
            .map((entry) => entry.conditionName.trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    if (active.isEmpty) return ArcMapConditions.noSpecialCondition.label;
    return active.join(' + ');
  }

  List<ArcRaidCandidate> _regionalCandidates(
    ArcRegionalMapConditionsSnapshot snapshot, {
    required ArcServerRegion region,
    required DateTime nowUtc,
  }) {
    final candidates = <ArcRaidCandidate>[
      for (final mapName in _standardMaps)
        ArcRaidCandidate(
          mapName: mapName,
          conditionName: ArcMapConditions.noSpecialCondition.label,
          isLive: true,
        ),
    ];

    for (final entry in snapshot.entries) {
      final window = entry.windowFor(region);
      if (window == null || !window.endUtc.isAfter(nowUtc)) continue;
      candidates.add(
        ArcRaidCandidate(
          mapName: entry.mapDisplayName,
          conditionName: entry.conditionName,
          isLive: window.isActiveAt(nowUtc),
          startUtc: window.startUtc,
          endUtc: window.endUtc,
        ),
      );
    }
    return List<ArcRaidCandidate>.unmodifiable(candidates);
  }

  List<ArcRaiderGoal> _priorityBlueprintGoals(
    Map<String, ArcBlueprintState> states, {
    required Set<String> excludedIds,
  }) {
    final prioritized =
        states.values
            .where(
              (state) =>
                  !state.owned &&
                  state.priorityRank > 0 &&
                  !excludedIds.contains(state.blueprintId),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final rankCompare = a.priorityRank.compareTo(b.priorityRank);
            if (rankCompare != 0) return rankCompare;
            return a.blueprintId.compareTo(b.blueprintId);
          });

    final goals = <ArcRaiderGoal>[];
    for (final state in prioritized.take(8)) {
      final blueprint = _blueprintById(state.blueprintId);
      if (blueprint == null) continue;
      final hint = ArcBlueprintIntelLibrary.resolve(blueprint);
      if (hint.likelyMaps.isEmpty) continue;
      final conditions = ArcBlueprintIntelLibrary.playableConditions(
        hint.bestConditions,
      ).toList(growable: false);
      final mapSpecific = !ArcBlueprintIntelLibrary.isAllMaps(hint.likelyMaps);
      goals.add(
        ArcRaiderGoal(
          id: 'priority-blueprint:${blueprint.id}',
          label: blueprint.name,
          source: ArcRaiderGoalSource.blueprint,
          cooperation: ArcRaiderGoalCooperation.scarceSharedLoot,
          priority: (4 - state.priorityRank).clamp(2, 4).toInt(),
          mapNames: List<String>.unmodifiable(hint.likelyMaps),
          conditionNames: conditions,
          conditionFit: conditions.isEmpty
              ? ArcRaiderGoalConditionFit.none
              : ArcRaiderGoalConditionFit.preferred,
          routeConfidence: mapSpecific || conditions.isNotEmpty
              ? ArcRaiderGoalRouteConfidence.strong
              : ArcRaiderGoalRouteConfidence.provisional,
          reason: hint.tip,
        ),
      );
    }
    return List<ArcRaiderGoal>.unmodifiable(goals);
  }

  ArcBlueprint? _blueprintById(String blueprintId) {
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (blueprint.id == blueprintId) return blueprint;
    }
    return null;
  }

  DateTime _effectiveNow(
    ArcRegionalMapConditionsSnapshot snapshot, {
    DateTime? nowUtc,
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    if (!snapshot.isOfficialLive) return now;
    final elapsed = now.difference(snapshot.loadedAtUtc);
    if (elapsed.isNegative) return snapshot.serverNowUtc;
    return snapshot.serverNowUtc.add(elapsed);
  }

  String _normalizeMap(String value) {
    var normalized = value.trim().toLowerCase();
    if (normalized.startsWith('the ')) {
      normalized = normalized.substring(4);
    }
    return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '');
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
