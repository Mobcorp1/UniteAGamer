import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_cosmetic_equipability.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_season_reset_models.dart';

void main() {
  group('ArcSeasonState', () {
    test('creates a closed-beta baseline season state', () {
      final now = DateTime.utc(2026, 7, 15);
      final state = ArcSeasonState.initial(now: now);

      expect(
        state.currentSeasonId,
        ArcSeasonResetPolicy.defaultCurrentSeasonId,
      );
      expect(state.currentSeasonStartedAt, now);
      expect(state.resetStatus, ArcSeasonResetStatus.idle);
      expect(state.resetVersion, 0);
    });

    test('round-trips reset history and last reset state', () {
      final completedAt = DateTime.utc(2026, 7, 15, 12);
      final state = ArcSeasonState(
        currentSeasonId: 'closed-beta-season-2',
        lastCompletedSeasonId: 'closed-beta-season-1',
        lastResetId: 'reset-1',
        lastResetAt: completedAt,
        resetVersion: 1,
        resetStatus: ArcSeasonResetStatus.completed,
        seasonHistory: [
          ArcSeasonHistoryEntry(
            seasonId: 'closed-beta-season-1',
            resetId: 'reset-1',
            completedAt: completedAt,
            scrappyStateCount: 3,
            questStateCount: 2,
            benchStateCount: 1,
            operationProgressCount: 5,
            rewardCount: 4,
          ),
        ],
      );

      final restored = ArcSeasonState.fromMap(state.toMap());

      expect(restored.currentSeasonId, 'closed-beta-season-2');
      expect(restored.lastCompletedSeasonId, 'closed-beta-season-1');
      expect(restored.lastResetId, 'reset-1');
      expect(restored.resetVersion, 1);
      expect(restored.resetStatus, ArcSeasonResetStatus.completed);
      expect(restored.seasonHistory.single.scrappyStateCount, 3);
      expect(restored.seasonHistory.single.operationProgressCount, 5);
      expect(restored.seasonHistory.single.rewardCount, 4);
    });
  });

  group('ArcSeasonResetPolicy', () {
    test('classifies tracker, reward and recalculated systems', () {
      final impacts = ArcSeasonResetPolicy.impacts(
        scrappyStateCount: 4,
        questStateCount: 5,
        benchStateCount: 6,
        operationProgressCount: 3,
        rewardCount: 7,
      );

      final byId = {for (final impact in impacts) impact.id: impact};

      expect(
        byId['profile']?.classification,
        ArcSeasonResetClassification.preserved,
      );
      expect(
        byId['scrappy']?.classification,
        ArcSeasonResetClassification.reset,
      );
      expect(byId['scrappy']?.itemCount, 4);
      expect(byId['quests']?.itemCount, 5);
      expect(byId['benches']?.itemCount, 6);
      expect(
        byId['operations']?.classification,
        ArcSeasonResetClassification.reset,
      );
      expect(byId['operations']?.itemCount, 3);
      expect(byId['rewards']?.itemCount, 7);
      expect(
        byId['command-centre']?.classification,
        ArcSeasonResetClassification.recalculated,
      );
      expect(
        byId['temporary-state']?.classification,
        ArcSeasonResetClassification.manualReconfirm,
      );
    });
  });

  group('ArcOperationProgress season metadata', () {
    test('round-trips the source season for reset archiving', () {
      final progress = ArcOperationProgress(
        operationId: 'daily_trade',
        progress: 2,
        target: 3,
        seasonId: 'closed-beta-season-1',
      );

      final restored = ArcOperationProgress.fromMap(
        progress.operationId,
        progress.toMap(),
      );

      expect(restored.operationId, 'daily_trade');
      expect(restored.progress, 2);
      expect(restored.target, 3);
      expect(restored.seasonId, 'closed-beta-season-1');
    });
  });

  group('ArcOperationTask reset classification', () {
    test(
      'keeps lifetime operations permanent and resets seasonal cadences',
      () {
        const reward = ArcOperationReward(
          id: 'operation_credit',
          label: 'Operation Credit',
          type: ArcOperationRewardType.operationCredit,
        );

        const daily = ArcOperationTask(
          id: 'daily_trade',
          title: 'Daily Trade',
          description: 'Create a trade.',
          cadence: ArcOperationCadence.daily,
          category: ArcOperationCategory.trading,
          target: 1,
          rewards: [reward],
        );
        const weekly = ArcOperationTask(
          id: 'weekly_trade',
          title: 'Weekly Trade',
          description: 'Complete weekly trade work.',
          cadence: ArcOperationCadence.weekly,
          category: ArcOperationCategory.trading,
          target: 3,
          rewards: [reward],
        );
        const lifetime = ArcOperationTask(
          id: 'lifetime_trade',
          title: 'Lifetime Trade',
          description: 'Complete lifetime trade work.',
          cadence: ArcOperationCadence.lifetime,
          category: ArcOperationCategory.trading,
          target: 10,
          rewards: [reward],
        );

        expect(daily.resetsWithSeason, isTrue);
        expect(weekly.repeatableBySeason, isTrue);
        expect(lifetime.resetsWithSeason, isFalse);
        expect(lifetime.permanentProgress, isTrue);
      },
    );
  });

  group('ArcRewardInventoryItem season metadata', () {
    test('stores source season and permanent equipability defaults', () {
      const reward = ArcOperationReward(
        id: 'beta_badge',
        label: 'Beta Badge',
        type: ArcOperationRewardType.badge,
        rarity: ArcCosmeticRarity.closedBeta,
        betaExclusive: true,
      );

      final item = ArcRewardInventoryItem.fromReward(
        reward,
        sourceSeasonId: 'closed-beta-season-1',
        sourceOperationId: 'beta_first_login',
      );
      final restored = ArcRewardInventoryItem.fromMap(
        item.rewardId,
        item.toMap(),
      );

      expect(restored.sourceSeasonId, 'closed-beta-season-1');
      expect(restored.sourceOperationId, 'beta_first_login');
      expect(restored.permanent, isTrue);
      expect(restored.historicalVisible, isTrue);
      expect(restored.equipableAfterSeason, isTrue);
      expect(restored.currentSeasonUnlock, isTrue);
    });

    test('can represent historical season-only rewards safely', () {
      const reward = ArcOperationReward(
        id: 'season_banner',
        label: 'Season Banner',
        type: ArcOperationRewardType.profileBanner,
      );

      final item = ArcRewardInventoryItem.fromReward(
        reward,
        sourceSeasonId: 'closed-beta-season-1',
        permanent: false,
        equipableAfterSeason: false,
        currentSeasonUnlock: false,
      );
      final restored = ArcRewardInventoryItem.fromMap(
        item.rewardId,
        item.toMap(),
      );

      expect(restored.permanent, isFalse);
      expect(restored.historicalVisible, isTrue);
      expect(restored.equipableAfterSeason, isFalse);
      expect(restored.currentSeasonUnlock, isFalse);
    });

    test('blocks expired season-only cosmetics from being equipped', () {
      const reward = ArcOperationReward(
        id: 'season_frame',
        label: 'Season Frame',
        type: ArcOperationRewardType.profileFrame,
      );

      final current = ArcRewardInventoryItem.fromReward(
        reward,
        sourceSeasonId: 'closed-beta-season-2',
        permanent: false,
        equipableAfterSeason: false,
        currentSeasonUnlock: true,
      );
      final expired = ArcRewardInventoryItem.fromReward(
        reward,
        sourceSeasonId: 'closed-beta-season-1',
        permanent: false,
        equipableAfterSeason: false,
        currentSeasonUnlock: false,
      );

      expect(
        ArcCosmeticEquipability.canEquip(
          current,
          currentSeasonId: 'closed-beta-season-2',
        ),
        isTrue,
      );
      expect(
        ArcCosmeticEquipability.canEquip(
          expired,
          currentSeasonId: 'closed-beta-season-2',
        ),
        isFalse,
      );
      expect(
        ArcCosmeticEquipability.isExpiredSeasonOnly(
          expired,
          currentSeasonId: 'closed-beta-season-2',
        ),
        isTrue,
      );
    });
  });
}
