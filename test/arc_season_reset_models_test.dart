import 'package:flutter_test/flutter_test.dart';
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
      expect(restored.seasonHistory.single.rewardCount, 4);
    });
  });

  group('ArcSeasonResetPolicy', () {
    test('classifies tracker, reward and recalculated systems', () {
      final impacts = ArcSeasonResetPolicy.impacts(
        scrappyStateCount: 4,
        questStateCount: 5,
        benchStateCount: 6,
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
  });
}
