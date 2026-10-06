import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_recommendation_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raider_goal_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_squad_raid_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';

class ArcSquadRaidPlanningEngine {
  const ArcSquadRaidPlanningEngine();

  List<ArcRaidObjective> objectivesForMap({
    required ArcSquadRaidBundle bundle,
    required String mapDisplayName,
  }) {
    final allObjectives = bundle.projections.values
        .expand((projection) => projection.objectives)
        .toList(growable: false);
    if (allObjectives.isEmpty) return const <ArcRaidObjective>[];

    final overlapCounts = <String, int>{};
    final ownerCounts = <String, int>{};
    for (final objective in allObjectives) {
      overlapCounts.update(
        objective.overlapKey,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      ownerCounts.update(
        objective.ownerUid,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final mapKey = _normalizeMap(mapDisplayName);
    final output = <ArcRaidObjective>[];
    for (final objective in allObjectives) {
      if (objective.mapNames.isNotEmpty &&
          !objective.mapNames.any((map) => _normalizeMap(map) == mapKey)) {
        continue;
      }

      final overlap = overlapCounts[objective.overlapKey] ?? 1;
      final ownerCount = math.max(1, ownerCounts[objective.ownerUid] ?? 1);
      var weight = objective.baseWeight;

      switch (bundle.session.fairnessMode) {
        case ArcSquadRaidFairnessMode.balancedSquad:
          // Give each member a similar total influence while paid tiers can
          // contribute a broader set of objectives.
          weight *= 6.0 / ownerCount;
          break;
        case ArcSquadRaidFairnessMode.leaderPriorities:
          weight *= objective.ownerUid == bundle.session.leaderUid ? 1.35 : 0.9;
          break;
        case ArcSquadRaidFairnessMode.maximumSquadValue:
          break;
      }

      weight *= _overlapModifier(objective.classification, overlap);
      final overlapText = overlap > 1
          ? ' $overlap squad members align on this target.'
          : '';
      final classText = switch (objective.classification) {
        ArcSquadObjectiveClass.repeatableEncounter =>
          ' Repeatable encounter: route can support another attempt if raid time remains.',
        ArcSquadObjectiveClass.renewableResource =>
          ' Renewable resource target.',
        ArcSquadObjectiveClass.scarceCompetitive =>
          ' Scarce pickup: competition penalty applied when squad needs overlap.',
        _ => '',
      };

      output.add(
        ArcRaidObjective(
          id: 'squad:${objective.ownerUid}:${objective.id}',
          label: objective.label,
          reason:
              'Squad objective for ${objective.ownerLabel}.$overlapText$classText',
          category: objective.system.toLowerCase().contains('quest')
              ? ArcRaidMapMarkerCategory.questObjective
              : ArcRaidMapMarkerCategory.operationObjective,
          system: 'Squad ${objective.system}',
          itemName: objective.itemName,
          missingCount: objective.missingCount,
          sourceHint: objective.sourceHint,
          blueprintId: objective.blueprintId,
          weight: weight.clamp(0.45, 12.0),
          private: true,
        ),
      );
    }

    return List<ArcRaidObjective>.unmodifiable(output);
  }

  Map<String, ArcBlueprintState> blueprintStatesForBundle(
    ArcSquadRaidBundle bundle,
  ) {
    final projectedBlueprints = <String, int>{};
    for (final objective in bundle.projections.values.expand(
      (projection) => projection.objectives,
    )) {
      final id = objective.blueprintId?.trim();
      if (id == null || id.isEmpty) continue;
      projectedBlueprints.update(
        id,
        (value) => math.min(value, objective.baseWeight.round()),
        ifAbsent: () => objective.baseWeight.round(),
      );
    }

    return <String, ArcBlueprintState>{
      for (final blueprint in ArcBlueprintSeedData.blueprints)
        blueprint.id: ArcBlueprintState(
          blueprintId: blueprint.id,
          owned: !projectedBlueprints.containsKey(blueprint.id),
          dupesOwned: 0,
          priorityRank: projectedBlueprints.containsKey(blueprint.id)
              ? math.max(1, 7 - projectedBlueprints[blueprint.id]!.clamp(1, 6))
              : 0,
          updatedAt: null,
        ),
    };
  }

  ArcRaidRecommendationSet recommend({
    required ArcSquadRaidBundle bundle,
    required ArcRegionalMapConditionsSnapshot regionalSnapshot,
    required ArcServerRegion region,
    DateTime? nowUtc,
  }) {
    final now = (nowUtc ?? regionalSnapshot.serverNowUtc).toUtc();
    final allObjectives = bundle.projections.values
        .expand((projection) => projection.objectives)
        .toList(growable: false);
    if (allObjectives.isEmpty) return ArcRaidRecommendationSet.empty;

    final overlapCounts = <String, int>{};
    final ownerCounts = <String, int>{};
    for (final objective in allObjectives) {
      overlapCounts.update(
        objective.overlapKey,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      ownerCounts.update(
        objective.ownerUid,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final goals = <ArcRaiderGoal>[];
    for (final objective in allObjectives) {
      if (objective.mapNames.isEmpty) continue;
      final overlap = overlapCounts[objective.overlapKey] ?? 1;
      final ownerCount = math.max(1, ownerCounts[objective.ownerUid] ?? 1);
      var weight = objective.baseWeight;
      switch (bundle.session.fairnessMode) {
        case ArcSquadRaidFairnessMode.balancedSquad:
          weight *= 6.0 / ownerCount;
          break;
        case ArcSquadRaidFairnessMode.leaderPriorities:
          weight *= objective.ownerUid == bundle.session.leaderUid ? 1.35 : 0.9;
          break;
        case ArcSquadRaidFairnessMode.maximumSquadValue:
          break;
      }
      weight *= _overlapModifier(objective.classification, overlap);

      goals.add(
        ArcRaiderGoal(
          id: 'squad-goal:${objective.ownerUid}:${objective.id}',
          label: objective.label,
          source: _goalSource(objective.system),
          cooperation: _cooperation(objective.classification),
          priority: weight.round().clamp(1, 5),
          mapNames: objective.mapNames,
          conditionNames: objective.conditionNames,
          conditionFit: objective.conditionNames.isEmpty
              ? ArcRaiderGoalConditionFit.none
              : ArcRaiderGoalConditionFit.preferred,
          routeConfidence: ArcRaiderGoalRouteConfidence.strong,
          reason: 'Squad progression objective.',
        ),
      );
    }
    if (goals.isEmpty) return ArcRaidRecommendationSet.empty;

    final candidates = <ArcRaidCandidate>[
      for (final map in _standardMaps)
        ArcRaidCandidate(
          mapName: map,
          conditionName: ArcMapConditions.noSpecialCondition.label,
          isLive: true,
        ),
    ];

    for (final entry in regionalSnapshot.entries) {
      final window = entry.windowFor(region);
      if (window == null || !window.endUtc.isAfter(now)) continue;
      candidates.add(
        ArcRaidCandidate(
          mapName: entry.mapDisplayName,
          conditionName: entry.conditionName,
          isLive: window.isActiveAt(now),
          startUtc: window.startUtc,
          endUtc: window.endUtc,
        ),
      );
    }

    return const ArcRaidRecommendationEngine().build(
      goals: goals,
      candidates: candidates,
      nowUtc: now,
    );
  }

  double _overlapModifier(ArcSquadObjectiveClass classification, int overlap) {
    if (overlap <= 1) return 1;
    return switch (classification) {
      ArcSquadObjectiveClass.sharedCompletion => 1 + (overlap - 1) * 0.5,
      ArcSquadObjectiveClass.repeatableEncounter => 1 + (overlap - 1) * 0.35,
      ArcSquadObjectiveClass.renewableResource => 1 + (overlap - 1) * 0.25,
      ArcSquadObjectiveClass.scarceCompetitive => math.max(
        0.45,
        1 - (overlap - 1) * 0.28,
      ),
      ArcSquadObjectiveClass.individualLoot => 1,
      ArcSquadObjectiveClass.oneOffInteraction => 1 + (overlap - 1) * 0.4,
    };
  }

  ArcRaiderGoalSource _goalSource(String system) {
    final normalized = system.toLowerCase();
    if (normalized.contains('quest')) return ArcRaiderGoalSource.quest;
    if (normalized.contains('blueprint')) return ArcRaiderGoalSource.blueprint;
    if (normalized.contains('bench')) return ArcRaiderGoalSource.bench;
    if (normalized.contains('scrappy')) return ArcRaiderGoalSource.crafting;
    return ArcRaiderGoalSource.project;
  }

  ArcRaiderGoalCooperation _cooperation(ArcSquadObjectiveClass classification) {
    return switch (classification) {
      ArcSquadObjectiveClass.scarceCompetitive =>
        ArcRaiderGoalCooperation.scarceSharedLoot,
      ArcSquadObjectiveClass.individualLoot =>
        ArcRaiderGoalCooperation.personal,
      _ => ArcRaiderGoalCooperation.cooperative,
    };
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
