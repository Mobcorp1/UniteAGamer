import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_bench_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_decision_engine_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_nomadic_trader_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_quest_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_resource_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_blueprint_watches_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_create_listing_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_listing_queues_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart';

class ArcDecisionEngine {
  const ArcDecisionEngine();

  ArcDecisionState build({
    required bool blueprintStateKnown,
    required int ownedBlueprints,
    required int totalBlueprints,
    required int? missingBlueprints,
    required int duplicateBlueprints,
    required List<String> prioritizedMissingBlueprints,
    required ArcSavedLoadout? favouriteLoadout,
    required ArcOperationsUserState operationsState,
    required ArcCommandTradeActivity tradeActivity,
    required int readyOperations,
    required int inProgressOperations,
    required int availableOperations,
    required ArcQuestIntelligence questIntel,
    required ArcBenchIntelligence benchIntel,
    required ArcNomadicTraderIntelligence traderIntel,
    required ArcResourceIntelligence resourceIntel,
    ArcRaidIntelligenceState? raidIntelligence,
  }) {
    final loadoutSummary = _loadoutSummary(favouriteLoadout);
    final signals = <ArcDecisionSignal>[];

    void add(ArcDecisionSignal signal) => signals.add(signal);

    if (readyOperations > 0) {
      add(
        _signal(
          id: 'operations-claim',
          title: 'Claim Operation Rewards',
          summary:
              '$readyOperations operation reward ${_plural(readyOperations, 'is', 'are')} ready in Operations.',
          detail:
              'Claim rewards before planning the next objective so Vault and profile cosmetics stay current.',
          category: ArcDecisionCategory.operations,
          status: ArcCommandStatus.ready,
          progressLabel: '$readyOperations ready to claim',
          action: const ArcDecisionAction(
            label: 'Open Operations',
            intent: ArcCommandActionIntent.operations,
          ),
          sourceSystem: 'Operations',
          score: _score(
            readiness: 96,
            timeSensitivity: 72,
            progressionUnlockValue: 72,
            completionPercentage: 100,
            setupCompleteness: 90,
            confidence: 96,
          ),
        ),
      );
    }

    if (benchIntel.readyToUpgrade) {
      add(
        _signal(
          id: 'bench-ready',
          title: 'Upgrade ${benchIntel.station}',
          summary: benchIntel.summary,
          detail: benchIntel.recommendation,
          category: ArcDecisionCategory.bench,
          status: ArcCommandStatus.ready,
          progressLabel: benchIntel.progressLabel,
          action: const ArcDecisionAction(
            label: 'Bench Tracker',
            routeName: ScrappyGridScreen.benchRouteName,
          ),
          sourceSystem: 'Bench Intelligence',
          score: _score(
            readiness: 100,
            progressionUnlockValue: 90,
            completionPercentage: benchIntel.completionPercent,
            setupCompleteness: 95,
            confidence: 95,
          ),
        ),
      );
    } else if (benchIntel.hasBlocker && benchIntel.trackingKnown) {
      add(
        _signal(
          id: 'bench-blocker',
          title: 'Farm Bench Resources',
          summary: benchIntel.summary,
          detail: benchIntel.recommendation,
          category: ArcDecisionCategory.bench,
          status: benchIntel.status,
          progressLabel: benchIntel.missingShortText,
          action: const ArcDecisionAction(
            label: 'Bench Tracker',
            routeName: ScrappyGridScreen.benchRouteName,
          ),
          secondaryAction: tradeActivity.communityListings > 0
              ? const ArcDecisionAction(
                  label: 'View Trades',
                  routeName: TraderHubScreen.routeName,
                )
              : null,
          sourceSystem: 'Bench Intelligence',
          tradeAssisted: tradeActivity.communityListings > 0,
          score: _score(
            blockerSeverity: 78,
            tradeAvailability: tradeActivity.communityListings > 0 ? 58 : 12,
            progressionUnlockValue: 82,
            missingResourcePressure: _missingPressure(benchIntel.missingCount),
            completionPercentage: benchIntel.completionPercent,
            setupCompleteness: 88,
            confidence: 88,
          ),
        ),
      );
    } else if (_hasTrackedIncompleteProgress(
      trackingKnown: benchIntel.trackingKnown,
      status: benchIntel.status,
      completionPercent: benchIntel.completionPercent,
    )) {
      add(
        _signal(
          id: 'bench-progress',
          title: 'Progress ${benchIntel.upgradeLabel}',
          summary: benchIntel.summary,
          detail: benchIntel.recommendation,
          category: ArcDecisionCategory.bench,
          status: benchIntel.status,
          progressLabel: benchIntel.trackingKnown
              ? benchIntel.progressLabel
              : 'Set up bench tracker',
          action: const ArcDecisionAction(
            label: 'Bench Tracker',
            routeName: ScrappyGridScreen.benchRouteName,
          ),
          sourceSystem: 'Bench Intelligence',
          score: _score(
            progressionUnlockValue: 46,
            completionPercentage: benchIntel.completionPercent,
            setupCompleteness: benchIntel.trackingKnown ? 74 : 18,
            confidence: benchIntel.trackingKnown ? 72 : 36,
          ),
        ),
      );
    }

    if (questIntel.readyToComplete) {
      add(
        _signal(
          id: 'quest-ready',
          title: 'Complete ${questIntel.questName}',
          summary: questIntel.summary,
          detail: questIntel.recommendation,
          category: ArcDecisionCategory.quest,
          status: ArcCommandStatus.ready,
          progressLabel: questIntel.progressLabel,
          action: const ArcDecisionAction(
            label: 'Quest Tracker',
            routeName: ScrappyGridScreen.questRouteName,
          ),
          sourceSystem: 'Quest Intelligence',
          score: _score(
            readiness: 98,
            progressionUnlockValue: 82,
            completionPercentage: questIntel.completionPercent,
            setupCompleteness: 95,
            confidence: 94,
          ),
        ),
      );
    } else if (questIntel.hasBlocker && questIntel.trackingKnown) {
      add(
        _signal(
          id: 'quest-blocker',
          title: 'Farm Quest Items',
          summary: questIntel.summary,
          detail: questIntel.recommendation,
          category: ArcDecisionCategory.quest,
          status: questIntel.status,
          progressLabel: questIntel.missingShortText,
          action: const ArcDecisionAction(
            label: 'Quest Tracker',
            routeName: ScrappyGridScreen.questRouteName,
          ),
          secondaryAction: tradeActivity.communityListings > 0
              ? const ArcDecisionAction(
                  label: 'View Trades',
                  routeName: TraderHubScreen.routeName,
                )
              : null,
          sourceSystem: 'Quest Intelligence',
          tradeAssisted: tradeActivity.communityListings > 0,
          score: _score(
            blockerSeverity: 74,
            tradeAvailability: tradeActivity.communityListings > 0 ? 56 : 10,
            progressionUnlockValue: 78,
            missingResourcePressure: _missingPressure(questIntel.missingCount),
            completionPercentage: questIntel.completionPercent,
            setupCompleteness: 88,
            confidence: 88,
          ),
        ),
      );
    } else if (_hasTrackedIncompleteProgress(
      trackingKnown: questIntel.trackingKnown,
      status: questIntel.status,
      completionPercent: questIntel.completionPercent,
    )) {
      add(
        _signal(
          id: 'quest-progress',
          title: 'Progress ${questIntel.questName}',
          summary: questIntel.summary,
          detail: questIntel.recommendation,
          category: ArcDecisionCategory.quest,
          status: questIntel.status,
          progressLabel: questIntel.trackingKnown
              ? questIntel.progressLabel
              : 'Set up quest tracker',
          action: const ArcDecisionAction(
            label: 'Quest Tracker',
            routeName: ScrappyGridScreen.questRouteName,
          ),
          sourceSystem: 'Quest Intelligence',
          score: _score(
            progressionUnlockValue: 44,
            completionPercentage: questIntel.completionPercent,
            setupCompleteness: questIntel.trackingKnown ? 74 : 18,
            confidence: questIntel.trackingKnown ? 72 : 36,
          ),
        ),
      );
    }

    final topResource = resourceIntel.topResource;
    if (resourceIntel.hasCriticalBlocker && topResource != null) {
      add(
        _signal(
          id: 'resource-critical-${topResource.id}',
          title: 'Farm ${topResource.name}',
          summary: resourceIntel.summary,
          detail: topResource.recommendation,
          category: ArcDecisionCategory.criticalBlocker,
          status: topResource.status,
          progressLabel: topResource.missingLabel,
          action: const ArcDecisionAction(
            label: 'Resource Tracker',
            routeName: ScrappyGridScreen.routeName,
          ),
          secondaryAction: resourceIntel.tradeTargets.isNotEmpty
              ? const ArcDecisionAction(
                  label: 'View Trades',
                  routeName: TraderHubScreen.routeName,
                )
              : null,
          sourceSystem: 'Resource Intelligence',
          tradeAssisted: resourceIntel.tradeTargets.isNotEmpty,
          score: _score(
            blockerSeverity: topResource.blocksMultipleSystems ? 96 : 82,
            multiSystemImpact: topResource.blocksMultipleSystems ? 94 : 46,
            tradeAvailability: resourceIntel.tradeTargets.isNotEmpty ? 62 : 12,
            progressionUnlockValue: topResource.progressionValue,
            missingResourcePressure: _missingPressure(topResource.missingCount),
            setupCompleteness: 92,
            confidence: 90,
          ),
        ),
      );
    } else if (resourceIntel.farmTargets.isNotEmpty) {
      final resource = resourceIntel.farmTargets.first;
      add(
        _signal(
          id: 'resource-farm-${resource.id}',
          title: 'Secure ${resource.name}',
          summary: resourceIntel.summary,
          detail: resource.recommendation,
          category: ArcDecisionCategory.resources,
          status: resource.status,
          progressLabel: resource.missingLabel,
          action: const ArcDecisionAction(
            label: 'Resources',
            routeName: ScrappyGridScreen.routeName,
          ),
          sourceSystem: 'Resource Intelligence',
          score: _score(
            blockerSeverity: resource.isMissing ? 46 : 0,
            multiSystemImpact: resource.usedByMultipleSystems ? 52 : 18,
            progressionUnlockValue: resource.progressionValue,
            missingResourcePressure: _missingPressure(resource.missingCount),
            setupCompleteness: 82,
            confidence: 82,
          ),
        ),
      );
    }

    if (resourceIntel.safeTradeCandidates.isNotEmpty) {
      final resource = resourceIntel.safeTradeCandidates.first;
      add(
        _signal(
          id: 'resource-safe-trade-${resource.id}',
          title: 'Trade Surplus ${resource.name}',
          summary:
              'Safe surplus is available without blocking tracked systems.',
          detail: resource.recommendation,
          category: ArcDecisionCategory.inventory,
          status: ArcCommandStatus.ready,
          progressLabel: resource.duplicateLabel,
          action: const ArcDecisionAction(
            label: 'Trade Centre',
            routeName: TraderHubScreen.routeName,
          ),
          sourceSystem: 'Resource Intelligence',
          tradeAssisted: true,
          score: _score(
            readiness: 74,
            tradeAvailability: 84,
            progressionUnlockValue: 42,
            setupCompleteness: 84,
            confidence: 84,
          ),
        ),
      );
    }

    if (traderIntel.canAffordBestPurchase) {
      final purchase = traderIntel.bestPurchase!;
      add(
        _signal(
          id: 'nomadic-buy-${purchase.purchase.id}',
          title: 'Buy ${purchase.purchase.name}',
          summary: traderIntel.summary,
          detail: purchase.reason,
          category: ArcDecisionCategory.nomadicTrader,
          status: ArcCommandStatus.ready,
          progressLabel: purchase.priorityLabel,
          action: const ArcDecisionAction(
            label: 'Nomadic Trader',
            intent: ArcCommandActionIntent.nomadicTrader,
          ),
          sourceSystem: 'Nomadic Trader Intelligence',
          score: _score(
            readiness: 92,
            timeSensitivity: traderIntel.resetLabel == null ? 28 : 64,
            progressionUnlockValue: purchase.priorityScore,
            completionPercentage: traderIntel.completionPercent,
            setupCompleteness: 86,
            confidence: 84,
          ),
        ),
      );
    } else if (traderIntel.hasImportantGap) {
      final purchase = traderIntel.bestPurchase!;
      add(
        _signal(
          id: 'nomadic-prepare-${purchase.purchase.id}',
          title: 'Prepare Trader Purchase',
          summary: traderIntel.summary,
          detail: traderIntel.hasTradeableNeed
              ? 'Use Trade Centre before farming: ${traderIntel.tradeNeedLabels.take(2).join(', ')}.'
              : traderIntel.recommendation,
          category: ArcDecisionCategory.nomadicTrader,
          status: traderIntel.status,
          progressLabel: purchase.missingShortText,
          action: const ArcDecisionAction(
            label: 'Nomadic Trader',
            intent: ArcCommandActionIntent.nomadicTrader,
          ),
          secondaryAction: traderIntel.hasTradeableNeed
              ? const ArcDecisionAction(
                  label: 'View Trades',
                  routeName: TraderHubScreen.routeName,
                )
              : null,
          sourceSystem: 'Nomadic Trader Intelligence',
          tradeAssisted: traderIntel.hasTradeableNeed,
          score: _score(
            blockerSeverity: 58,
            timeSensitivity: traderIntel.resetLabel == null ? 18 : 58,
            tradeAvailability: traderIntel.hasTradeableNeed ? 66 : 8,
            progressionUnlockValue: purchase.priorityScore,
            missingResourcePressure: _missingPressure(
              purchase.missingResources.length,
            ),
            completionPercentage: traderIntel.completionPercent,
            setupCompleteness: 82,
            confidence: 80,
          ),
        ),
      );
    } else if (traderIntel.trackingKnown && traderIntel.shouldVisit) {
      add(
        _signal(
          id: 'nomadic-review',
          title: 'Review Nomadic Trader',
          summary: traderIntel.summary,
          detail: traderIntel.recommendation,
          category: ArcDecisionCategory.nomadicTrader,
          status: traderIntel.status,
          progressLabel: traderIntel.progressLabel,
          action: const ArcDecisionAction(
            label: 'Nomadic Trader',
            intent: ArcCommandActionIntent.nomadicTrader,
          ),
          sourceSystem: 'Nomadic Trader Intelligence',
          score: _score(
            timeSensitivity: traderIntel.resetLabel == null ? 12 : 40,
            progressionUnlockValue: 36,
            completionPercentage: traderIntel.completionPercent,
            setupCompleteness: 76,
            confidence: 70,
          ),
        ),
      );
    }

    if (tradeActivity.hasActionableTrades) {
      add(
        _signal(
          id: 'trade-activity',
          title: tradeActivity.releasableListingQueues > 0
              ? 'Release Queued Listing'
              : tradeActivity.blockedListingQueues > 0
              ? 'Fix Listing Queue'
              : tradeActivity.hasWatchMatches
              ? 'Review Blueprint Watch Match'
              : tradeActivity.hasHighValueIntelligence
              ? 'Review Smart Trade Match'
              : 'Review Trade Activity',
          summary: tradeActivity.releasableListingQueues > 0
              ? '${tradeActivity.releasableListingQueues} listing queue can release its next public copy.'
              : tradeActivity.blockedListingQueues > 0
              ? '${tradeActivity.blockedListingQueues} listing queue needs attention before it can release.'
              : tradeActivity.hasWatchMatches
              ? '${tradeActivity.matchedBlueprintWatches} blueprint watch has a live matching listing.'
              : tradeActivity.hasHighValueIntelligence
              ? 'Trade Intelligence found ${tradeActivity.bestIntelligenceLabel.toLowerCase()} worth reviewing.'
              : 'Trading has live activity that may change your next move.',
          detail: tradeActivity.releasableListingQueues > 0
              ? 'Open Listing Queues and release the next duplicate only when the current queue-linked listing is closed.'
              : tradeActivity.blockedListingQueues > 0
              ? 'Open Listing Queues to review duplicate availability or pause/cancel the queue.'
              : tradeActivity.hasWatchMatches
              ? 'Open Blueprint Watches to inspect the matched listing before creating another trade.'
              : tradeActivity.hasHighValueIntelligence
              ? 'Open Smart Trade Assist before creating a fresh listing.'
              : 'Clear offers and session updates before creating more listings.',
          category: ArcDecisionCategory.trade,
          status: ArcCommandStatus.ready,
          progressLabel: _tradeProgressLabel(tradeActivity),
          action: tradeActivity.hasQueueAction
              ? const ArcDecisionAction(
                  label: 'Listing Queues',
                  routeName: TradingListingQueuesScreen.routeName,
                )
              : tradeActivity.hasWatchMatches
              ? const ArcDecisionAction(
                  label: 'Blueprint Watches',
                  routeName: TradingBlueprintWatchesScreen.routeName,
                )
              : tradeActivity.hasHighValueIntelligence
              ? const ArcDecisionAction(
                  label: 'Smart Trade',
                  intent: ArcCommandActionIntent.smartTrade,
                )
              : const ArcDecisionAction(
                  label: 'Open Trades',
                  routeName: TraderHubScreen.routeName,
                ),
          secondaryAction: tradeActivity.unreadNotifications > 0
              ? const ArcDecisionAction(
                  label: 'Notifications',
                  routeName: TradingNotificationsScreen.routeName,
                )
              : null,
          sourceSystem: 'Trade Intelligence',
          tradeAssisted: true,
          score: _score(
            readiness: 78,
            tradeAvailability: math.max(
              tradeActivity.hasQueueAction || tradeActivity.hasWatchMatches
                  ? 82
                  : 55,
              tradeActivity.bestIntelligenceConfidence,
            ),
            progressionUnlockValue: tradeActivity.hasQueueAction
                ? 78
                : tradeActivity.hasWatchMatches
                ? 74
                : tradeActivity.hasHighValueIntelligence
                ? 72
                : 44,
            setupCompleteness: 86,
            confidence: tradeActivity.bestIntelligenceConfidence > 0
                ? tradeActivity.bestIntelligenceConfidence
                : 72,
          ),
        ),
      );
    }

    if (!loadoutSummary.ready) {
      add(
        _signal(
          id: 'loadout-incomplete',
          title: 'Finish Favourite Loadout',
          summary: loadoutSummary.missingText,
          detail:
              'This is the fastest way to reduce pre-raid decision fatigue.',
          category: ArcDecisionCategory.loadout,
          status: ArcCommandStatus.warning,
          progressLabel: loadoutSummary.statusLabel,
          action: const ArcDecisionAction(
            label: 'Open Loadout',
            intent: ArcCommandActionIntent.favouriteLoadout,
          ),
          sourceSystem: 'Favourite Loadout',
          score: _score(
            blockerSeverity: 42,
            progressionUnlockValue: 60,
            setupCompleteness: 36,
            confidence: 76,
          ),
        ),
      );
    }

    if (duplicateBlueprints > 0) {
      add(
        _signal(
          id: 'blueprint-duplicates',
          title: 'Trade Duplicate Blueprints',
          summary:
              'You have spare blueprint value that can help fill missing unlocks.',
          detail: 'Review duplicates before farming more blueprint routes.',
          category: ArcDecisionCategory.blueprint,
          status: ArcCommandStatus.ready,
          progressLabel: '$duplicateBlueprints duplicate ready',
          action: const ArcDecisionAction(
            label: 'Smart Trade',
            intent: ArcCommandActionIntent.smartTrade,
          ),
          secondaryAction: const ArcDecisionAction(
            label: 'Create Trade',
            routeName: TradingCreateListingScreen.routeName,
          ),
          sourceSystem: 'Blueprint Tracker',
          tradeAssisted: true,
          score: _score(
            readiness: 78,
            tradeAvailability: 72,
            progressionUnlockValue: 54,
            setupCompleteness: 86,
            confidence: 82,
          ),
        ),
      );
    }

    if (raidIntelligence != null &&
        raidIntelligence.opportunityClusters.isNotEmpty) {
      final clusters = raidIntelligence.opportunityClusters.length;
      final blueprintTargets = raidIntelligence.opportunityClusters.fold<int>(
        0,
        (total, cluster) => total + cluster.blueprintIds.length,
      );
      final routeReady = raidIntelligence.routePlan != null;
      add(
        _signal(
          id: routeReady
              ? 'raid-intelligence-route-ready'
              : 'raid-intelligence-blueprint-run',
          title: routeReady
              ? 'Continue Blueprint Run'
              : 'Generate Blueprint Run',
          summary: raidIntelligence.recommendation,
          detail:
              'Raid Intelligence can route $blueprintTargets evidence-backed Blueprint ${_plural(blueprintTargets, 'target', 'targets')} on ${raidIntelligence.map.displayName}.',
          category: ArcDecisionCategory.raidIntelligence,
          status: routeReady ? ArcCommandStatus.ready : ArcCommandStatus.active,
          progressLabel:
              '$clusters opportunity ${_plural(clusters, 'cluster', 'clusters')}',
          action: ArcDecisionAction(
            label: routeReady ? 'Continue Route' : 'Generate Run',
            routeName: ArcRaidIntelligenceScreen.routeName,
          ),
          secondaryAction: const ArcDecisionAction(
            label: 'Open Blueprints',
            routeName: BlueprintGridScreen.routeName,
          ),
          sourceSystem: 'Raid Intelligence',
          score: _score(
            readiness: routeReady ? 88 : 64,
            multiSystemImpact: favouriteLoadout == null ? 36 : 58,
            progressionUnlockValue: math.min(92, 46 + blueprintTargets * 8),
            missingResourcePressure: _missingPressure(missingBlueprints ?? 0),
            setupCompleteness: 86,
            confidence: math.min(
              94,
              58 +
                  raidIntelligence.opportunityClusters.first.confidence.score ~/
                      2,
            ),
          ),
        ),
      );
    }

    if (!blueprintStateKnown) {
      add(
        _signal(
          id: 'blueprint-setup',
          title: 'Start Blueprint Tracking',
          summary:
              'Mark owned blueprints so the hub can identify blockers and useful trades.',
          detail:
              'Track more resources to improve this recommendation and unlock collection guidance.',
          category: ArcDecisionCategory.blueprint,
          status: ArcCommandStatus.neutral,
          progressLabel: 'Blueprint state not tracked yet',
          action: const ArcDecisionAction(
            label: 'Open Blueprint Tracker',
            routeName: BlueprintGridScreen.routeName,
          ),
          sourceSystem: 'Blueprint Tracker',
          score: _score(
            setupCompleteness: 18,
            progressionUnlockValue: 42,
            confidence: 32,
          ),
        ),
      );
    } else if ((missingBlueprints ?? 0) > 0) {
      final target = prioritizedMissingBlueprints.isEmpty
          ? 'missing blueprint routes'
          : prioritizedMissingBlueprints.first;
      add(
        _signal(
          id: 'blueprint-collection',
          title: 'Complete Blueprint Collection',
          summary: 'Focus the next session on $target.',
          detail:
              'Prioritized missing blueprints should guide loot and trade choices.',
          category: ArcDecisionCategory.blueprint,
          status: ArcCommandStatus.active,
          progressLabel: '$ownedBlueprints/$totalBlueprints owned',
          action: const ArcDecisionAction(
            label: 'Open Blueprint Tracker',
            routeName: BlueprintGridScreen.routeName,
          ),
          sourceSystem: 'Blueprint Tracker',
          score: _score(
            multiSystemImpact: prioritizedMissingBlueprints.isEmpty ? 16 : 38,
            progressionUnlockValue: 52,
            missingResourcePressure: _missingPressure(missingBlueprints ?? 0),
            completionPercentage: totalBlueprints <= 0
                ? 0
                : ((ownedBlueprints / totalBlueprints) * 100).round(),
            setupCompleteness: 86,
            confidence: 78,
          ),
        ),
      );
    }

    if (inProgressOperations > 0 && readyOperations == 0) {
      add(
        _signal(
          id: 'operations-progress',
          title: 'Advance Operations Track',
          summary:
              'Operations progress is live and can feed Reward Vault cosmetics.',
          detail:
              '${operationsState.inventory.length} Vault reward ${_plural(operationsState.inventory.length, 'item', 'items')} unlocked.',
          category: ArcDecisionCategory.rewardVault,
          status: ArcCommandStatus.active,
          progressLabel:
              '${operationsState.completedCount}/$availableOperations complete',
          action: const ArcDecisionAction(
            label: 'Open Operations',
            intent: ArcCommandActionIntent.operations,
          ),
          sourceSystem: 'Operations',
          score: _score(
            progressionUnlockValue: 46,
            completionPercentage: availableOperations <= 0
                ? 0
                : ((operationsState.completedCount / availableOperations) * 100)
                      .round(),
            setupCompleteness: 82,
            confidence: 78,
          ),
        ),
      );
    }

    if (signals.isEmpty) {
      add(
        _fallbackSignal(
          traderIntel.trackingKnown
              ? 'Maintain Weekly Trader Plan'
              : 'Set up Command Trackers',
          traderIntel.trackingKnown
              ? 'Core blockers are quiet. Check trader targets before broad farming.'
              : 'No live stash count available yet. Set up trackers to unlock stronger guidance.',
        ),
      );
    }

    final ranked = _rank(signals);
    final actionableRanked = ranked
        .where(_signalIsCurrentAction)
        .toList(growable: false);
    final primary = ArcDecisionMission.fromSignal(
      actionableRanked.isNotEmpty ? actionableRanked.first : ranked.first,
    );
    final objectives = actionableRanked
        .map(ArcDecisionObjective.fromSignal)
        .toList(growable: false);
    final blockers = actionableRanked
        .where(_isBlocker)
        .map(ArcDecisionBlocker.fromSignal)
        .toList(growable: false);
    final recommendations = _recommendationsFrom(
      actionableRanked,
    ).map(ArcDecisionRecommendation.fromSignal).toList(growable: false);
    final tradeOpportunities = actionableRanked
        .where(
          (signal) =>
              signal.category == ArcDecisionCategory.trade ||
              signal.tradeAssisted,
        )
        .toList(growable: false);
    final resourceActions = actionableRanked
        .where(
          (signal) =>
              signal.category == ArcDecisionCategory.resources ||
              signal.category == ArcDecisionCategory.inventory ||
              signal.category == ArcDecisionCategory.criticalBlocker,
        )
        .toList(growable: false);
    final statuses = _systemStatuses(
      blueprintStateKnown: blueprintStateKnown,
      ownedBlueprints: ownedBlueprints,
      totalBlueprints: totalBlueprints,
      missingBlueprints: missingBlueprints,
      duplicateBlueprints: duplicateBlueprints,
      favouriteLoadout: favouriteLoadout,
      loadoutSummary: loadoutSummary,
      raidIntelligence: raidIntelligence,
      operationsState: operationsState,
      tradeActivity: tradeActivity,
      readyOperations: readyOperations,
      inProgressOperations: inProgressOperations,
      questIntel: questIntel,
      benchIntel: benchIntel,
      traderIntel: traderIntel,
      resourceIntel: resourceIntel,
    );

    return ArcDecisionState(
      primaryMission: primary,
      rankedObjectives: objectives,
      blockers: blockers,
      smartRecommendations: recommendations,
      tradeAssistedOpportunities: tradeOpportunities,
      resourceActions: resourceActions,
      systemStatuses: statuses,
      signals: ranked,
      confidenceLabel: _stateConfidenceLabel(
        actionableRanked.isEmpty ? ranked : actionableRanked,
      ),
      summary: _stateSummary(
        primary,
        actionableRanked.isEmpty ? ranked : actionableRanked,
      ),
    );
  }

  List<ArcDecisionSignal> _recommendationsFrom(List<ArcDecisionSignal> ranked) {
    final recommendations = <ArcDecisionSignal>[];
    final seen = <ArcDecisionCategory>{};
    for (final signal in ranked) {
      if (signal.status == ArcCommandStatus.success) continue;
      if (seen.add(signal.category)) recommendations.add(signal);
      if (recommendations.length >= 4) break;
    }
    if (recommendations.length < 4) {
      recommendations.addAll(
        ranked
            .where(
              (signal) =>
                  !recommendations.contains(signal) &&
                  _signalIsCurrentAction(signal),
            )
            .take(4 - recommendations.length),
      );
    }
    return recommendations.take(4).toList(growable: false);
  }

  List<ArcDecisionSystemStatus> _systemStatuses({
    required bool blueprintStateKnown,
    required int ownedBlueprints,
    required int totalBlueprints,
    required int? missingBlueprints,
    required int duplicateBlueprints,
    required ArcSavedLoadout? favouriteLoadout,
    required _LoadoutDecisionSummary loadoutSummary,
    required ArcRaidIntelligenceState? raidIntelligence,
    required ArcOperationsUserState operationsState,
    required ArcCommandTradeActivity tradeActivity,
    required int readyOperations,
    required int inProgressOperations,
    required ArcQuestIntelligence questIntel,
    required ArcBenchIntelligence benchIntel,
    required ArcNomadicTraderIntelligence traderIntel,
    required ArcResourceIntelligence resourceIntel,
  }) {
    final equippedCosmetics = _equippedCosmeticCount(operationsState);
    final statuses = <ArcDecisionSignal>[
      _systemStatus(
        id: 'status-operations',
        title: 'Operations',
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
        category: ArcDecisionCategory.operations,
        status: readyOperations > 0
            ? ArcCommandStatus.ready
            : inProgressOperations > 0
            ? ArcCommandStatus.active
            : ArcCommandStatus.neutral,
        action: const ArcDecisionAction(
          label: 'Open Operations',
          intent: ArcCommandActionIntent.operations,
        ),
      ),
      _systemStatus(
        id: 'status-resources',
        title: 'Resources',
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
        category: ArcDecisionCategory.resources,
        status: resourceIntel.status,
        action: const ArcDecisionAction(
          label: 'Track Resources',
          routeName: ScrappyGridScreen.routeName,
        ),
      ),
      _systemStatus(
        id: 'status-quest',
        title: 'Quest',
        value: questIntel.trackingKnown
            ? questIntel.readyToComplete
                  ? 'Ready'
                  : '${questIntel.completionPercent}%'
            : 'Set up',
        detail: questIntel.trackingKnown
            ? questIntel.questName
            : 'Open quest tracker',
        category: ArcDecisionCategory.quest,
        status: questIntel.status,
        action: const ArcDecisionAction(
          label: 'Quest Tracker',
          routeName: ScrappyGridScreen.questRouteName,
        ),
      ),
      _systemStatus(
        id: 'status-bench',
        title: 'Bench',
        value: benchIntel.trackingKnown
            ? benchIntel.readyToUpgrade
                  ? 'Ready'
                  : '${benchIntel.completionPercent}%'
            : 'Set up',
        detail: benchIntel.trackingKnown
            ? benchIntel.upgradeLabel
            : 'Open bench tracker',
        category: ArcDecisionCategory.bench,
        status: benchIntel.status,
        action: const ArcDecisionAction(
          label: 'Bench Tracker',
          routeName: ScrappyGridScreen.benchRouteName,
        ),
      ),
      _systemStatus(
        id: 'status-nomadic-trader',
        title: 'Nomadic Trader',
        value: !traderIntel.trackingKnown
            ? 'Set up'
            : traderIntel.canAffordBestPurchase || traderIntel.goalAffordable
            ? 'Ready'
            : '${traderIntel.completionPercent}%',
        detail: traderIntel.trackingKnown
            ? traderIntel.goalName
            : 'Open trader tracker',
        category: ArcDecisionCategory.nomadicTrader,
        status: traderIntel.status,
        action: const ArcDecisionAction(
          label: 'Nomadic Trader',
          intent: ArcCommandActionIntent.nomadicTrader,
        ),
      ),
      _systemStatus(
        id: 'status-blueprints',
        title: 'Blueprints',
        value: blueprintStateKnown
            ? '$ownedBlueprints/$totalBlueprints'
            : 'Set up',
        detail: blueprintStateKnown
            ? '${missingBlueprints ?? 0} missing - $duplicateBlueprints dupes'
            : 'No owned state yet',
        category: ArcDecisionCategory.blueprint,
        status: blueprintStateKnown
            ? ArcCommandStatus.active
            : ArcCommandStatus.neutral,
        action: const ArcDecisionAction(
          label: 'Open Blueprints',
          routeName: BlueprintGridScreen.routeName,
        ),
      ),
      _systemStatus(
        id: 'status-loadout',
        title: 'Favourite Loadout',
        value: loadoutSummary.ready ? 'Ready' : 'Incomplete',
        detail: favouriteLoadout?.name ?? loadoutSummary.statusLabel,
        category: ArcDecisionCategory.loadout,
        status: loadoutSummary.ready
            ? ArcCommandStatus.success
            : ArcCommandStatus.warning,
        action: const ArcDecisionAction(
          label: 'Open Loadout',
          intent: ArcCommandActionIntent.favouriteLoadout,
        ),
      ),
      _systemStatus(
        id: 'status-raid-intelligence',
        title: 'Raid Intelligence',
        value: raidIntelligence == null
            ? 'Set up'
            : raidIntelligence.routePlan != null
            ? 'Route ready'
            : raidIntelligence.opportunityClusters.isEmpty
            ? 'Quiet'
            : '${raidIntelligence.opportunityClusters.length} clusters',
        detail: raidIntelligence == null
            ? 'Generate Blueprint Run'
            : raidIntelligence.recommendation,
        category: ArcDecisionCategory.raidIntelligence,
        status:
            raidIntelligence == null ||
                raidIntelligence.opportunityClusters.isEmpty
            ? ArcCommandStatus.neutral
            : raidIntelligence.routePlan != null
            ? ArcCommandStatus.ready
            : ArcCommandStatus.active,
        action: const ArcDecisionAction(
          label: 'Raid Intelligence',
          routeName: ArcRaidIntelligenceScreen.routeName,
        ),
      ),
      _systemStatus(
        id: 'status-trade-activity',
        title: 'Trade Activity',
        value: tradeActivity.hasActionableTrades
            ? '${tradeActivity.actionableCount} signals'
            : 'Quiet',
        detail: tradeActivity.bestIntelligenceConfidence > 0
            ? '${tradeActivity.bestIntelligenceConfidence}% ${tradeActivity.bestIntelligenceLabel}'
            : '${tradeActivity.activeMyListings} live listings - ${tradeActivity.pendingOffers} offers',
        category: ArcDecisionCategory.trade,
        status: tradeActivity.hasActionableTrades
            ? ArcCommandStatus.ready
            : ArcCommandStatus.neutral,
        action: const ArcDecisionAction(
          label: 'Open Trades',
          routeName: TraderHubScreen.routeName,
        ),
      ),
      _systemStatus(
        id: 'status-reward-vault',
        title: 'Reward Vault',
        value: '${operationsState.inventory.length} items',
        detail: '$equippedCosmetics/4 equipped',
        category: ArcDecisionCategory.rewardVault,
        status: operationsState.inventory.isNotEmpty
            ? ArcCommandStatus.active
            : ArcCommandStatus.neutral,
        action: const ArcDecisionAction(
          label: 'Open Operations',
          intent: ArcCommandActionIntent.operations,
        ),
      ),
      _systemStatus(
        id: 'status-inventory',
        title: 'Inventory',
        value: duplicateBlueprints > 0 ? '$duplicateBlueprints dupes' : 'Clear',
        detail: duplicateBlueprints > 0
            ? 'Blueprint trade value'
            : resourceIntel.inventory.pressureDetail,
        category: ArcDecisionCategory.inventory,
        status: duplicateBlueprints > 0
            ? ArcCommandStatus.ready
            : resourceIntel.inventory.status,
        action: const ArcDecisionAction(
          label: 'Inventory',
          routeName: ScrappyGridScreen.routeName,
        ),
      ),
    ];
    return statuses
        .map(ArcDecisionSystemStatus.fromSignal)
        .toList(growable: false);
  }

  ArcDecisionSignal _systemStatus({
    required String id,
    required String title,
    required String value,
    required String detail,
    required ArcDecisionCategory category,
    required ArcCommandStatus status,
    required ArcDecisionAction action,
  }) {
    return _signal(
      id: id,
      title: title,
      summary: detail,
      detail: detail,
      category: category,
      status: status,
      progressLabel: value,
      action: action,
      sourceSystem: 'Decision System Status',
      score: _score(
        readiness: status == ArcCommandStatus.ready ? 70 : 20,
        blockerSeverity: status == ArcCommandStatus.warning ? 45 : 0,
        progressionUnlockValue: status == ArcCommandStatus.active ? 42 : 22,
        setupCompleteness: status == ArcCommandStatus.neutral ? 18 : 74,
        confidence: 78,
      ),
    );
  }

  ArcDecisionSignal _signal({
    required String id,
    required String title,
    required String summary,
    required String detail,
    required ArcDecisionCategory category,
    required ArcCommandStatus status,
    required String progressLabel,
    required ArcDecisionAction action,
    required String sourceSystem,
    required ArcDecisionScore score,
    ArcDecisionAction? secondaryAction,
    bool tradeAssisted = false,
  }) {
    return ArcDecisionSignal(
      id: id,
      title: title,
      summary: summary,
      detail: detail,
      category: category,
      status: status,
      progressLabel: progressLabel,
      action: action,
      secondaryAction: secondaryAction,
      sourceSystem: sourceSystem,
      score: score,
      tradeAssisted: tradeAssisted,
    );
  }

  ArcDecisionSignal _fallbackSignal(String title, String summary) {
    return _signal(
      id: 'fallback',
      title: title,
      summary: summary,
      detail: summary,
      category: ArcDecisionCategory.optional,
      status: ArcCommandStatus.success,
      progressLabel: 'Core trackers ready',
      action: const ArcDecisionAction(
        label: 'Open Nomadic Trader',
        intent: ArcCommandActionIntent.nomadicTrader,
      ),
      sourceSystem: 'Decision Engine',
      score: _score(
        readiness: 40,
        progressionUnlockValue: 34,
        setupCompleteness: 60,
        confidence: 58,
      ),
    );
  }

  ArcDecisionScore _score({
    int readiness = 0,
    int blockerSeverity = 0,
    int multiSystemImpact = 0,
    int timeSensitivity = 0,
    int tradeAvailability = 0,
    int progressionUnlockValue = 0,
    int missingResourcePressure = 0,
    int completionPercentage = 0,
    int setupCompleteness = 0,
    int confidence = 60,
  }) {
    return ArcDecisionScore(
      readiness: readiness.clamp(0, 100),
      blockerSeverity: blockerSeverity.clamp(0, 100),
      multiSystemImpact: multiSystemImpact.clamp(0, 100),
      timeSensitivity: timeSensitivity.clamp(0, 100),
      tradeAvailability: tradeAvailability.clamp(0, 100),
      progressionUnlockValue: progressionUnlockValue.clamp(0, 100),
      missingResourcePressure: missingResourcePressure.clamp(0, 100),
      completionPercentage: completionPercentage.clamp(0, 100),
      setupCompleteness: setupCompleteness.clamp(0, 100),
      confidence: confidence.clamp(0, 100),
    );
  }

  List<ArcDecisionSignal> _rank(List<ArcDecisionSignal> signals) {
    final ranked = signals.toList(growable: false)
      ..sort((left, right) {
        final score = _rankWeight(right).compareTo(_rankWeight(left));
        if (score != 0) return score;
        final confidence = right.confidence.compareTo(left.confidence);
        if (confidence != 0) return confidence;
        return left.title.compareTo(right.title);
      });
    return ranked;
  }

  int _rankWeight(ArcDecisionSignal signal) {
    return signal.priority +
        _statusBoost(signal.status) +
        _categoryBoost(signal.category);
  }

  int _statusBoost(ArcCommandStatus status) {
    return switch (status) {
      ArcCommandStatus.critical => 22,
      ArcCommandStatus.ready => 16,
      ArcCommandStatus.warning => 12,
      ArcCommandStatus.active => 6,
      ArcCommandStatus.neutral => 0,
      ArcCommandStatus.success => -4,
    };
  }

  int _categoryBoost(ArcDecisionCategory category) {
    return switch (category) {
      ArcDecisionCategory.criticalBlocker => 18,
      ArcDecisionCategory.bench => 12,
      ArcDecisionCategory.quest => 10,
      ArcDecisionCategory.trade => 8,
      ArcDecisionCategory.resources => 8,
      ArcDecisionCategory.inventory => 4,
      ArcDecisionCategory.loadout => 5,
      ArcDecisionCategory.blueprint => 3,
      ArcDecisionCategory.raidIntelligence => 9,
      ArcDecisionCategory.nomadicTrader => 7,
      ArcDecisionCategory.operations => 14,
      ArcDecisionCategory.rewardVault => 6,
      ArcDecisionCategory.community => 1,
      ArcDecisionCategory.optional => -10,
    };
  }

  bool _isBlocker(ArcDecisionSignal signal) {
    if (signal.category == ArcDecisionCategory.optional) return false;
    return signal.status == ArcCommandStatus.critical ||
        signal.status == ArcCommandStatus.warning ||
        signal.score.blockerSeverity >= 45 ||
        signal.score.missingResourcePressure >= 45 ||
        signal.status == ArcCommandStatus.ready;
  }

  bool _hasTrackedIncompleteProgress({
    required bool trackingKnown,
    required ArcCommandStatus status,
    required int completionPercent,
  }) {
    if (!trackingKnown || status == ArcCommandStatus.success) return false;
    return completionPercent < 100;
  }

  bool _signalIsCurrentAction(ArcDecisionSignal signal) {
    if (signal.category == ArcDecisionCategory.optional) return false;
    if (signal.status == ArcCommandStatus.success) return false;
    if (signal.score.completionPercentage >= 100 &&
        signal.status != ArcCommandStatus.ready &&
        signal.status != ArcCommandStatus.critical) {
      return false;
    }

    final text =
        '${signal.id} ${signal.title} ${signal.summary} '
        '${signal.detail} ${signal.progressLabel} ${signal.sourceSystem}';
    return !_looksStaleOrComplete(text);
  }

  bool _looksStaleOrComplete(String text) {
    final normalized = text.toLowerCase();
    if (RegExp(r'\b100\s*%').hasMatch(normalized)) return true;
    if (RegExp(r'\b100\s+percent\b').hasMatch(normalized)) return true;
    if (RegExp(r'\bclaimed\b').hasMatch(normalized)) return true;
    if (normalized.contains('already complete') ||
        normalized.contains('already completed') ||
        normalized.contains('reward claimed') ||
        normalized.contains('all tracked') && normalized.contains('complete') ||
        normalized.contains('completed for this season') ||
        normalized.contains('previous expedition') ||
        normalized.contains('previous season') ||
        normalized.contains('past expedition') ||
        normalized.contains('stale objective')) {
      return true;
    }
    return false;
  }

  String _tradeProgressLabel(ArcCommandTradeActivity tradeActivity) {
    final activeSessionBacklog = math.max(
      0,
      tradeActivity.activeSessions - tradeActivity.readySessions,
    );
    final signals = <String>[
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
      if (tradeActivity.matchedBlueprintWatches > 0)
        '${tradeActivity.matchedBlueprintWatches} watch ${_plural(tradeActivity.matchedBlueprintWatches, 'match', 'matches')}',
      if (tradeActivity.releasableListingQueues > 0)
        '${tradeActivity.releasableListingQueues} queue ${_plural(tradeActivity.releasableListingQueues, 'release', 'releases')}',
      if (tradeActivity.blockedListingQueues > 0)
        '${tradeActivity.blockedListingQueues} blocked ${_plural(tradeActivity.blockedListingQueues, 'queue', 'queues')}',
    ];
    return signals.isEmpty ? 'Trade signal ready' : signals.join(' - ');
  }

  int _missingPressure(int missingCount) {
    return math.min(100, math.max(0, missingCount) * 12);
  }

  String _stateConfidenceLabel(List<ArcDecisionSignal> ranked) {
    if (ranked.isEmpty) return 'Low confidence';
    final average =
        ranked
            .take(5)
            .fold<int>(0, (total, signal) => total + signal.confidence) /
        math.min(5, ranked.length);
    if (average >= 82) return 'High confidence';
    if (average >= 56) return 'Medium confidence';
    return 'Low confidence';
  }

  String _stateSummary(
    ArcDecisionMission primary,
    List<ArcDecisionSignal> ranked,
  ) {
    final systems = ranked
        .take(4)
        .map((signal) => signal.category.label)
        .toSet()
        .join(', ');
    return 'Primary mission is ${primary.title}. Ranked from ${systems.isEmpty ? 'available systems' : systems}.';
  }

  _LoadoutDecisionSummary _loadoutSummary(ArcSavedLoadout? loadout) {
    if (loadout == null) {
      return const _LoadoutDecisionSummary(
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
    final kitParts = <String>[
      if (loadout.primaryWeapon.trim().isNotEmpty) loadout.primaryWeapon.trim(),
      if (loadout.secondaryWeapon.trim().isNotEmpty)
        loadout.secondaryWeapon.trim(),
      if (loadout.augment.trim().isNotEmpty) loadout.augment.trim(),
    ];

    return _LoadoutDecisionSummary(
      ready: missingSlots.isEmpty,
      statusLabel: missingSlots.isEmpty
          ? 'Ready'
          : 'Needs ${missingSlots.length}',
      detail: kitParts.isEmpty ? loadout.name : kitParts.join(' / '),
      missingSlots: missingSlots,
    );
  }

  int _equippedCosmeticCount(ArcOperationsUserState operationsState) {
    final equipped = operationsState.equippedCosmetics;
    return [
      equipped.badgeId,
      equipped.titleId,
      equipped.profileFrameId,
      equipped.profileBannerId,
    ].where((id) => id != null && id.trim().isNotEmpty).length;
  }

  String _plural(int count, String singular, String plural) {
    return count == 1 ? singular : plural;
  }
}

class _LoadoutDecisionSummary {
  const _LoadoutDecisionSummary({
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
