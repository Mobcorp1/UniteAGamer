import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_dynamic_operations_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_operations_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';

void main() {
  group('ArcDynamicOperationsEngine', () {
    test('hides completed operations from the generated rotation', () {
      final completed = ArcOperationsSeedData.dailyOperations.singleWhere(
        (task) => task.id == 'daily_refresh_listing',
      );
      final state = ArcOperationsUserState(
        progressById: {
          completed.id: ArcOperationProgress(
            operationId: completed.id,
            progress: completed.target,
            target: completed.target,
            claimed: true,
            seasonId: ArcSeasonDefaults.closedBetaSeasonOne,
          ),
        },
        inventory: const [],
        equippedCosmetics: const ArcEquippedCosmetics(),
      );

      final plan = ArcDynamicOperationsEngine.generate(
        userState: state,
        cadence: ArcOperationCadence.daily,
        now: DateTime.utc(2026, 7, 22),
      );

      expect(plan.hiddenCompletedCount, 1);
      expect(plan.tasks.map((task) => task.id), isNot(contains(completed.id)));
    });

    test('ranks ready-to-claim operations before unfinished tasks', () {
      final ready = ArcOperationsSeedData.dailyOperations.singleWhere(
        (task) => task.id == 'daily_verify_intel',
      );
      final state = ArcOperationsUserState(
        progressById: {
          ready.id: ArcOperationProgress(
            operationId: ready.id,
            progress: ready.target,
            target: ready.target,
            seasonId: ArcSeasonDefaults.closedBetaSeasonOne,
          ),
        },
        inventory: const [],
        equippedCosmetics: const ArcEquippedCosmetics(),
      );

      final plan = ArcDynamicOperationsEngine.generate(
        userState: state,
        cadence: ArcOperationCadence.daily,
        now: DateTime.utc(2026, 7, 22),
      );

      expect(plan.tasks.first.id, ready.id);
      expect(plan.priorityLabel, 'CLAIM REWARD');
    });

    test(
      'uses admin tuning for limits, target overrides and held templates',
      () {
        final config = ArcOperationTuningConfig.fromMap(const {
          'cadenceLimits': {'daily': 2},
          'taskTargetOverrides': {'daily_update_availability': 2},
          'disabledTaskIds': ['daily_verify_intel'],
          'featuredTaskIds': ['daily_update_availability'],
        });

        final plan = ArcDynamicOperationsEngine.generate(
          userState: ArcOperationsUserState.empty,
          cadence: ArcOperationCadence.daily,
          config: config,
          now: DateTime.utc(2026, 7, 22),
        );

        expect(plan.tasks, hasLength(2));
        expect(
          plan.tasks.map((task) => task.id),
          isNot(contains('daily_verify_intel')),
        );
        expect(plan.tasks.first.id, 'daily_update_availability');
        expect(plan.tasks.first.target, 2);
        expect(plan.disabledCount, 1);
      },
    );

    test('keeps reputation and community operations free-tier earnable', () {
      for (final task in ArcOperationsSeedData.allOperations) {
        expect(
          task.accessTier,
          ArcOperationAccessTier.free,
          reason: '${task.id} must not make reputation pay-to-win.',
        );
      }

      final plan = ArcDynamicOperationsEngine.generate(
        userState: ArcOperationsUserState.empty,
        cadence: ArcOperationCadence.weekly,
        now: DateTime.utc(2026, 7, 22),
      );

      expect(plan.fairnessLabel, 'FREE-TIER EARNABLE');
    });
  });

  group('ArcOperationTask reward persistence policy', () {
    test('keeps lifetime, beta and community rewards permanent', () {
      final lifetime = ArcOperationsSeedData.lifetimeOperations.singleWhere(
        (task) => task.id == 'life_first_trade',
      );
      final beta = ArcOperationsSeedData.betaOperations.singleWhere(
        (task) => task.id == 'beta_feedback',
      );
      final guardian = ArcOperationsSeedData.monthlyOperations.singleWhere(
        (task) => task.id == 'monthly_guardian',
      );
      final daily = ArcOperationsSeedData.dailyOperations.singleWhere(
        (task) => task.id == 'daily_refresh_listing',
      );

      expect(lifetime.grantsPermanentRewards, isTrue);
      expect(beta.grantsPermanentRewards, isTrue);
      expect(guardian.grantsPermanentRewards, isTrue);
      expect(daily.grantsPermanentRewards, isFalse);
    });
  });

  group('ArcOperationTuningConfig', () {
    test('round-trips safe admin configuration', () {
      const config = ArcOperationTuningConfig(
        enabled: false,
        seasonId: 'closed-beta-season-2',
        cadenceLimits: {ArcOperationCadence.daily: 1},
        categoryWeights: {ArcOperationCategory.trading: 250},
        taskWeightOverrides: {'daily_refresh_listing': 300},
        taskTargetOverrides: {'weekly_trade_run': 4},
        disabledTaskIds: {'daily_verify_intel'},
        featuredTaskIds: {'weekly_trade_run'},
      );

      final restored = ArcOperationTuningConfig.fromMap(config.toMap());

      expect(restored.enabled, isFalse);
      expect(restored.seasonId, 'closed-beta-season-2');
      expect(restored.limitFor(ArcOperationCadence.daily), 1);
      expect(restored.categoryWeight(ArcOperationCategory.trading), 250);
      expect(restored.taskWeightOverrides['daily_refresh_listing'], 300);
      expect(restored.taskTargetOverrides['weekly_trade_run'], 4);
      expect(restored.disabledTaskIds, contains('daily_verify_intel'));
      expect(restored.featuredTaskIds, contains('weekly_trade_run'));
    });
  });
}
