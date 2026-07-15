import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_operations_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_reward_eligibility.dart';

void main() {
  const engine = ArcRewardEligibilityEngine();

  group('ArcRewardEligibilityEngine', () {
    test('grants beta access only from beta proof', () {
      final result = engine.evaluate(
        userData: const {'closedBetaParticipant': true},
      );

      expect(result.rewardIds, contains('beta_access'));
      expect(result.rewardIds, isNot(contains('founding_raider')));
    });

    test('gates founder rewards behind founder or early supporter proof', () {
      final normal = engine.evaluate(userData: const {});
      final founder = engine.evaluate(
        userData: const {
          'roles': ['founder'],
        },
      );

      expect(normal.rewardIds, isNot(contains('founding_raider')));
      expect(founder.rewardIds, contains('founding_raider'));
    });

    test('backfills closed beta veteran rewards from durable login count', () {
      final result = engine.evaluate(telemetryData: const {'loginEvents': 10});

      expect(
        result.rewardIds,
        containsAll(['og_legend', 'inner_circle', 'beta_command_banner']),
      );
    });
  });

  group('ArcOperationsSeedData reward gates', () {
    test('first loadout no longer grants the founder badge', () {
      final loadoutTask = ArcOperationsSeedData.betaOperations.singleWhere(
        (task) => task.id == 'beta_loadout_saved',
      );

      expect(
        loadoutTask.rewards.map((reward) => reward.id),
        isNot(contains('founding_raider')),
      );
    });
  });
}
