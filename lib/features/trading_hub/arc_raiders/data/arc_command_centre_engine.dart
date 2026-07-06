import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_nomadic_trader_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_operations_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_resource_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_bench_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_nomadic_trader_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_quest_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_resource_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_create_listing_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_my_listings_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_my_offers_screen.dart';
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

    return ArcCommandCentreState(
      priority: _priority(
        blueprintStateKnown: blueprintStateKnown,
        ownedBlueprints: ownedBlueprints,
        totalBlueprints: totalBlueprints,
        missingBlueprints: missingBlueprints,
        duplicateBlueprints: duplicateBlueprints,
        prioritizedMissing: prioritizedMissing,
        loadoutSummary: loadoutSummary,
        operationsState: operationsState,
        tradeActivity: tradeActivity,
        readyOperations: readyOperations,
        inProgressOperations: inProgressOperations,
        questIntel: questIntel,
        benchIntel: benchIntel,
        traderIntel: traderIntel,
        resourceIntel: resourceIntel,
      ),
      snapshots: _snapshots(
        blueprintStateKnown: blueprintStateKnown,
        ownedBlueprints: ownedBlueprints,
        totalBlueprints: totalBlueprints,
        missingBlueprints: missingBlueprints,
        duplicateBlueprints: duplicateBlueprints,
        loadout: loadout,
        loadoutSummary: loadoutSummary,
        operationsState: operationsState,
        tradeActivity: tradeActivity,
        readyOperations: readyOperations,
        inProgressOperations: inProgressOperations,
        questIntel: questIntel,
        benchIntel: benchIntel,
        traderIntel: traderIntel,
        resourceIntel: resourceIntel,
      ),
      objectives: _objectives(
        blueprintStateKnown: blueprintStateKnown,
        ownedBlueprints: ownedBlueprints,
        totalBlueprints: totalBlueprints,
        missingBlueprints: missingBlueprints,
        duplicateBlueprints: duplicateBlueprints,
        loadoutSummary: loadoutSummary,
        operationsState: operationsState,
        tradeActivity: tradeActivity,
        readyOperations: readyOperations,
        inProgressOperations: inProgressOperations,
        availableOperations: availableOperations,
        questIntel: questIntel,
        benchIntel: benchIntel,
        traderIntel: traderIntel,
        resourceIntel: resourceIntel,
      ),
      alerts: _alerts(
        blueprintStateKnown: blueprintStateKnown,
        duplicateBlueprints: duplicateBlueprints,
        missingBlueprints: missingBlueprints,
        loadoutSummary: loadoutSummary,
        tradeActivity: tradeActivity,
        readyOperations: readyOperations,
        questIntel: questIntel,
        benchIntel: benchIntel,
        traderIntel: traderIntel,
        resourceIntel: resourceIntel,
      ),
      recommendations: _recommendations(
        blueprintStateKnown: blueprintStateKnown,
        missingBlueprints: missingBlueprints,
        duplicateBlueprints: duplicateBlueprints,
        loadoutSummary: loadoutSummary,
        tradeActivity: tradeActivity,
        readyOperations: readyOperations,
        questIntel: questIntel,
        benchIntel: benchIntel,
        traderIntel: traderIntel,
        resourceIntel: resourceIntel,
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
      resources: _resources(resourceIntel),
      tradeSummary: _tradeSummary(
        prioritizedMissing: prioritizedMissing,
        duplicateBlueprints: duplicateBlueprints,
        tradeActivity: tradeActivity,
        questIntel: questIntel,
        benchIntel: benchIntel,
        traderIntel: traderIntel,
        resourceIntel: resourceIntel,
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
      ),
    );
  }

  static ArcCommandPriority _priority({
    required bool blueprintStateKnown,
    required int ownedBlueprints,
    required int totalBlueprints,
    required int? missingBlueprints,
    required int duplicateBlueprints,
    required List<String> prioritizedMissing,
    required _ArcLoadoutCommandSummary loadoutSummary,
    required ArcOperationsUserState operationsState,
    required ArcCommandTradeActivity tradeActivity,
    required int readyOperations,
    required int inProgressOperations,
    required ArcQuestIntelligence questIntel,
    required ArcBenchIntelligence benchIntel,
    required ArcNomadicTraderIntelligence traderIntel,
    required ArcResourceIntelligence resourceIntel,
  }) {
    if (readyOperations > 0) {
      return ArcCommandPriority(
        title: 'Claim Operation Rewards',
        explanation:
            '$readyOperations operation reward ${_plural(readyOperations, 'is', 'are')} ready in Operations.',
        progressLabel: '$readyOperations ready to claim',
        statusTag: 'Reward ready',
        detail:
            'Claim rewards before planning the next objective so Vault and profile cosmetics stay current.',
        status: ArcCommandStatus.ready,
        primaryAction: const ArcCommandAction(
          label: 'Open Operations',
          intent: ArcCommandActionIntent.operations,
        ),
      );
    }

    if (benchIntel.readyToUpgrade) {
      return ArcCommandPriority(
        title: 'Upgrade ${benchIntel.station}',
        explanation: benchIntel.summary,
        progressLabel: benchIntel.progressLabel,
        statusTag: benchIntel.statusLabel,
        detail: benchIntel.recommendation,
        status: ArcCommandStatus.ready,
        primaryAction: const ArcCommandAction(
          label: 'Bench Tracker',
          routeName: ScrappyGridScreen.benchRouteName,
        ),
      );
    }

    if (questIntel.readyToComplete) {
      return ArcCommandPriority(
        title: 'Complete ${questIntel.questName}',
        explanation: questIntel.summary,
        progressLabel: questIntel.progressLabel,
        statusTag: questIntel.statusLabel,
        detail: questIntel.recommendation,
        status: ArcCommandStatus.ready,
        primaryAction: const ArcCommandAction(
          label: 'Quest Tracker',
          routeName: ScrappyGridScreen.questRouteName,
        ),
      );
    }

    if (resourceIntel.hasCriticalBlocker) {
      final resource = resourceIntel.topResource!;
      return ArcCommandPriority(
        title: 'Farm ${resource.name}',
        explanation: resourceIntel.summary,
        progressLabel: resource.missingLabel,
        statusTag: resource.priorityLabel,
        detail: resource.recommendation,
        status: resource.status,
        primaryAction: const ArcCommandAction(
          label: 'Resource Tracker',
          routeName: ScrappyGridScreen.routeName,
        ),
        secondaryAction: resourceIntel.tradeTargets.isNotEmpty
            ? const ArcCommandAction(
                label: 'View Trades',
                routeName: TraderHubScreen.routeName,
              )
            : null,
      );
    }

    if (traderIntel.canAffordBestPurchase &&
        (traderIntel.bestPurchase?.priorityScore ?? 0) >= 60) {
      final purchase = traderIntel.bestPurchase!;
      return ArcCommandPriority(
        title: 'Buy ${purchase.purchase.name}',
        explanation: traderIntel.summary,
        progressLabel: purchase.priorityLabel,
        statusTag: traderIntel.statusLabel,
        detail: purchase.reason,
        status: ArcCommandStatus.ready,
        primaryAction: const ArcCommandAction(
          label: 'Nomadic Trader',
          intent: ArcCommandActionIntent.nomadicTrader,
        ),
        secondaryAction:
            purchase.missingResources.isNotEmpty || traderIntel.hasTradeableNeed
            ? const ArcCommandAction(
                label: 'View Trades',
                routeName: TraderHubScreen.routeName,
              )
            : null,
      );
    }

    if (benchIntel.hasBlocker && benchIntel.trackingKnown) {
      return ArcCommandPriority(
        title: 'Farm Bench Resources',
        explanation: benchIntel.summary,
        progressLabel: benchIntel.missingShortText,
        statusTag: benchIntel.statusLabel,
        detail: benchIntel.recommendation,
        status: benchIntel.status,
        primaryAction: const ArcCommandAction(
          label: 'Bench Tracker',
          routeName: ScrappyGridScreen.benchRouteName,
        ),
        secondaryAction: tradeActivity.communityListings > 0
            ? const ArcCommandAction(
                label: 'View Trades',
                routeName: TraderHubScreen.routeName,
              )
            : null,
      );
    }

    if (traderIntel.hasImportantGap &&
        (traderIntel.bestPurchase?.priorityScore ?? 0) >= 70) {
      final purchase = traderIntel.bestPurchase!;
      return ArcCommandPriority(
        title: 'Prepare Trader Purchase',
        explanation: traderIntel.summary,
        progressLabel: purchase.missingShortText,
        statusTag: purchase.priorityLabel,
        detail: traderIntel.hasTradeableNeed
            ? 'Use Trade Centre before farming: ${traderIntel.tradeNeedLabels.take(2).join(', ')}.'
            : traderIntel.recommendation,
        status: traderIntel.status,
        primaryAction: const ArcCommandAction(
          label: 'Nomadic Trader',
          intent: ArcCommandActionIntent.nomadicTrader,
        ),
        secondaryAction: traderIntel.hasTradeableNeed
            ? const ArcCommandAction(
                label: 'View Trades',
                routeName: TraderHubScreen.routeName,
              )
            : null,
      );
    }

    if (questIntel.hasBlocker && questIntel.trackingKnown) {
      return ArcCommandPriority(
        title: 'Farm Quest Items',
        explanation: questIntel.summary,
        progressLabel: questIntel.missingShortText,
        statusTag: questIntel.statusLabel,
        detail: questIntel.recommendation,
        status: questIntel.status,
        primaryAction: const ArcCommandAction(
          label: 'Quest Tracker',
          routeName: ScrappyGridScreen.questRouteName,
        ),
        secondaryAction: tradeActivity.communityListings > 0
            ? const ArcCommandAction(
                label: 'View Trades',
                routeName: TraderHubScreen.routeName,
              )
            : null,
      );
    }

    if (tradeActivity.hasActionableTrades) {
      final activeSessionBacklog = math.max(
        0,
        tradeActivity.activeSessions - tradeActivity.readySessions,
      );
      final tradeSignals = <String>[
        if (tradeActivity.unreadNotifications > 0)
          '${tradeActivity.unreadNotifications} unread',
        if (tradeActivity.pendingOffers > 0)
          '${tradeActivity.pendingOffers} ${_plural(tradeActivity.pendingOffers, 'pending offer', 'pending offers')}',
        if (tradeActivity.readySessions > 0)
          '${tradeActivity.readySessions} ${_plural(tradeActivity.readySessions, 'ready session', 'ready sessions')}',
        if (activeSessionBacklog > 0)
          '$activeSessionBacklog ${_plural(activeSessionBacklog, 'active session', 'active sessions')}',
        if (tradeActivity.intelligenceMatches > 0)
          '${tradeActivity.intelligenceMatches} smart ${_plural(tradeActivity.intelligenceMatches, 'match', 'matches')}',
      ];
      return ArcCommandPriority(
        title: tradeActivity.hasHighValueIntelligence
            ? 'Review Smart Trade Match'
            : 'Review Trade Activity',
        explanation: tradeActivity.hasHighValueIntelligence
            ? 'Trade Intelligence found ${tradeActivity.bestIntelligenceLabel.toLowerCase()} worth reviewing.'
            : 'Trading has live activity that may change your next move.',
        progressLabel: tradeSignals.isEmpty
            ? 'Trade signal ready'
            : tradeSignals.join(' - '),
        statusTag: tradeActivity.hasHighValueIntelligence
            ? '${tradeActivity.bestIntelligenceConfidence}% match'
            : 'Actionable',
        detail: tradeActivity.hasHighValueIntelligence
            ? 'Open Smart Trade Assist before creating a fresh listing.'
            : 'Clear offers and session updates before creating more listings.',
        status: ArcCommandStatus.ready,
        primaryAction: tradeActivity.hasHighValueIntelligence
            ? const ArcCommandAction(
                label: 'Smart Trade',
                intent: ArcCommandActionIntent.smartTrade,
              )
            : const ArcCommandAction(
                label: 'Open Trades',
                routeName: TraderHubScreen.routeName,
              ),
        secondaryAction: tradeActivity.unreadNotifications > 0
            ? const ArcCommandAction(
                label: 'Notifications',
                routeName: TradingNotificationsScreen.routeName,
              )
            : null,
      );
    }

    if (!loadoutSummary.ready) {
      return ArcCommandPriority(
        title: 'Finish Favourite Loadout',
        explanation: loadoutSummary.missingText,
        progressLabel: loadoutSummary.statusLabel,
        statusTag: 'High impact',
        detail: 'This is the fastest way to reduce pre-raid decision fatigue.',
        status: ArcCommandStatus.warning,
        primaryAction: const ArcCommandAction(
          label: 'Open Loadout',
          intent: ArcCommandActionIntent.favouriteLoadout,
        ),
      );
    }

    if (duplicateBlueprints > 0) {
      return ArcCommandPriority(
        title: 'Trade Duplicate Blueprints',
        explanation:
            'You have spare blueprint value that can help fill missing unlocks.',
        progressLabel: '$duplicateBlueprints duplicate ready',
        statusTag: 'Trade useful',
        detail: 'Review duplicates before farming more blueprint routes.',
        status: ArcCommandStatus.ready,
        primaryAction: const ArcCommandAction(
          label: 'Smart Trade',
          intent: ArcCommandActionIntent.smartTrade,
        ),
        secondaryAction: const ArcCommandAction(
          label: 'Create Trade',
          routeName: TradingCreateListingScreen.routeName,
        ),
      );
    }

    if (!blueprintStateKnown) {
      return const ArcCommandPriority(
        title: 'Start Blueprint Tracking',
        explanation:
            'Mark owned blueprints so the hub can identify blockers and useful trades.',
        progressLabel: 'Blueprint state not tracked yet',
        statusTag: 'Set up',
        detail:
            'The command engine gets sharper as soon as blueprint data exists.',
        status: ArcCommandStatus.neutral,
        primaryAction: ArcCommandAction(
          label: 'Open Blueprint Tracker',
          routeName: BlueprintGridScreen.routeName,
        ),
      );
    }

    if ((missingBlueprints ?? 0) > 0) {
      final target = prioritizedMissing.isEmpty
          ? 'missing blueprint routes'
          : prioritizedMissing.first;
      return ArcCommandPriority(
        title: 'Complete Blueprint Collection',
        explanation: 'Focus the next session on $target.',
        progressLabel: '$ownedBlueprints/$totalBlueprints owned',
        statusTag: '${missingBlueprints ?? 0} missing',
        detail:
            'Prioritized missing blueprints should guide loot and trade choices.',
        status: ArcCommandStatus.active,
        primaryAction: const ArcCommandAction(
          label: 'Open Blueprint Tracker',
          routeName: BlueprintGridScreen.routeName,
        ),
      );
    }

    if (inProgressOperations > 0 || operationsState.inventory.isNotEmpty) {
      return ArcCommandPriority(
        title: 'Advance Operations Track',
        explanation:
            'Operations progress is live and can feed Reward Vault cosmetics.',
        progressLabel:
            '${operationsState.completedCount}/${_operationTasks.length} complete',
        statusTag: '$inProgressOperations in progress',
        detail:
            '${operationsState.inventory.length} Vault reward ${_plural(operationsState.inventory.length, 'item', 'items')} unlocked.',
        status: ArcCommandStatus.active,
        primaryAction: const ArcCommandAction(
          label: 'Open Operations',
          intent: ArcCommandActionIntent.operations,
        ),
      );
    }

    return const ArcCommandPriority(
      title: 'Prepare for Weekly Trader',
      explanation:
          'Blueprint tracking and loadout setup are stable. Check trader targets next.',
      progressLabel: 'Core trackers ready',
      statusTag: 'Maintain',
      detail:
          'Nomadic Trader tracking can confirm whether today has a purchase worth making.',
      status: ArcCommandStatus.success,
      primaryAction: ArcCommandAction(
        label: 'Open Nomadic Trader',
        intent: ArcCommandActionIntent.nomadicTrader,
      ),
    );
  }

  static List<ArcCommandSnapshotMetric> _snapshots({
    required bool blueprintStateKnown,
    required int ownedBlueprints,
    required int totalBlueprints,
    required int? missingBlueprints,
    required int duplicateBlueprints,
    required ArcSavedLoadout? loadout,
    required _ArcLoadoutCommandSummary loadoutSummary,
    required ArcOperationsUserState operationsState,
    required ArcCommandTradeActivity tradeActivity,
    required int readyOperations,
    required int inProgressOperations,
    required ArcQuestIntelligence questIntel,
    required ArcBenchIntelligence benchIntel,
    required ArcNomadicTraderIntelligence traderIntel,
    required ArcResourceIntelligence resourceIntel,
  }) {
    return [
      ArcCommandSnapshotMetric(
        label: 'Intel Level',
        value: 'Intel L${operationsState.operationLevel}',
        detail: '${operationsState.intelXp} XP tracked',
        status: operationsState.intelXp > 0
            ? ArcCommandStatus.active
            : ArcCommandStatus.neutral,
      ),
      ArcCommandSnapshotMetric(
        label: 'Operations',
        value: readyOperations > 0
            ? '$readyOperations ready'
            : inProgressOperations > 0
            ? '$inProgressOperations active'
            : 'Set up',
        detail: readyOperations > 0
            ? 'Claim Operations reward'
            : inProgressOperations > 0
            ? 'Operations in progress'
            : 'Open Quest Tracker',
        status: readyOperations > 0
            ? ArcCommandStatus.ready
            : inProgressOperations > 0
            ? ArcCommandStatus.active
            : ArcCommandStatus.neutral,
      ),
      ArcCommandSnapshotMetric(
        label: 'Quest',
        value: questIntel.trackingKnown
            ? questIntel.readyToComplete
                  ? 'Ready'
                  : '${questIntel.completionPercent}%'
            : 'Set up',
        detail: questIntel.trackingKnown
            ? questIntel.questName
            : 'Open quest tracker',
        status: questIntel.status,
      ),
      ArcCommandSnapshotMetric(
        label: 'Bench',
        value: benchIntel.trackingKnown
            ? benchIntel.readyToUpgrade
                  ? 'Ready'
                  : '${benchIntel.completionPercent}%'
            : 'Set up',
        detail: benchIntel.trackingKnown
            ? benchIntel.upgradeLabel
            : 'Open bench tracker',
        status: benchIntel.status,
      ),
      ArcCommandSnapshotMetric(
        label: 'Resources',
        value: resourceIntel.trackingKnown
            ? resourceIntel.totalMissingResources > 0
                  ? '${resourceIntel.totalMissingResources} missing'
                  : resourceIntel.totalDuplicateResources > 0
                  ? '${resourceIntel.totalDuplicateResources} surplus'
                  : 'Stable'
            : 'Set up',
        detail: resourceIntel.trackingKnown
            ? resourceIntel.topResourceLabel
            : 'Track inventory',
        status: resourceIntel.status,
      ),
      ArcCommandSnapshotMetric(
        label: 'Nomadic Trader',
        value: !traderIntel.trackingKnown
            ? 'Set up'
            : traderIntel.canAffordBestPurchase || traderIntel.goalAffordable
            ? 'Ready'
            : '${traderIntel.completionPercent}%',
        detail: traderIntel.trackingKnown
            ? traderIntel.goalName
            : 'Open trader tracker',
        status: traderIntel.status,
      ),
      ArcCommandSnapshotMetric(
        label: 'Blueprints',
        value: blueprintStateKnown
            ? '$ownedBlueprints/$totalBlueprints'
            : 'Set up',
        detail: blueprintStateKnown
            ? '${missingBlueprints ?? 0} missing - $duplicateBlueprints dupes'
            : 'No owned state yet',
        status: blueprintStateKnown
            ? ArcCommandStatus.active
            : ArcCommandStatus.neutral,
      ),
      ArcCommandSnapshotMetric(
        label: 'Favourite Loadout',
        value: loadoutSummary.ready ? 'Ready' : 'Incomplete',
        detail: loadout?.name ?? loadoutSummary.statusLabel,
        status: loadoutSummary.ready
            ? ArcCommandStatus.success
            : ArcCommandStatus.warning,
      ),
      ArcCommandSnapshotMetric(
        label: 'Trade Activity',
        value: tradeActivity.hasActionableTrades
            ? '${tradeActivity.actionableCount} signals'
            : 'Quiet',
        detail: tradeActivity.bestIntelligenceConfidence > 0
            ? '${tradeActivity.bestIntelligenceConfidence}% ${tradeActivity.bestIntelligenceLabel}'
            : '${tradeActivity.activeMyListings} live listings - ${tradeActivity.pendingOffers} offers',
        status: tradeActivity.hasActionableTrades
            ? ArcCommandStatus.ready
            : ArcCommandStatus.neutral,
      ),
      ArcCommandSnapshotMetric(
        label: 'Reward Vault',
        value: '${operationsState.inventory.length} items',
        detail: '${_equippedCosmeticCount(operationsState)}/4 equipped',
        status: operationsState.inventory.isNotEmpty
            ? ArcCommandStatus.active
            : ArcCommandStatus.neutral,
      ),
      ArcCommandSnapshotMetric(
        label: 'Inventory',
        value: duplicateBlueprints > 0 ? '$duplicateBlueprints dupes' : 'Clear',
        detail: duplicateBlueprints > 0
            ? 'Blueprint trade value'
            : 'No duplicate blueprints',
        status: duplicateBlueprints > 0
            ? ArcCommandStatus.ready
            : ArcCommandStatus.neutral,
      ),
    ];
  }

  static List<ArcCommandObjective> _objectives({
    required bool blueprintStateKnown,
    required int ownedBlueprints,
    required int totalBlueprints,
    required int? missingBlueprints,
    required int duplicateBlueprints,
    required _ArcLoadoutCommandSummary loadoutSummary,
    required ArcOperationsUserState operationsState,
    required ArcCommandTradeActivity tradeActivity,
    required int readyOperations,
    required int inProgressOperations,
    required int availableOperations,
    required ArcQuestIntelligence questIntel,
    required ArcBenchIntelligence benchIntel,
    required ArcNomadicTraderIntelligence traderIntel,
    required ArcResourceIntelligence resourceIntel,
  }) {
    final objectives = <ArcCommandObjective>[];

    if (readyOperations > 0) {
      objectives.add(
        ArcCommandObjective(
          title: 'Claim Operation Rewards',
          reason:
              'Reward Vault unlocks are ready to claim from completed Operations.',
          statusLabel: 'Reward ready',
          progressText:
              '${operationsState.completedCount}/$availableOperations completed - ${operationsState.inventory.length} rewards owned',
          status: ArcCommandStatus.ready,
          action: const ArcCommandAction(
            label: 'Open Operations',
            intent: ArcCommandActionIntent.operations,
          ),
        ),
      );
    }

    if (resourceIntel.hasCriticalBlocker ||
        resourceIntel.farmTargets.isNotEmpty) {
      final resource =
          resourceIntel.topResource ?? resourceIntel.farmTargets.first;
      objectives.add(
        ArcCommandObjective(
          title: resource.blocksMultipleSystems
              ? 'Farm ${resource.name}'
              : 'Secure ${resource.name}',
          reason: resource.recommendation,
          statusLabel: resource.priorityLabel,
          progressText: resource.missingLabel,
          status: resource.status,
          action: const ArcCommandAction(
            label: 'Resources',
            routeName: ScrappyGridScreen.routeName,
          ),
        ),
      );
    }

    if (traderIntel.shouldVisit) {
      final purchase = traderIntel.bestPurchase;
      objectives.add(
        ArcCommandObjective(
          title: purchase == null
              ? 'Visit Nomadic Trader'
              : purchase.canAfford
              ? 'Buy ${purchase.purchase.name}'
              : 'Prepare ${purchase.purchase.name}',
          reason: traderIntel.recommendation,
          statusLabel: traderIntel.statusLabel,
          progressText: purchase == null
              ? traderIntel.progressLabel
              : purchase.canAfford
              ? purchase.priorityLabel
              : purchase.missingShortText,
          status: traderIntel.status,
          action: const ArcCommandAction(
            label: 'Nomadic Trader',
            intent: ArcCommandActionIntent.nomadicTrader,
          ),
        ),
      );
    }

    objectives.addAll([
      ArcCommandObjective(
        title: benchIntel.readyToUpgrade
            ? 'Upgrade ${benchIntel.station}'
            : 'Progress ${benchIntel.upgradeLabel}',
        reason: benchIntel.recommendation,
        statusLabel: benchIntel.statusLabel,
        progressText: benchIntel.trackingKnown
            ? benchIntel.progressLabel
            : benchIntel.summary,
        status: benchIntel.status,
        action: const ArcCommandAction(
          label: 'Bench Tracker',
          routeName: ScrappyGridScreen.benchRouteName,
        ),
      ),
      ArcCommandObjective(
        title: questIntel.readyToComplete
            ? 'Complete ${questIntel.questName}'
            : 'Progress ${questIntel.questName}',
        reason: questIntel.recommendation,
        statusLabel: questIntel.statusLabel,
        progressText: questIntel.trackingKnown
            ? questIntel.progressLabel
            : questIntel.summary,
        status: questIntel.status,
        action: const ArcCommandAction(
          label: 'Quest Tracker',
          routeName: ScrappyGridScreen.questRouteName,
        ),
      ),
    ]);

    if (tradeActivity.hasActionableTrades) {
      objectives.add(
        ArcCommandObjective(
          title: 'Review Trade Centre',
          reason: 'Listings, offers, sessions or notifications need attention.',
          statusLabel: 'Actionable',
          progressText:
              '${tradeActivity.activeMyListings} live listings - ${tradeActivity.pendingOffers} pending offers - ${tradeActivity.activeSessions} sessions',
          status: ArcCommandStatus.ready,
          action: const ArcCommandAction(
            label: 'Open Trades',
            routeName: TraderHubScreen.routeName,
          ),
        ),
      );
    }

    if (!loadoutSummary.ready) {
      objectives.add(
        ArcCommandObjective(
          title: 'Complete Favourite Loadout',
          reason: loadoutSummary.missingText,
          statusLabel: loadoutSummary.statusLabel,
          progressText: 'Missing: ${loadoutSummary.missingShortText}',
          status: ArcCommandStatus.warning,
          action: const ArcCommandAction(
            label: 'Open Loadout',
            intent: ArcCommandActionIntent.favouriteLoadout,
          ),
        ),
      );
    }

    objectives.add(
      ArcCommandObjective(
        title: 'Complete Blueprint Collection',
        reason: blueprintStateKnown
            ? 'Use the tracker to focus missing unlocks.'
            : 'Mark owned blueprints so collection blockers become visible.',
        statusLabel: blueprintStateKnown ? 'Tracking' : 'Set up',
        progressText: blueprintStateKnown
            ? '$ownedBlueprints/$totalBlueprints owned'
            : 'No blueprint state yet',
        status: blueprintStateKnown
            ? ArcCommandStatus.active
            : ArcCommandStatus.neutral,
        action: const ArcCommandAction(
          label: 'Open Blueprints',
          routeName: BlueprintGridScreen.routeName,
        ),
      ),
    );

    if (duplicateBlueprints > 0) {
      objectives.add(
        ArcCommandObjective(
          title: 'Review Duplicate Blueprints',
          reason: 'Duplicates can become trade leverage.',
          statusLabel: 'Trade ready',
          progressText: '$duplicateBlueprints duplicate tracked',
          status: ArcCommandStatus.ready,
          action: const ArcCommandAction(
            label: 'Smart Trade',
            intent: ArcCommandActionIntent.smartTrade,
          ),
        ),
      );
    }

    if (inProgressOperations > 0 && readyOperations == 0) {
      objectives.add(
        ArcCommandObjective(
          title: 'Advance Operations Progress',
          reason:
              'Operations progress feeds Reward Vault cosmetics and profile identity.',
          statusLabel: 'In progress',
          progressText:
              '${operationsState.completedCount}/$availableOperations completed - ${operationsState.inventory.length} rewards owned',
          status: ArcCommandStatus.active,
          action: const ArcCommandAction(
            label: 'Open Operations',
            intent: ArcCommandActionIntent.operations,
          ),
        ),
      );
    }

    if (objectives.length < 6) {
      objectives.add(
        ArcCommandObjective(
          title: 'Plan Next Trade',
          reason: _tradeCanHelpProgress(questIntel, benchIntel, traderIntel)
              ? 'Trades may help with quest or bench blockers before farming.'
              : (missingBlueprints ?? 0) > 0
              ? 'Missing blueprints can be routed through trade before farming.'
              : 'Trade tools are ready when a new target appears.',
          statusLabel: 'Optional',
          progressText:
              _tradeCanHelpProgress(questIntel, benchIntel, traderIntel)
              ? 'Bench or quest needs visible'
              : (missingBlueprints ?? 0) > 0
              ? '${missingBlueprints ?? 0} possible needs'
              : 'No tracked blockers',
          status: ArcCommandStatus.neutral,
          action: const ArcCommandAction(
            label: 'View Trades',
            routeName: TraderHubScreen.routeName,
          ),
        ),
      );
    }

    return objectives;
  }

  static List<ArcCommandAlert> _alerts({
    required bool blueprintStateKnown,
    required int duplicateBlueprints,
    required int? missingBlueprints,
    required _ArcLoadoutCommandSummary loadoutSummary,
    required ArcCommandTradeActivity tradeActivity,
    required int readyOperations,
    required ArcQuestIntelligence questIntel,
    required ArcBenchIntelligence benchIntel,
    required ArcNomadicTraderIntelligence traderIntel,
    required ArcResourceIntelligence resourceIntel,
  }) {
    final alerts = <ArcCommandAlert>[];
    if (readyOperations > 0) {
      alerts.add(
        ArcCommandAlert(
          title: 'Operation rewards ready',
          body:
              '$readyOperations reward ${_plural(readyOperations, 'is', 'are')} ready to claim in Operations.',
          statusLabel: 'Claim',
          status: ArcCommandStatus.ready,
          action: const ArcCommandAction(
            label: 'Operations',
            intent: ArcCommandActionIntent.operations,
          ),
        ),
      );
    }
    if (benchIntel.readyToUpgrade) {
      alerts.add(
        ArcCommandAlert(
          title: '${benchIntel.upgradeLabel} ready',
          body: benchIntel.recommendation,
          statusLabel: 'Upgrade',
          status: ArcCommandStatus.ready,
          action: const ArcCommandAction(
            label: 'Bench',
            routeName: ScrappyGridScreen.benchRouteName,
          ),
        ),
      );
    } else if (benchIntel.hasBlocker && benchIntel.trackingKnown) {
      alerts.add(
        ArcCommandAlert(
          title: 'Bench resource blocker',
          body: benchIntel.missingShortText,
          statusLabel: 'Missing',
          status: benchIntel.status,
          action: const ArcCommandAction(
            label: 'Bench',
            routeName: ScrappyGridScreen.benchRouteName,
          ),
        ),
      );
    }
    if (questIntel.readyToComplete) {
      alerts.add(
        ArcCommandAlert(
          title: '${questIntel.questName} ready',
          body: questIntel.recommendation,
          statusLabel: 'Complete',
          status: ArcCommandStatus.ready,
          action: const ArcCommandAction(
            label: 'Quest',
            routeName: ScrappyGridScreen.questRouteName,
          ),
        ),
      );
    } else if (questIntel.hasBlocker && questIntel.trackingKnown) {
      alerts.add(
        ArcCommandAlert(
          title: 'Quest item blocker',
          body: questIntel.missingShortText,
          statusLabel: 'Missing',
          status: questIntel.status,
          action: const ArcCommandAction(
            label: 'Quest',
            routeName: ScrappyGridScreen.questRouteName,
          ),
        ),
      );
    }
    if (traderIntel.canAffordBestPurchase) {
      final purchase = traderIntel.bestPurchase!;
      alerts.add(
        ArcCommandAlert(
          title: 'Trader purchase ready',
          body: '${purchase.purchase.name} can be bought or marked purchased.',
          statusLabel: 'Buy',
          status: ArcCommandStatus.ready,
          action: const ArcCommandAction(
            label: 'Trader',
            intent: ArcCommandActionIntent.nomadicTrader,
          ),
        ),
      );
    } else if (traderIntel.hasImportantGap) {
      final purchase = traderIntel.bestPurchase!;
      alerts.add(
        ArcCommandAlert(
          title: 'Trader resource gap',
          body: purchase.missingShortText,
          statusLabel: purchase.priorityLabel,
          status: traderIntel.status,
          action: const ArcCommandAction(
            label: 'Trader',
            intent: ArcCommandActionIntent.nomadicTrader,
          ),
        ),
      );
    }
    if (resourceIntel.hasCriticalBlocker) {
      final resource = resourceIntel.topResource!;
      alerts.add(
        ArcCommandAlert(
          title: 'Protected resource blocker',
          body: resource.recommendation,
          statusLabel: resource.protectionLabel,
          status: resource.status,
          action: const ArcCommandAction(
            label: 'Resources',
            routeName: ScrappyGridScreen.routeName,
          ),
        ),
      );
    } else if (resourceIntel.hasTradeSurplus) {
      final resource = resourceIntel.safeTradeCandidates.first;
      alerts.add(
        ArcCommandAlert(
          title: 'Safe trade surplus',
          body: resource.recommendation,
          statusLabel: 'Surplus',
          status: ArcCommandStatus.ready,
          action: const ArcCommandAction(
            label: 'Trade Centre',
            routeName: TraderHubScreen.routeName,
          ),
        ),
      );
    }
    if (tradeActivity.unreadNotifications > 0) {
      alerts.add(
        ArcCommandAlert(
          title: 'Unread trade notifications',
          body:
              '${tradeActivity.unreadNotifications} trade notification ${_plural(tradeActivity.unreadNotifications, 'needs', 'need')} review.',
          statusLabel: 'Inbox',
          status: ArcCommandStatus.ready,
          action: const ArcCommandAction(
            label: 'Notifications',
            routeName: TradingNotificationsScreen.routeName,
          ),
        ),
      );
    }
    if (tradeActivity.pendingOffers > 0) {
      alerts.add(
        ArcCommandAlert(
          title: 'Pending offers waiting',
          body:
              '${tradeActivity.pendingOffers} offer ${_plural(tradeActivity.pendingOffers, 'is', 'are')} pending in the Trade Centre.',
          statusLabel: 'Offer',
          status: ArcCommandStatus.ready,
          action: const ArcCommandAction(
            label: 'Offers',
            routeName: TradingMyOffersScreen.routeName,
          ),
        ),
      );
    }
    if (tradeActivity.hasHighValueIntelligence) {
      alerts.add(
        ArcCommandAlert(
          title: 'High-value smart match',
          body:
              '${tradeActivity.bestIntelligenceLabel} scored ${tradeActivity.bestIntelligenceConfidence}%.',
          statusLabel: 'Smart match',
          status: ArcCommandStatus.ready,
          action: const ArcCommandAction(
            label: 'Smart Trade',
            intent: ArcCommandActionIntent.smartTrade,
          ),
        ),
      );
    }
    if (!loadoutSummary.ready) {
      alerts.add(
        ArcCommandAlert(
          title: 'Loadout incomplete',
          body: loadoutSummary.missingText,
          statusLabel: 'Action needed',
          status: ArcCommandStatus.warning,
          action: const ArcCommandAction(
            label: 'Open Loadout',
            intent: ArcCommandActionIntent.favouriteLoadout,
          ),
        ),
      );
    }
    if (duplicateBlueprints > 0) {
      alerts.add(
        ArcCommandAlert(
          title: 'Duplicate blueprints available',
          body:
              '$duplicateBlueprints duplicate blueprint can be reviewed for trades.',
          statusLabel: 'Trade value',
          status: ArcCommandStatus.ready,
          action: const ArcCommandAction(
            label: 'Smart Trade',
            intent: ArcCommandActionIntent.smartTrade,
          ),
        ),
      );
    }
    if (!blueprintStateKnown) {
      alerts.add(
        const ArcCommandAlert(
          title: 'Blueprint tracker not initialized',
          body:
              'Marking owned blueprints unlocks collection and trade guidance.',
          statusLabel: 'Set up',
          status: ArcCommandStatus.neutral,
          action: ArcCommandAction(
            label: 'Open Tracker',
            routeName: BlueprintGridScreen.routeName,
          ),
        ),
      );
    } else if ((missingBlueprints ?? 0) > 0) {
      alerts.add(
        ArcCommandAlert(
          title: 'Missing blueprint blockers',
          body: '${missingBlueprints ?? 0} blueprint unlocks are still open.',
          statusLabel: 'Track',
          status: ArcCommandStatus.active,
          action: const ArcCommandAction(
            label: 'Open Tracker',
            routeName: BlueprintGridScreen.routeName,
          ),
        ),
      );
    }
    if (alerts.isEmpty) {
      alerts.add(
        const ArcCommandAlert(
          title: 'Command centre quiet',
          body:
              'No live trade, duplicate, loadout or operation blockers are waiting.',
          statusLabel: 'Clear',
          status: ArcCommandStatus.success,
          action: ArcCommandAction(
            label: 'Tool Deck',
            intent: ArcCommandActionIntent.toolDeck,
          ),
        ),
      );
    }
    return alerts;
  }

  static List<ArcCommandRecommendation> _recommendations({
    required bool blueprintStateKnown,
    required int? missingBlueprints,
    required int duplicateBlueprints,
    required _ArcLoadoutCommandSummary loadoutSummary,
    required ArcCommandTradeActivity tradeActivity,
    required int readyOperations,
    required ArcQuestIntelligence questIntel,
    required ArcBenchIntelligence benchIntel,
    required ArcNomadicTraderIntelligence traderIntel,
    required ArcResourceIntelligence resourceIntel,
  }) {
    final recommendations = <ArcCommandRecommendation>[];

    if (readyOperations > 0) {
      recommendations.add(
        const ArcCommandRecommendation(
          title: 'Claim Operations rewards before changing cosmetics.',
          body:
              'Reward Vault state updates immediately after Operations rewards are claimed.',
          action: ArcCommandAction(
            label: 'Operations',
            intent: ArcCommandActionIntent.operations,
          ),
        ),
      );
    }

    if (resourceIntel.trackingKnown) {
      final resource = resourceIntel.topResource;
      recommendations.add(
        ArcCommandRecommendation(
          title: resource == null
              ? 'Keep resource tracking current.'
              : resource.safeToTrade
              ? 'Offer surplus ${resource.name} before farming more.'
              : resource.neverTrade
              ? 'Never trade ${resource.name} until blockers clear.'
              : 'Farm ${resource.name} before trading it away.',
          body: resource?.recommendation ?? resourceIntel.recommendation,
          action: ArcCommandAction(
            label: resourceIntel.hasTradeSurplus ? 'Trade Centre' : 'Resources',
            routeName: resourceIntel.hasTradeSurplus
                ? TraderHubScreen.routeName
                : ScrappyGridScreen.routeName,
          ),
        ),
      );
    }

    if (traderIntel.trackingKnown) {
      final purchase = traderIntel.bestPurchase;
      recommendations.add(
        ArcCommandRecommendation(
          title: traderIntel.canAffordBestPurchase && purchase != null
              ? 'Buy ${purchase.purchase.name} before spending resources.'
              : traderIntel.hasImportantGap && purchase != null
              ? 'Trade or farm for ${purchase.purchase.name}.'
              : 'Review Nomadic Trader goals before farming.',
          body: purchase == null ? traderIntel.recommendation : purchase.reason,
          action: const ArcCommandAction(
            label: 'Nomadic Trader',
            intent: ArcCommandActionIntent.nomadicTrader,
          ),
        ),
      );
    }

    recommendations.add(
      ArcCommandRecommendation(
        title: benchIntel.readyToUpgrade
            ? 'Upgrade ${benchIntel.station} before spending resources.'
            : benchIntel.trackingKnown
            ? 'Use Bench Operations for ${benchIntel.upgradeLabel}.'
            : 'Set up Bench Operations to unlock resource guidance.',
        body: benchIntel.recommendation,
        action: const ArcCommandAction(
          label: 'Bench Tracker',
          routeName: ScrappyGridScreen.benchRouteName,
        ),
      ),
    );

    recommendations.add(
      ArcCommandRecommendation(
        title: questIntel.readyToComplete
            ? 'Complete ${questIntel.questName} before farming more.'
            : questIntel.trackingKnown
            ? 'Focus ${questIntel.questName} quest requirements.'
            : 'Set up Mission Operations for quest item guidance.',
        body: questIntel.recommendation,
        action: const ArcCommandAction(
          label: 'Quest Tracker',
          routeName: ScrappyGridScreen.questRouteName,
        ),
      ),
    );

    if (_tradeCanHelpProgress(questIntel, benchIntel, traderIntel)) {
      recommendations.add(
        const ArcCommandRecommendation(
          title: 'Check trades for bench or quest blockers.',
          body:
              'Trade Centre can help clear item gaps before another farming route.',
          action: ArcCommandAction(
            label: 'Trade Centre',
            routeName: TraderHubScreen.routeName,
          ),
        ),
      );
    }

    if (tradeActivity.hasActionableTrades) {
      recommendations.add(
        ArcCommandRecommendation(
          title: tradeActivity.hasHighValueIntelligence
              ? 'Review the top Smart Trade match before farming.'
              : 'Resolve ${tradeActivity.actionableCount} live trade ${_plural(tradeActivity.actionableCount, 'signal', 'signals')} first.',
          body: tradeActivity.hasHighValueIntelligence
              ? '${tradeActivity.bestIntelligenceLabel} is currently the strongest trade signal.'
              : 'Offers, sessions and notifications can alter what you should farm or list next.',
          action: tradeActivity.hasHighValueIntelligence
              ? const ArcCommandAction(
                  label: 'Smart Trade',
                  intent: ArcCommandActionIntent.smartTrade,
                )
              : const ArcCommandAction(
                  label: 'Trade Centre',
                  routeName: TraderHubScreen.routeName,
                ),
        ),
      );
    }

    if (!loadoutSummary.ready || recommendations.length < 4) {
      recommendations.add(
        ArcCommandRecommendation(
          title: loadoutSummary.ready
              ? 'Review your Favourite Loadout before raids.'
              : 'Finish your Favourite Loadout before entering raids.',
          body: loadoutSummary.ready
              ? loadoutSummary.detail
              : loadoutSummary.missingText,
          action: const ArcCommandAction(
            label: 'Open Loadout',
            intent: ArcCommandActionIntent.favouriteLoadout,
          ),
        ),
      );
    }

    if (duplicateBlueprints > 0) {
      recommendations.add(
        const ArcCommandRecommendation(
          title: 'Turn duplicate blueprints into trade leverage.',
          body:
              'Smart Trade can compare duplicate value against collection needs.',
          action: ArcCommandAction(
            label: 'Smart Trade',
            intent: ArcCommandActionIntent.smartTrade,
          ),
        ),
      );
    } else {
      recommendations.add(
        const ArcCommandRecommendation(
          title: 'Keep duplicate blueprint tracking current.',
          body: 'Trade value is easiest to act on when duplicates are visible.',
          action: ArcCommandAction(
            label: 'Open Blueprints',
            routeName: BlueprintGridScreen.routeName,
          ),
        ),
      );
    }

    recommendations.add(
      ArcCommandRecommendation(
        title: blueprintStateKnown && (missingBlueprints ?? 0) > 0
            ? 'Focus missing blueprints before broad farming.'
            : blueprintStateKnown
            ? 'Collection tracking is stable.'
            : 'Start with blueprint tracking for sharper recommendations.',
        body: blueprintStateKnown
            ? '${missingBlueprints ?? 0} blueprint gaps remain visible to the command engine.'
            : 'A smaller tracked queue keeps the next step obvious.',
        action: const ArcCommandAction(
          label: 'Open Blueprints',
          routeName: BlueprintGridScreen.routeName,
        ),
      ),
    );

    if (recommendations.length < 4) {
      recommendations.add(
        const ArcCommandRecommendation(
          title: 'Check weekly trader before farming resources.',
          body: 'Trader goals can change which resources are worth keeping.',
          action: ArcCommandAction(
            label: 'Nomadic Trader',
            intent: ArcCommandActionIntent.nomadicTrader,
          ),
        ),
      );
    }

    return recommendations.take(4).toList(growable: false);
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
          placeholderMessage: 'Raid planner hook is ready for phase 2 wiring.',
          intent: ArcCommandActionIntent.placeholder,
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
        reason: tradeActivity.hasActionableTrades
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

  static List<ArcCommandResourceStatus> _resources(
    ArcResourceIntelligence resourceIntel,
  ) {
    if (resourceIntel.highestPriorityResources.isNotEmpty) {
      return resourceIntel.highestPriorityResources
          .take(4)
          .map(
            (resource) => ArcCommandResourceStatus(
              name: resource.name,
              ownedLabel: '${resource.ownedCount} owned',
              requiredLabel: resource.isMissing
                  ? '${resource.missingCount} missing'
                  : resource.duplicateLabel,
              status: resource.status,
            ),
          )
          .toList(growable: false);
    }

    return const [
      ArcCommandResourceStatus(
        name: 'Resources',
        ownedLabel: 'Not tracked yet',
        requiredLabel: 'Track resources',
        status: ArcCommandStatus.neutral,
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
  }) {
    final lookingFor = <String>[
      if (tradeActivity.pendingOffers > 0)
        '${tradeActivity.pendingOffers} pending ${_plural(tradeActivity.pendingOffers, 'offer', 'offers')}',
      if (tradeActivity.activeSessions > 0)
        '${tradeActivity.activeSessions} active trade ${_plural(tradeActivity.activeSessions, 'session', 'sessions')}',
      if (tradeActivity.bestIntelligenceConfidence > 0)
        '${tradeActivity.bestIntelligenceConfidence}% ${tradeActivity.bestIntelligenceLabel}',
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
  }) {
    return ArcCommandSummaryPanel(
      title: 'Statistics',
      statusLabel: 'Live summary',
      body: 'Command Centre is aggregating safe live signals from core tools.',
      details: [
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
