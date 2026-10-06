import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_tier.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_squad_raid_planning_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_squad_raid_projection_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_squad_raid_models.dart';

void main() {
  const projectionEngine = ArcSquadRaidProjectionEngine();
  const planningEngine = ArcSquadRaidPlanningEngine();

  test('objective contribution depth follows subscription tier', () {
    expect(
      ArcSquadRaidProjectionEngine.objectiveLimitForTier(
        UagSubscriptionTier.free,
      ),
      1,
    );
    expect(
      ArcSquadRaidProjectionEngine.objectiveLimitForTier(
        UagSubscriptionTier.essential,
      ),
      5,
    );
    expect(
      ArcSquadRaidProjectionEngine.objectiveLimitForTier(
        UagSubscriptionTier.premium,
      ),
      24,
    );
  });

  test(
    'free projection clamps a larger Blueprint priority list to one goal',
    () {
      final states = <String, ArcBlueprintState>{
        for (var i = 0; i < 4; i++)
          'blueprint-$i': ArcBlueprintState(
            blueprintId: 'blueprint-$i',
            owned: false,
            dupesOwned: 0,
            priorityRank: i + 1,
            updatedAt: null,
          ),
      };

      final projection = projectionEngine.build(
        ownerUid: 'free-user',
        ownerLabel: 'Free Raider',
        tier: UagSubscriptionTier.free,
        blueprintStates: states,
        raidPlannerTargets: const [],
        scrappyStates: const {},
        progressionRecords: ArcProgressionRecords.empty,
      );

      expect(projection.objectiveLimit, 1);
      expect(projection.objectives.length, lessThanOrEqualTo(1));
    },
  );

  test('scarce overlap is penalised while repeatable overlap is boosted', () {
    ArcSquadRaidProjection projection(
      String uid,
      ArcSquadObjectiveClass classification,
    ) {
      return ArcSquadRaidProjection(
        ownerUid: uid,
        ownerLabel: uid,
        tier: UagSubscriptionTier.premium,
        objectiveLimit: 24,
        objectives: <ArcSquadRaidObjectiveProjection>[
          ArcSquadRaidObjectiveProjection(
            id: 'same-target',
            ownerUid: uid,
            ownerLabel: uid,
            label: 'Target',
            system: 'Bench',
            itemName: 'Target',
            missingCount: 1,
            classification: classification,
            baseWeight: 5,
          ),
        ],
      );
    }

    ArcSquadRaidBundle bundle(ArcSquadObjectiveClass classification) {
      return ArcSquadRaidBundle(
        session: const ArcSquadRaidSession(
          id: 'squad',
          leaderUid: 'a',
          leaderLabel: 'A',
          memberUids: <String>['a', 'b'],
          memberLabels: <String, String>{'a': 'A', 'b': 'B'},
          fairnessMode: ArcSquadRaidFairnessMode.maximumSquadValue,
          status: 'active',
        ),
        projections: <String, ArcSquadRaidProjection>{
          'a': projection('a', classification),
          'b': projection('b', classification),
        },
      );
    }

    final scarce = planningEngine.objectivesForMap(
      bundle: bundle(ArcSquadObjectiveClass.scarceCompetitive),
      mapDisplayName: 'Spaceport',
    );
    final repeatable = planningEngine.objectivesForMap(
      bundle: bundle(ArcSquadObjectiveClass.repeatableEncounter),
      mapDisplayName: 'Spaceport',
    );

    expect(scarce, hasLength(2));
    expect(repeatable, hasLength(2));
    expect(repeatable.first.weight, greaterThan(scarce.first.weight));
  });
}
