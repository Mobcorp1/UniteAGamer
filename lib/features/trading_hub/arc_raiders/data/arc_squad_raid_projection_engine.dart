import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_tier.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_intel_seed.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_progression_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_objective_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_squad_raid_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/models/raid_planner_models.dart';

class ArcSquadRaidProjectionEngine {
  const ArcSquadRaidProjectionEngine();

  static int objectiveLimitForTier(UagSubscriptionTier tier) => switch (tier) {
    UagSubscriptionTier.free => 1,
    UagSubscriptionTier.essential => 5,
    UagSubscriptionTier.premium => 24,
  };

  ArcSquadRaidProjection build({
    required String ownerUid,
    required String ownerLabel,
    required UagSubscriptionTier tier,
    required Map<String, ArcBlueprintState> blueprintStates,
    required List<RaidBlueprintTarget> raidPlannerTargets,
    required Map<String, ArcScrappyState> scrappyStates,
    required ArcProgressionRecords progressionRecords,
  }) {
    final limit = objectiveLimitForTier(tier);
    final progression = const ArcProgressionEngine().build(
      scrappyStates: scrappyStates,
      records: progressionRecords,
    );
    final trackerObjectives = const ArcRaidObjectiveIntelligenceEngine()
        .trackedObjectives(
          progression: progression,
          scrappyStates: scrappyStates,
        );

    final candidates = <ArcSquadRaidObjectiveProjection>[];
    final blueprintIdsAdded = <String>{};

    final orderedTargets =
        raidPlannerTargets
            .where(
              (target) => blueprintStates[target.blueprintId]?.owned != true,
            )
            .toList(growable: false)
          ..sort((a, b) {
            final tierCompare = a.tier.index.compareTo(b.tier.index);
            if (tierCompare != 0) return tierCompare;
            return a.rank.compareTo(b.rank);
          });

    for (final target in orderedTargets) {
      final blueprint = _blueprint(target.blueprintId);
      if (blueprint == null) continue;
      blueprintIdsAdded.add(blueprint.id);
      candidates.add(
        _blueprintObjective(
          ownerUid: ownerUid,
          ownerLabel: ownerLabel,
          blueprint: blueprint,
          baseWeight: switch (target.tier) {
            RaidTargetTier.activeHunt => math.max(
              4.8,
              6.4 - target.rank * 0.28,
            ),
            RaidTargetTier.nextUp => math.max(3.5, 4.6 - target.rank * 0.18),
            RaidTargetTier.later => 2.2,
          },
        ),
      );
    }

    final priorityStates =
        blueprintStates.values
            .where(
              (state) =>
                  !state.owned &&
                  state.priorityRank > 0 &&
                  !blueprintIdsAdded.contains(state.blueprintId),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final rankCompare = a.priorityRank.compareTo(b.priorityRank);
            if (rankCompare != 0) return rankCompare;
            return a.blueprintId.compareTo(b.blueprintId);
          });

    for (final state in priorityStates) {
      final blueprint = _blueprint(state.blueprintId);
      if (blueprint == null) continue;
      candidates.add(
        _blueprintObjective(
          ownerUid: ownerUid,
          ownerLabel: ownerLabel,
          blueprint: blueprint,
          baseWeight: math.max(3.2, 5.1 - state.priorityRank * 0.3),
        ),
      );
    }

    for (final objective in trackerObjectives.where(
      (objective) => objective.missingCount > 0,
    )) {
      final text =
          '${objective.system} ${objective.itemName} ${objective.label} '
          '${objective.sourceHint ?? ''} ${objective.reason}';
      candidates.add(
        ArcSquadRaidObjectiveProjection(
          id: 'tracker:${objective.id}',
          ownerUid: ownerUid,
          ownerLabel: ownerLabel,
          label: objective.label,
          system: objective.system,
          itemName: objective.itemName,
          missingCount: objective.missingCount,
          sourceHint: objective.sourceHint ?? objective.reason,
          blueprintId: objective.blueprintId,
          mapNames: _mapsFromText(text),
          conditionNames: _conditionsFromText(text),
          classification: _classify(
            system: objective.system,
            text: text,
            isBlueprint: objective.blueprintId?.isNotEmpty == true,
          ),
          baseWeight: _trackerWeight(objective),
        ),
      );
    }

    final deduped = <String, ArcSquadRaidObjectiveProjection>{};
    for (final objective in candidates) {
      final key = objective.blueprintId?.trim().isNotEmpty == true
          ? 'blueprint:${objective.blueprintId}'
          : objective.overlapKey;
      final current = deduped[key];
      if (current == null || objective.baseWeight > current.baseWeight) {
        deduped[key] = objective;
      }
    }

    final ordered = deduped.values.toList(growable: false)
      ..sort((a, b) {
        final weightCompare = b.baseWeight.compareTo(a.baseWeight);
        if (weightCompare != 0) return weightCompare;
        final missingCompare = b.missingCount.compareTo(a.missingCount);
        if (missingCompare != 0) return missingCompare;
        return a.label.compareTo(b.label);
      });

    return ArcSquadRaidProjection(
      ownerUid: ownerUid,
      ownerLabel: ownerLabel,
      tier: tier,
      objectiveLimit: limit,
      objectives: List<ArcSquadRaidObjectiveProjection>.unmodifiable(
        ordered.take(limit),
      ),
      sharing: ArcRaidObjectiveSharing.allChosenRaidPlanObjectives,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  ArcSquadRaidObjectiveProjection _blueprintObjective({
    required String ownerUid,
    required String ownerLabel,
    required ArcBlueprint blueprint,
    required double baseWeight,
  }) {
    final hint = ArcBlueprintIntelLibrary.resolve(blueprint);
    final maps = ArcBlueprintIntelLibrary.isAllMaps(hint.likelyMaps)
        ? const <String>[]
        : List<String>.unmodifiable(hint.likelyMaps);
    return ArcSquadRaidObjectiveProjection(
      id: 'blueprint:${blueprint.id}',
      ownerUid: ownerUid,
      ownerLabel: ownerLabel,
      label: '${blueprint.name} Blueprint',
      system: 'Blueprint',
      itemName: blueprint.name,
      missingCount: 1,
      sourceHint: hint.tip,
      blueprintId: blueprint.id,
      mapNames: maps,
      conditionNames: ArcBlueprintIntelLibrary.playableConditions(
        hint.bestConditions,
      ).toList(growable: false),
      classification: ArcSquadObjectiveClass.scarceCompetitive,
      baseWeight: baseWeight,
    );
  }

  ArcBlueprint? _blueprint(String id) {
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (blueprint.id == id) return blueprint;
    }
    return null;
  }

  double _trackerWeight(ArcRaidObjective objective) {
    final system = objective.system.toLowerCase();
    final base = system.contains('quest')
        ? 6.2
        : system.contains('bench')
        ? 5.2
        : system.contains('scrappy')
        ? 4.7
        : 3.6;
    return base + math.min(2.0, objective.missingCount * 0.08);
  }

  ArcSquadObjectiveClass _classify({
    required String system,
    required String text,
    required bool isBlueprint,
  }) {
    if (isBlueprint || system.toLowerCase().contains('blueprint')) {
      return ArcSquadObjectiveClass.scarceCompetitive;
    }
    final normalized = text.toLowerCase();

    const repeatable = <String>[
      'leaper',
      'bastion',
      'rocketeer',
      'bombardier',
      'sentinel',
      'hornet',
      'wasp',
      'snitch',
      'arc core',
      'arc cell',
      'pulse unit',
    ];
    if (repeatable.any(normalized.contains)) {
      return ArcSquadObjectiveClass.repeatableEncounter;
    }

    const renewable = <String>[
      'nature',
      'organic',
      'mushroom',
      'lemon',
      'apricot',
      'olive',
      'prickly pear',
      'fruit',
      'plant',
      'greenhouse',
      'wooded',
      'lush blooms',
    ];
    if (renewable.any(normalized.contains)) {
      return ArcSquadObjectiveClass.renewableResource;
    }

    if (system.toLowerCase().contains('quest')) {
      return ArcSquadObjectiveClass.sharedCompletion;
    }

    if (normalized.contains('interact') ||
        normalized.contains('terminal') ||
        normalized.contains('activate') ||
        normalized.contains('scan ')) {
      return ArcSquadObjectiveClass.oneOffInteraction;
    }

    return ArcSquadObjectiveClass.individualLoot;
  }

  List<String> _mapsFromText(String text) {
    const maps = <String>[
      'The Blue Gate',
      'Buried City',
      'Dam Battlegrounds',
      'Spaceport',
      'Stella Montis',
      'Riven Tides',
    ];
    final normalized = text.toLowerCase();
    return maps
        .where((map) => normalized.contains(map.toLowerCase()))
        .toList(growable: false);
  }

  List<String> _conditionsFromText(String text) {
    const conditions = <String>[
      'Night Raid',
      'Hurricane',
      'Electromagnetic Storm',
      'Lush Blooms',
      'Harvester',
      'Locked Gate',
      'Hidden Bunker',
      'Beachcombing',
      'Close Scrutiny',
      'Cold Snap',
    ];
    final normalized = text.toLowerCase();
    return conditions
        .where((condition) => normalized.contains(condition.toLowerCase()))
        .toList(growable: false);
  }
}
