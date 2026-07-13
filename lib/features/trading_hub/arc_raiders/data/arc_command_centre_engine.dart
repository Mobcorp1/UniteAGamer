import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_view_mapper.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_decision_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_nomadic_trader_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_operations_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_resource_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_bench_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_decision_engine_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_nomadic_trader_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_quest_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_resource_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_blueprint_watches_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_create_listing_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_listing_queues_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_my_listings_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart';

class ArcCommandCentreEngine {
  const ArcCommandCentreEngine._();

  static ArcCommandCentreState build({
    required Map<String, ArcBlueprintState> blueprintStates,
    required List<ArcSavedLoadout> savedLoadouts,
    Map<String, ArcScrappyState> scrappyStates =
        const <String, ArcScrappyState>{},
    ArcNomadicTraderTrackerSnapshot nomadicTraderTracker =
        ArcNomadicTraderTrackerSnapshot.empty,
    ArcOperationsUserState operationsState = ArcOperationsUserState.empty,
    ArcCommandTradeActivity tradeActivity = ArcCommandTradeActivity.empty,
  }) {
    final totalBlueprints = ArcBlueprintSeedData.blueprints.length;
    final blueprintStateKnown = blueprintStates.isNotEmpty;
    final ownedBlueprints = blueprintStates.values
        .where((state) => state.owned)
        .length
        .clamp(0, totalBlueprints)
        .toInt();
    final missingBlueprints = blueprintStateKnown
        ? math.max(0, totalBlueprints - ownedBlueprints)
        : null;
    final duplicateBlueprints = blueprintStates.values.fold<int>(
      0,
      (total, state) => total + state.dupesOwned,
    );
    final recentBlueprint = _recentBlueprintName(blueprintStates);
    final prioritizedMissing = _prioritizedMissingBlueprints(blueprintStates);
    final loadout = savedLoadouts.isEmpty ? null : savedLoadouts.first;
    final loadoutSummary = _loadoutSummary(loadout);
    final readyOperations = _operationCount(
      operationsState,
      ArcOperationClaimState.readyToClaim,
    );
    final inProgressOperations = _operationCount(
      operationsState,
      ArcOperationClaimState.inProgress,
    );
    final availableOperations = _operationTasks.length;
    final questIntel = const ArcQuestIntelligenceEngine().build(
      scrappyStates: scrappyStates,
    );
    final benchIntel = const ArcBenchIntelligenceEngine().build(
      scrappyStates: scrappyStates,
    );
    final traderIntel = const ArcNomadicTraderIntelligenceEngine().build(
      tracker: nomadicTraderTracker,
      questIntel: questIntel,
      benchIntel: benchIntel,
      favouriteLoadout: loadout,
      blueprintStates: blueprintStates,
      tradeActivity: tradeActivity,
      duplicateBlueprints: duplicateBlueprints,
    );
    final resourceIntel = const ArcResourceIntelligenceEngine().build(
      scrappyStates: scrappyStates,
      questIntel: questIntel,
      benchIntel: benchIntel,
      traderIntel: traderIntel,
      favouriteLoadout: loadout,
      blueprintStates: blueprintStates,
      tradeActivity: tradeActivity,
    );
    final decisionState = const ArcDecisionEngine().build(
      blueprintStateKnown: blueprintStateKnown,
      ownedBlueprints: ownedBlueprints,
      totalBlueprints: totalBlueprints,
      missingBlueprints: missingBlueprints,
      duplicateBlueprints: duplicateBlueprints,
      prioritizedMissingBlueprints: prioritizedMissing,
      favouriteLoadout: loadout,
      operationsState: operationsState,
      tradeActivity: tradeActivity,
      readyOperations: readyOperations,
      inProgressOperations: inProgressOperations,
      availableOperations: availableOperations,
      questIntel: questIntel,
      benchIntel: benchIntel,
      traderIntel: traderIntel,
      resourceIntel: resourceIntel,
    );

    return ArcCommandCentreState(
      priority: ArcCommandCentreViewMapper.priority(
        decisionState.primaryMission,
      ),
      snapshots: ArcCommandCentreViewMapper.snapshots(decisionState),
      objectives: ArcCommandCentreViewMapper.objectives(decisionState),
      alerts: ArcCommandCentreViewMapper.alerts(decisionState),
      recommendations: ArcCommandCentreViewMapper.recommendations(
        decisionState,
      ),
      checklist: _checklist(
        loadoutReady: loadoutSummary.ready,
        tradeActivity: tradeActivity,
        readyOperations: readyOperations,
        questIntel: questIntel,
        benchIntel: benchIntel,
        traderIntel: traderIntel,
        resourceIntel: resourceIntel,
      ),
      resources: ArcCommandCentreViewMapper.resources(decisionState),
      tradeSummary: _tradeSummary(
        prioritizedMissing: prioritizedMissing,
        duplicateBlueprints: duplicateBlueprints,
        tradeActivity: tradeActivity,
        questIntel: questIntel,
        benchIntel: benchIntel,
        traderIntel: traderIntel,
        resourceIntel: resourceIntel,
        decisionState: decisionState,
      ),
      blueprintSummary: _blueprintSummary(
        blueprintStateKnown: blueprintStateKnown,
        ownedBlueprints: ownedBlueprints,
        totalBlueprints: totalBlueprints,
        missingBlueprints: missingBlueprints,
        duplicateBlueprints: duplicateBlueprints,
        recentBlueprint: recentBlueprint,
      ),
      questSummary: _questSummary(questIntel),
      benchSummary: _benchSummary(benchIntel),
      operationsSummary: _operationsSummary(
        operationsState: operationsState,
        readyOperations: readyOperations,
        inProgressOperations: inProgressOperations,
        availableOperations: availableOperations,
      ),
      weeklyTraderSummary: _weeklyTraderSummary(traderIntel),
      resourceSummary: _resourceSummary(resourceIntel),
      decisionSummary: _decisionSummary(decisionState),
      communitySummary: _communitySummary(tradeActivity),
      statisticsSummary: _statisticsSummary(
        blueprintStateKnown: blueprintStateKnown,
        ownedBlueprints: ownedBlueprints,
        duplicateBlueprints: duplicateBlueprints,
        tradeActivity: tradeActivity,
        operationsState: operationsState,
        questIntel: questIntel,
        benchIntel: benchIntel,
        traderIntel: traderIntel,
        resourceIntel: resourceIntel,
        decisionState: decisionState,
      ),
    );
  }

  static List<ArcCommandChecklistItem> _checklist({
    required bool loadoutReady,
    required ArcCommandTradeActivity tradeActivity,
    required int readyOperations,
    required ArcQuestIntelligence questIntel,
    required ArcBenchIntelligence benchIntel,
    required ArcNomadicTraderIntelligence traderIntel,
    required ArcResourceIntelligence resourceIntel,
  }) {
    return [
      ArcCommandChecklistItem(
        id: 'claim-operations',
        label: 'Claim Operations',
        reason: readyOperations > 0
            ? '$readyOperations reward ready in Operations.'
            : 'No claimable Operation rewards right now.',
        doneByDefault: readyOperations == 0,
        action: const ArcCommandAction(
          label: 'Operations',
          intent: ArcCommandActionIntent.operations,
        ),
      ),
      const ArcCommandChecklistItem(
        id: 'weekly-raid',
        label: 'Weekly Raid',
        reason: 'Confirm this week has one focused raid goal.',
        action: ArcCommandAction(
          label: 'Raid Planner',
          routeName: RaidPlannerScreen.routeName,
        ),
      ),
      ArcCommandChecklistItem(
        id: 'nomadic-trader',
        label: 'Check Nomadic Trader',
        reason: traderIntel.trackingKnown
            ? traderIntel.recommendation
            : 'Review trader goals before spending resources.',
        doneByDefault: traderIntel.trackingKnown && !traderIntel.shouldVisit,
        action: const ArcCommandAction(
          label: 'Open Trader',
          intent: ArcCommandActionIntent.nomadicTrader,
        ),
      ),
      ArcCommandChecklistItem(
        id: 'review-trades',
        label: 'Review Trades',
        reason: tradeActivity.releasableListingQueues > 0
            ? '${tradeActivity.releasableListingQueues} listing queue can release.'
            : tradeActivity.blockedListingQueues > 0
            ? '${tradeActivity.blockedListingQueues} listing queue needs attention.'
            : tradeActivity.matchedBlueprintWatches > 0
            ? '${tradeActivity.matchedBlueprintWatches} blueprint watch match found.'
            : tradeActivity.hasActionableTrades
            ? 'Check listings, offers and duplicate value.'
            : 'No actionable trade signal is waiting.',
        doneByDefault: !tradeActivity.hasActionableTrades,
        action: const ArcCommandAction(
          label: 'View Trades',
          routeName: TraderHubScreen.routeName,
        ),
      ),
      ArcCommandChecklistItem(
        id: 'protect-resources',
        label: resourceIntel.hasProtectedResources
            ? 'Protect Resources'
            : 'Review Resources',
        reason: resourceIntel.trackingKnown
            ? resourceIntel.recommendation
            : 'Track resources so safe trade and protected items are visible.',
        doneByDefault:
            resourceIntel.trackingKnown && !resourceIntel.hasCriticalBlocker,
        action: const ArcCommandAction(
          label: 'Resources',
          routeName: ScrappyGridScreen.routeName,
        ),
      ),
      ArcCommandChecklistItem(
        id: 'hand-in-quest',
        label: questIntel.readyToComplete ? 'Hand In Quest' : 'Track Quest',
        reason: questIntel.trackingKnown
            ? questIntel.recommendation
            : 'Set up Mission Operations to track quest item progress.',
        doneByDefault: questIntel.trackingKnown && !questIntel.readyToComplete,
        action: const ArcCommandAction(
          label: 'Quest Tracker',
          routeName: ScrappyGridScreen.questRouteName,
        ),
      ),
      ArcCommandChecklistItem(
        id: 'upgrade-bench',
        label: benchIntel.readyToUpgrade ? 'Upgrade Bench' : 'Track Bench',
        reason: benchIntel.trackingKnown
            ? benchIntel.recommendation
            : 'Set up Bench Operations to track upgrade resources.',
        doneByDefault: benchIntel.trackingKnown && !benchIntel.readyToUpgrade,
        action: const ArcCommandAction(
          label: 'Bench Tracker',
          routeName: ScrappyGridScreen.benchRouteName,
        ),
      ),
      const ArcCommandChecklistItem(
        id: 'clear-inventory',
        label: 'Clear Inventory',
        reason:
            'Stash fullness is not wired yet; use resource tracker meanwhile.',
        action: ArcCommandAction(
          label: 'Resources',
          routeName: ScrappyGridScreen.routeName,
        ),
      ),
      ArcCommandChecklistItem(
        id: 'review-loadout',
        label: 'Review Favourite Loadout',
        reason:
            'Make sure weapons, equipment and augments match the next raid.',
        doneByDefault: loadoutReady,
        action: const ArcCommandAction(
          label: 'Open Loadout',
          intent: ArcCommandActionIntent.favouriteLoadout,
        ),
      ),
      ArcCommandChecklistItem(
        id: 'clear-trade-inbox',
        label: 'Clear Trade Inbox',
        reason: tradeActivity.unreadNotifications > 0
            ? '${tradeActivity.unreadNotifications} unread trade notification pending.'
            : 'Trade inbox has no unread notifications.',
        doneByDefault: tradeActivity.unreadNotifications == 0,
        action: const ArcCommandAction(
          label: 'Inbox',
          routeName: TradingNotificationsScreen.routeName,
        ),
      ),
    ];
  }

  static ArcCommandTradeSummary _tradeSummary({
    required List<String> prioritizedMissing,
    required int duplicateBlueprints,
    required ArcCommandTradeActivity tradeActivity,
    required ArcQuestIntelligence questIntel,
    required ArcBenchIntelligence benchIntel,
    required ArcNomadicTraderIntelligence traderIntel,
    required ArcResourceIntelligence resourceIntel,
    required ArcDecisionState decisionState,
  }) {
    final tradeAssistedNeeds = decisionState.tradeAssistedOpportunities
        .where((signal) => signal.category != ArcDecisionCategory.inventory)
        .take(2)
        .map((signal) => signal.progressLabel)
        .where((label) => label.trim().isNotEmpty);
    final lookingFor = <String>[
      if (tradeActivity.pendingOffers > 0)
        '${tradeActivity.pendingOffers} pending ${_plural(tradeActivity.pendingOffers, 'offer', 'offers')}',
      if (tradeActivity.activeSessions > 0)
        '${tradeActivity.activeSessions} active trade ${_plural(tradeActivity.activeSessions, 'session', 'sessions')}',
      if (tradeActivity.bestIntelligenceConfidence > 0)
        '${tradeActivity.bestIntelligenceConfidence}% ${tradeActivity.bestIntelligenceLabel}',
      if (tradeActivity.matchedBlueprintWatches > 0)
        '${tradeActivity.matchedBlueprintWatches} blueprint watch ${_plural(tradeActivity.matchedBlueprintWatches, 'match', 'matches')}',
      ...tradeAssistedNeeds,
      if (benchIntel.hasBlocker && benchIntel.trackingKnown)
        ...benchIntel.missingResources
            .take(2)
            .map((resource) => resource.missingLabel),
      if (questIntel.hasBlocker && questIntel.trackingKnown)
        ...questIntel.missingItems.take(2).map((item) => item.missingLabel),
      if (traderIntel.hasTradeableNeed) ...traderIntel.tradeNeedLabels.take(2),
      ...resourceIntel.tradeTargets
          .take(2)
          .map((resource) => resource.missingLabel),
      if (prioritizedMissing.isNotEmpty) ...prioritizedMissing.take(3),
      if (prioritizedMissing.isEmpty &&
          tradeActivity.pendingOffers == 0 &&
          !_tradeCanHelpProgress(questIntel, benchIntel, traderIntel))
        'Blueprint needs not tracked',
      if (tradeActivity.communityListings > 0)
        '${tradeActivity.communityListings} community listings live',
    ];
    final offering = <String>[
      if (tradeActivity.activeMyListings > 0)
        '${tradeActivity.activeMyListings} active ${_plural(tradeActivity.activeMyListings, 'listing', 'listings')}',
      if (tradeActivity.releasableListingQueues > 0)
        '${tradeActivity.releasableListingQueues} queue ${_plural(tradeActivity.releasableListingQueues, 'release', 'releases')} ready',
      if (tradeActivity.blockedListingQueues > 0)
        '${tradeActivity.blockedListingQueues} blocked ${_plural(tradeActivity.blockedListingQueues, 'queue', 'queues')}',
      if (tradeActivity.activeBlueprintWatches > 0)
        '${tradeActivity.activeBlueprintWatches} active blueprint ${_plural(tradeActivity.activeBlueprintWatches, 'watch', 'watches')}',
      duplicateBlueprints > 0
          ? '$duplicateBlueprints duplicate blueprints'
          : 'No duplicate blueprints tracked',
      if (traderIntel.canAffordBestPurchase)
        'Trader purchase ready'
      else if (traderIntel.hasImportantGap)
        'Trader resources needed',
      ...resourceIntel.safeTradeCandidates
          .take(2)
          .map((resource) => '${resource.duplicateCount} ${resource.name}'),
      if (tradeActivity.unreadNotifications > 0)
        '${tradeActivity.unreadNotifications} unread ${_plural(tradeActivity.unreadNotifications, 'notification', 'notifications')}',
      if (tradeActivity.myListings > 0 && tradeActivity.activeMyListings == 0)
        '${tradeActivity.myListings} listing history',
    ];
    return ArcCommandTradeSummary(
      lookingFor: lookingFor.take(4).toList(growable: false),
      offering: offering.take(4).toList(growable: false),
      actions: const [
        ArcCommandAction(
          label: 'View Trades',
          routeName: TraderHubScreen.routeName,
        ),
        ArcCommandAction(
          label: 'Create Trade',
          routeName: TradingCreateListingScreen.routeName,
        ),
        ArcCommandAction(
          label: 'My Listings',
          routeName: TradingMyListingsScreen.routeName,
        ),
        ArcCommandAction(
          label: 'Watches',
          routeName: TradingBlueprintWatchesScreen.routeName,
        ),
        ArcCommandAction(
          label: 'Queues',
          routeName: TradingListingQueuesScreen.routeName,
        ),
        ArcCommandAction(
          label: 'Auto Match',
          intent: ArcCommandActionIntent.smartTrade,
        ),
      ],
    );
  }

  static ArcCommandSummaryPanel _blueprintSummary({
    required bool blueprintStateKnown,
    required int ownedBlueprints,
    required int totalBlueprints,
    required int? missingBlueprints,
    required int duplicateBlueprints,
    required String? recentBlueprint,
  }) {
    return ArcCommandSummaryPanel(
      title: 'Blueprint Summary',
      statusLabel: blueprintStateKnown ? 'Tracking' : 'Set up',
      body: blueprintStateKnown
          ? 'Collection state is available for command priorities.'
          : 'Mark owned blueprints to activate collection guidance.',
      details: blueprintStateKnown
          ? [
              '$ownedBlueprints/$totalBlueprints owned',
              '${missingBlueprints ?? 0} missing',
              '$duplicateBlueprints duplicate',
              recentBlueprint == null
                  ? 'No recent acquisition timestamp'
                  : 'Recent: $recentBlueprint',
            ]
          : const [
              'Owned count not tracked yet',
              'Missing count not tracked yet',
              'Duplicate count not tracked yet',
            ],
      status: blueprintStateKnown
          ? ArcCommandStatus.active
          : ArcCommandStatus.neutral,
      action: const ArcCommandAction(
        label: 'Open Blueprint Tracker',
        routeName: BlueprintGridScreen.routeName,
      ),
    );
  }

  static ArcCommandSummaryPanel _questSummary(ArcQuestIntelligence questIntel) {
    return ArcCommandSummaryPanel(
      title: 'Quest Progress',
      statusLabel: questIntel.statusLabel,
      body: questIntel.summary,
      details: [
        'Active quest: ${questIntel.questLabel}',
        questIntel.trackingKnown
            ? 'Progress: ${questIntel.progressLabel}'
            : 'Progress: Set up Mission Operations',
        questIntel.trackingKnown
            ? 'Required: ${questIntel.collectedCount}/${questIntel.requiredCount} items collected'
            : 'Required: ${questIntel.requiredCount} catalogued items',
        questIntel.readyToComplete
            ? 'Ready to complete'
            : 'Missing: ${questIntel.missingShortText}',
      ],
      status: questIntel.status,
      action: const ArcCommandAction(
        label: 'Quest Tracker',
        routeName: ScrappyGridScreen.questRouteName,
      ),
    );
  }

  static ArcCommandSummaryPanel _benchSummary(ArcBenchIntelligence benchIntel) {
    return ArcCommandSummaryPanel(
      title: 'Bench Progress',
      statusLabel: benchIntel.statusLabel,
      body: benchIntel.summary,
      details: [
        'Current level: ${benchIntel.currentLevelLabel}',
        'Next upgrade: ${benchIntel.upgradeLabel}',
        benchIntel.trackingKnown
            ? 'Progress: ${benchIntel.progressLabel}'
            : 'Progress: Set up Bench Operations',
        benchIntel.trackingKnown
            ? 'Required: ${benchIntel.collectedCount}/${benchIntel.requiredCount} resources collected'
            : 'Required: ${benchIntel.requiredCount} catalogued resources',
        benchIntel.readyToUpgrade
            ? 'Ready to upgrade'
            : 'Missing: ${benchIntel.missingShortText}',
      ],
      status: benchIntel.status,
      action: const ArcCommandAction(
        label: 'Bench Tracker',
        routeName: ScrappyGridScreen.benchRouteName,
      ),
    );
  }

  static ArcCommandSummaryPanel _operationsSummary({
    required ArcOperationsUserState operationsState,
    required int readyOperations,
    required int inProgressOperations,
    required int availableOperations,
  }) {
    final equippedCount = _equippedCosmeticCount(operationsState);
    final status = readyOperations > 0
        ? ArcCommandStatus.ready
        : operationsState.inventory.isNotEmpty || inProgressOperations > 0
        ? ArcCommandStatus.active
        : ArcCommandStatus.neutral;
    return ArcCommandSummaryPanel(
      title: 'Operations / Reward Vault',
      statusLabel: readyOperations > 0
          ? 'Rewards ready'
          : operationsState.inventory.isNotEmpty
          ? 'Tracking'
          : 'Set up',
      body: readyOperations > 0
          ? 'Claimable rewards are available from Operations.'
          : 'Operations progress and Reward Vault inventory are live.',
      details: [
        'Intel level ${operationsState.operationLevel} - ${operationsState.intelXp} XP',
        '${operationsState.completedCount}/$availableOperations operations completed',
        '$readyOperations ready to claim - $inProgressOperations in progress',
        '${operationsState.inventory.length} Vault reward ${_plural(operationsState.inventory.length, 'item', 'items')} owned',
        '$equippedCount/4 cosmetic slots equipped',
        operationsState.extraTradeSlots > 0 ||
                operationsState.extraMatchmakingSlots > 0
            ? 'Bonus slots: ${operationsState.extraTradeSlots} trade / ${operationsState.extraMatchmakingSlots} match'
            : 'Bonus slots: none unlocked yet',
      ],
      status: status,
      action: const ArcCommandAction(
        label: 'Open Operations',
        intent: ArcCommandActionIntent.operations,
      ),
    );
  }

  static ArcCommandSummaryPanel _weeklyTraderSummary(
    ArcNomadicTraderIntelligence traderIntel,
  ) {
    if (!traderIntel.trackingKnown) {
      return const ArcCommandSummaryPanel(
        title: 'Weekly Nomadic Trader',
        statusLabel: 'Set up',
        body:
            'No saved trader goal or purchase requirements are available yet.',
        details: [
          'Current stock: Open Nomadic Trader to track',
          'Required resources: Not tracked yet',
          'Reset timing: Not available',
        ],
        status: ArcCommandStatus.neutral,
        action: ArcCommandAction(
          label: 'Open Nomadic Trader',
          intent: ArcCommandActionIntent.nomadicTrader,
        ),
      );
    }

    final best = traderIntel.bestPurchase;
    return ArcCommandSummaryPanel(
      title: 'Weekly Nomadic Trader',
      statusLabel: traderIntel.statusLabel,
      body: traderIntel.summary,
      details: [
        'Goal: ${traderIntel.goalName}',
        'Value: ${traderIntel.currentValue}/${traderIntel.targetValue}',
        '${traderIntel.completedPurchaseCount}/${traderIntel.trackedPurchaseCount} tracked purchases complete',
        if (best != null) 'Recommended: ${best.purchase.name}',
        if (best != null) 'Why: ${best.priorityLabel}',
        if (best != null && best.missingResources.isNotEmpty)
          'Missing: ${best.missingShortText}'
        else if (traderIntel.remainingValue > 0)
          'Missing value: ${traderIntel.remainingValue}',
        traderIntel.resetLabel == null
            ? 'Reset timing: Not available'
            : 'Reset: ${traderIntel.resetLabel}',
      ],
      status: traderIntel.status,
      action: const ArcCommandAction(
        label: 'Open Nomadic Trader',
        intent: ArcCommandActionIntent.nomadicTrader,
      ),
    );
  }

  static ArcCommandSummaryPanel _resourceSummary(
    ArcResourceIntelligence resourceIntel,
  ) {
    if (!resourceIntel.trackingKnown) {
      return const ArcCommandSummaryPanel(
        title: 'Resource Intelligence',
        statusLabel: 'Set up',
        body: 'Resource ownership is not tracked yet.',
        details: [
          'Owned resources: Not tracked yet',
          'Missing resources: Safe empty state',
          'Safe trade resources: Not available',
        ],
        status: ArcCommandStatus.neutral,
        action: ArcCommandAction(
          label: 'Track Resources',
          routeName: ScrappyGridScreen.routeName,
        ),
      );
    }

    final top = resourceIntel.topResource;
    return ArcCommandSummaryPanel(
      title: 'Resource Intelligence',
      statusLabel: resourceIntel.statusLabel,
      body: resourceIntel.summary,
      details: [
        '${resourceIntel.totalTrackedResources} tracked resources with ownership',
        '${resourceIntel.totalMissingResources} total missing requirements',
        '${resourceIntel.totalDuplicateResources} tracked surplus resources',
        if (top != null)
          '${top.name}: scarcity ${top.scarcityScore}, usefulness ${top.usefulnessScore}, progression ${top.progressionValue}',
        if (resourceIntel.neverTradeResources.isNotEmpty)
          'Never trade: ${resourceIntel.neverTradeResources.take(3).map((resource) => resource.name).join(', ')}',
        if (resourceIntel.safeTradeCandidates.isNotEmpty)
          'Safe trade: ${resourceIntel.safeTradeCandidates.take(3).map((resource) => resource.name).join(', ')}',
        if (resourceIntel.farmTargets.isNotEmpty)
          'Farm: ${resourceIntel.farmTargets.first.name} - ${resourceIntel.farmTargets.first.farmHint}',
        'Inventory pressure: ${resourceIntel.inventory.pressureLabel}',
      ],
      status: resourceIntel.status,
      action: const ArcCommandAction(
        label: 'Resource Tracker',
        routeName: ScrappyGridScreen.routeName,
      ),
    );
  }

  static ArcCommandSummaryPanel _decisionSummary(
    ArcDecisionState decisionState,
  ) {
    final mission = decisionState.primaryMission;
    final topObjectives = decisionState.rankedObjectives
        .where((objective) => objective.id != mission.id)
        .take(3)
        .map((objective) => '${objective.title} - ${objective.progressLabel}');
    final tradeCount = decisionState.tradeAssistedOpportunities.length;
    final resourceCount = decisionState.resourceActions.length;
    return ArcCommandSummaryPanel(
      title: 'Decision Engine',
      statusLabel: decisionState.confidenceLabel,
      body: decisionState.summary,
      details: [
        'Primary: ${mission.title}',
        'Source: ${mission.sourceSystem}',
        'Score: ${mission.priority} - ${mission.score.confidenceLabel}',
        if (topObjectives.isNotEmpty)
          'Next: ${topObjectives.join(', ')}'
        else
          'Next: No secondary objective outranks the mission',
        '$tradeCount trade-assisted opportunity ${_plural(tradeCount, 'is', 'are')} ranked',
        '$resourceCount resource action ${_plural(resourceCount, 'is', 'are')} ranked',
      ],
      status: mission.status,
      action: mission.action.toCommandAction(),
    );
  }

  static ArcCommandSummaryPanel _communitySummary(
    ArcCommandTradeActivity tradeActivity,
  ) {
    final hasTradeData =
        tradeActivity.communityListings > 0 ||
        tradeActivity.myListings > 0 ||
        tradeActivity.acceptedOffers > 0 ||
        tradeActivity.activeSessions > 0;
    return ArcCommandSummaryPanel(
      title: 'Community Activity',
      statusLabel: hasTradeData ? 'Live trade data' : 'Safe empty state',
      body: hasTradeData
          ? 'Trading repository counts are connected to Command Centre.'
          : 'No live community trade activity is available for this account yet.',
      details: [
        '${tradeActivity.communityListings} active community listings',
        '${tradeActivity.myListings} total personal listings',
        '${tradeActivity.acceptedOffers} accepted offers',
        '${tradeActivity.activeSessions} active trading sessions',
        '${tradeActivity.activeBlueprintWatches} active blueprint watches',
        '${tradeActivity.activeListingQueues} active listing queues',
      ],
      status: hasTradeData ? ArcCommandStatus.active : ArcCommandStatus.neutral,
      action: const ArcCommandAction(
        label: 'Open Intel',
        routeName: ArcMarketIntelligenceScreen.routeName,
      ),
    );
  }

  static ArcCommandSummaryPanel _statisticsSummary({
    required bool blueprintStateKnown,
    required int ownedBlueprints,
    required int duplicateBlueprints,
    required ArcCommandTradeActivity tradeActivity,
    required ArcOperationsUserState operationsState,
    required ArcQuestIntelligence questIntel,
    required ArcBenchIntelligence benchIntel,
    required ArcNomadicTraderIntelligence traderIntel,
    required ArcResourceIntelligence resourceIntel,
    required ArcDecisionState decisionState,
  }) {
    return ArcCommandSummaryPanel(
      title: 'Statistics',
      statusLabel: 'Live summary',
      body: 'Command Centre is aggregating safe live signals from core tools.',
      details: [
        'Decision: ${decisionState.primaryMission.title}',
        'Decision confidence: ${decisionState.confidenceLabel}',
        'Accepted offers: ${tradeActivity.acceptedOffers}',
        'Active trade sessions: ${tradeActivity.activeSessions}',
        blueprintStateKnown
            ? 'Blueprints collected: $ownedBlueprints'
            : 'Blueprints collected: Not tracked yet',
        'Operations completed: ${operationsState.completedCount}',
        questIntel.trackingKnown
            ? 'Quest focus: ${questIntel.questName} ${questIntel.completionPercent}%'
            : 'Quest focus: Set up tracker',
        benchIntel.trackingKnown
            ? 'Bench focus: ${benchIntel.upgradeLabel} ${benchIntel.completionPercent}%'
            : 'Bench focus: Set up tracker',
        traderIntel.trackingKnown
            ? 'Trader focus: ${traderIntel.goalName} ${traderIntel.completionPercent}%'
            : 'Trader focus: Set up tracker',
        resourceIntel.trackingKnown
            ? 'Resource pressure: ${resourceIntel.inventory.pressureLabel}'
            : 'Resource pressure: Set up tracker',
        'Reward Vault items: ${operationsState.inventory.length}',
        'Inventory space saved: $duplicateBlueprints duplicate signals',
      ],
      status: ArcCommandStatus.neutral,
      action: const ArcCommandAction(
        label: 'Open Tool Deck',
        intent: ArcCommandActionIntent.toolDeck,
      ),
    );
  }

  static _ArcLoadoutCommandSummary _loadoutSummary(ArcSavedLoadout? loadout) {
    if (loadout == null) {
      return const _ArcLoadoutCommandSummary(
        ready: false,
        statusLabel: 'Needs setup',
        detail: 'No saved loadout',
        missingSlots: ['saved loadout'],
      );
    }

    final missingSlots = <String>[
      if (loadout.augment.trim().isEmpty) 'augment',
      if (loadout.primaryWeapon.trim().isEmpty) 'primary weapon',
      if (loadout.secondaryWeapon.trim().isEmpty) 'secondary weapon',
      if (loadout.equipment.isEmpty && loadout.consumables.isEmpty)
        'equipment or consumables',
    ];
    final ready = missingSlots.isEmpty;
    final kitParts = <String>[
      if (loadout.primaryWeapon.trim().isNotEmpty) loadout.primaryWeapon.trim(),
      if (loadout.secondaryWeapon.trim().isNotEmpty)
        loadout.secondaryWeapon.trim(),
      if (loadout.augment.trim().isNotEmpty) loadout.augment.trim(),
    ];

    return _ArcLoadoutCommandSummary(
      ready: ready,
      statusLabel: ready ? 'Ready' : 'Needs ${missingSlots.length}',
      detail: kitParts.isEmpty ? loadout.name : kitParts.join(' / '),
      missingSlots: missingSlots,
    );
  }

  static List<ArcOperationTask> get _operationTasks => [
    ...ArcOperationsSeedData.betaOperations,
    ...ArcOperationsSeedData.dailyOperations,
    ...ArcOperationsSeedData.weeklyOperations,
    ...ArcOperationsSeedData.monthlyOperations,
    ...ArcOperationsSeedData.lifetimeOperations,
  ];

  static int _operationCount(
    ArcOperationsUserState operationsState,
    ArcOperationClaimState state,
  ) {
    return _operationTasks
        .where((task) => operationsState.stateFor(task) == state)
        .length;
  }

  static int _equippedCosmeticCount(ArcOperationsUserState operationsState) {
    final equipped = operationsState.equippedCosmetics;
    return [
      equipped.badgeId,
      equipped.titleId,
      equipped.profileFrameId,
      equipped.profileBannerId,
    ].where((id) => id != null && id.trim().isNotEmpty).length;
  }

  static bool _tradeCanHelpProgress(
    ArcQuestIntelligence questIntel,
    ArcBenchIntelligence benchIntel,
    ArcNomadicTraderIntelligence traderIntel,
  ) {
    return (questIntel.trackingKnown && questIntel.hasBlocker) ||
        (benchIntel.trackingKnown && benchIntel.hasBlocker) ||
        traderIntel.hasTradeableNeed;
  }

  static String _plural(int count, String singular, String plural) {
    return count == 1 ? singular : plural;
  }

  static String? _recentBlueprintName(
    Map<String, ArcBlueprintState> blueprintStates,
  ) {
    ArcBlueprintState? recent;
    for (final state in blueprintStates.values) {
      if (!state.owned || state.updatedAt == null) continue;
      if (recent == null || state.updatedAt!.isAfter(recent.updatedAt!)) {
        recent = state;
      }
    }
    if (recent == null) return null;
    return _blueprintById(recent.blueprintId)?.name ?? recent.blueprintId;
  }

  static List<String> _prioritizedMissingBlueprints(
    Map<String, ArcBlueprintState> blueprintStates,
  ) {
    final prioritized =
        blueprintStates.values
            .where((state) => state.isPrioritized && !state.owned)
            .toList(growable: false)
          ..sort((a, b) => a.priorityRank.compareTo(b.priorityRank));

    return prioritized
        .map(
          (state) =>
              _blueprintById(state.blueprintId)?.name ?? state.blueprintId,
        )
        .take(3)
        .toList(growable: false);
  }

  static ArcBlueprint? _blueprintById(String id) {
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (blueprint.id == id) return blueprint;
    }
    return null;
  }
}

class _ArcLoadoutCommandSummary {
  const _ArcLoadoutCommandSummary({
    required this.ready,
    required this.statusLabel,
    required this.detail,
    required this.missingSlots,
  });

  final bool ready;
  final String statusLabel;
  final String detail;
  final List<String> missingSlots;

  String get missingShortText =>
      missingSlots.isEmpty ? 'none' : missingSlots.join(', ');

  String get missingText {
    if (ready) return 'Favourite Loadout has a complete saved kit.';
    return 'Missing $missingShortText; complete the loadout before raid planning.';
  }
}
