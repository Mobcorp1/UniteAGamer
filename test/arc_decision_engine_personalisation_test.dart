import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_decision_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_bench_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_nomadic_trader_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_quest_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_resource_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_listing_queues_screen.dart';

void main() {
  group('ArcDecisionEngine personalisation', () {
    test('leaves active surfaces empty when every tracked signal is quiet', () {
      final state = const ArcDecisionEngine().build(
        blueprintStateKnown: true,
        ownedBlueprints: 10,
        totalBlueprints: 10,
        missingBlueprints: 0,
        duplicateBlueprints: 0,
        prioritizedMissingBlueprints: const [],
        favouriteLoadout: _completeLoadout,
        operationsState: ArcOperationsUserState.empty,
        tradeActivity: ArcCommandTradeActivity.empty,
        readyOperations: 0,
        inProgressOperations: 0,
        availableOperations: 0,
        questIntel: _quietQuest,
        benchIntel: _quietBench,
        traderIntel: _quietTrader,
        resourceIntel: _quietResources,
      );

      expect(state.primaryMission.status, ArcCommandStatus.success);
      expect(state.rankedObjectives, isEmpty);
      expect(state.blockers, isEmpty);
      expect(state.smartRecommendations, isEmpty);
      expect(state.tradeAssistedOpportunities, isEmpty);
      expect(state.resourceActions, isEmpty);
    });

    test('ranks the strongest unfinished action first', () {
      final state = const ArcDecisionEngine().build(
        blueprintStateKnown: true,
        ownedBlueprints: 9,
        totalBlueprints: 10,
        missingBlueprints: 1,
        duplicateBlueprints: 0,
        prioritizedMissingBlueprints: const ['Anvil Splitter'],
        favouriteLoadout: _completeLoadout,
        operationsState: ArcOperationsUserState.empty,
        tradeActivity: const ArcCommandTradeActivity(
          communityListings: 0,
          myListings: 1,
          activeMyListings: 0,
          pendingOffers: 0,
          acceptedOffers: 0,
          activeSessions: 0,
          readySessions: 0,
          unreadNotifications: 0,
          activeListingQueues: 1,
          releasableListingQueues: 1,
        ),
        readyOperations: 1,
        inProgressOperations: 0,
        availableOperations: 3,
        questIntel: _quietQuest,
        benchIntel: _quietBench,
        traderIntel: _quietTrader,
        resourceIntel: _quietResources,
      );

      expect(state.rankedObjectives.first.title, 'Claim Operation Rewards');
      expect(
        state.rankedObjectives.map((objective) => objective.action.routeName),
        contains(TradingListingQueuesScreen.routeName),
      );
    });

    test('adds Raid Intelligence as a current blueprint-run action', () {
      final raidIntel = const ArcRaidIntelligenceEngine().build(
        mapId: 'blue_gate',
      );
      final state = const ArcDecisionEngine().build(
        blueprintStateKnown: true,
        ownedBlueprints: 9,
        totalBlueprints: 10,
        missingBlueprints: 1,
        duplicateBlueprints: 0,
        prioritizedMissingBlueprints: const ['Anvil Splitter'],
        favouriteLoadout: _completeLoadout,
        operationsState: ArcOperationsUserState.empty,
        tradeActivity: ArcCommandTradeActivity.empty,
        readyOperations: 0,
        inProgressOperations: 0,
        availableOperations: 0,
        questIntel: _quietQuest,
        benchIntel: _quietBench,
        traderIntel: _quietTrader,
        resourceIntel: _quietResources,
        raidIntelligence: raidIntel,
      );

      expect(
        state.rankedObjectives.map((objective) => objective.title),
        contains('Generate Blueprint Run'),
      );
      expect(
        state.rankedObjectives.map((objective) => objective.action.routeName),
        contains(ArcRaidIntelligenceScreen.routeName),
      );
    });
  });
}

final _completeLoadout = ArcSavedLoadout(
  id: 'kit',
  name: 'Closed Beta Kit',
  category: ArcLoadoutCategory.saved,
  playStyle: ArcPlayerPlayStyle.balanced,
  augment: 'Survivor',
  primaryWeapon: 'Anvil',
  primaryAttachments: const [],
  secondaryWeapon: 'Stitcher',
  secondaryAttachments: const [],
  equipment: const ['Grenade'],
  consumables: const [],
  quickUse: const ['Shield Recharger'],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

const _quietQuest = ArcQuestIntelligence(
  trackingKnown: true,
  questLabel: 'Quest Chain',
  trader: 'Shani',
  questName: 'No active quest',
  statusLabel: 'Stable',
  summary: 'All tracked quest requirements are complete.',
  recommendation: 'No quest blocker is waiting.',
  actionLabel: 'Quest Tracker',
  status: ArcCommandStatus.success,
  completionPercent: 100,
  completedItems: 1,
  totalItems: 1,
  requiredCount: 1,
  collectedCount: 1,
  missingCount: 0,
  readyToComplete: false,
  hasBlocker: false,
  missingItems: [],
);

const _quietBench = ArcBenchIntelligence(
  trackingKnown: true,
  station: 'Gunsmith',
  upgradeLabel: 'Gunsmith',
  statusLabel: 'Stable',
  summary: 'All tracked bench requirements are complete.',
  recommendation: 'No bench blocker is waiting.',
  actionLabel: 'Bench Tracker',
  status: ArcCommandStatus.success,
  completionPercent: 100,
  completedResources: 1,
  totalResources: 1,
  requiredCount: 1,
  collectedCount: 1,
  missingCount: 0,
  readyToUpgrade: false,
  hasBlocker: false,
  missingResources: [],
  currentLevelLabel: 'Lv. 5',
);

const _quietTrader = ArcNomadicTraderIntelligence(
  trackingKnown: true,
  goalName: 'Weekly Stock',
  statusLabel: 'Stable',
  summary: 'No priority trader purchase is waiting.',
  recommendation: 'No trader action is waiting.',
  actionLabel: 'Nomadic Trader',
  status: ArcCommandStatus.success,
  completionPercent: 100,
  targetValue: 0,
  currentValue: 0,
  remainingValue: 0,
  trackedPurchaseCount: 0,
  completedPurchaseCount: 0,
  affordablePurchaseCount: 0,
  nearlyAffordablePurchaseCount: 0,
  tradeNeedLabels: [],
  topPurchases: [],
);

const _quietInventory = ArcInventoryIntelligence(
  pressureLabel: 'Stable',
  pressureDetail: 'No tracked inventory pressure.',
  status: ArcCommandStatus.success,
  safeTradeCandidates: [],
  safeSellCandidates: [],
  protectedResources: [],
  futureRequirementLabels: [],
);

const _quietResources = ArcResourceIntelligence(
  trackingKnown: true,
  statusLabel: 'Stable',
  summary: 'No tracked resource blockers are waiting.',
  recommendation: 'No resource action is waiting.',
  actionLabel: 'Resources',
  status: ArcCommandStatus.success,
  totalTrackedResources: 0,
  totalRequiredResources: 0,
  totalMissingResources: 0,
  totalDuplicateResources: 0,
  entries: [],
  highestPriorityResources: [],
  lowestPriorityResources: [],
  missingResources: [],
  multiSystemResources: [],
  safeTradeCandidates: [],
  neverTradeResources: [],
  farmTargets: [],
  tradeTargets: [],
  inventory: _quietInventory,
);
