import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_upgrade_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_operations_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
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
      ),
      alerts: _alerts(
        blueprintStateKnown: blueprintStateKnown,
        duplicateBlueprints: duplicateBlueprints,
        missingBlueprints: missingBlueprints,
        loadoutSummary: loadoutSummary,
        tradeActivity: tradeActivity,
        readyOperations: readyOperations,
      ),
      recommendations: _recommendations(
        blueprintStateKnown: blueprintStateKnown,
        missingBlueprints: missingBlueprints,
        duplicateBlueprints: duplicateBlueprints,
        loadoutSummary: loadoutSummary,
        tradeActivity: tradeActivity,
        readyOperations: readyOperations,
      ),
      checklist: _checklist(
        loadoutReady: loadoutSummary.ready,
        tradeActivity: tradeActivity,
        readyOperations: readyOperations,
      ),
      resources: _resources(),
      tradeSummary: _tradeSummary(
        prioritizedMissing: prioritizedMissing,
        duplicateBlueprints: duplicateBlueprints,
        tradeActivity: tradeActivity,
      ),
      blueprintSummary: _blueprintSummary(
        blueprintStateKnown: blueprintStateKnown,
        ownedBlueprints: ownedBlueprints,
        totalBlueprints: totalBlueprints,
        missingBlueprints: missingBlueprints,
        duplicateBlueprints: duplicateBlueprints,
        recentBlueprint: recentBlueprint,
      ),
      questSummary: _questSummary(),
      benchSummary: _benchSummary(),
      operationsSummary: _operationsSummary(
        operationsState: operationsState,
        readyOperations: readyOperations,
        inProgressOperations: inProgressOperations,
        availableOperations: availableOperations,
      ),
      weeklyTraderSummary: _weeklyTraderSummary(),
      communitySummary: _communitySummary(tradeActivity),
      statisticsSummary: _statisticsSummary(
        blueprintStateKnown: blueprintStateKnown,
        ownedBlueprints: ownedBlueprints,
        duplicateBlueprints: duplicateBlueprints,
        tradeActivity: tradeActivity,
        operationsState: operationsState,
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
          'Nomadic trader requirements are ready for the next live-data pass.',
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
      const ArcCommandSnapshotMetric(
        label: 'Bench Level',
        value: 'Track',
        detail: 'Bench requirements ready',
        status: ArcCommandStatus.neutral,
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
  }) {
    return [
      ArcCommandObjective(
        title: readyOperations > 0
            ? 'Claim Operation Rewards'
            : 'Advance Operations Progress',
        reason: readyOperations > 0
            ? 'Reward Vault unlocks are ready to claim from completed Operations.'
            : 'Operations progress feeds Reward Vault cosmetics and profile identity.',
        statusLabel: readyOperations > 0
            ? 'Reward ready'
            : inProgressOperations > 0
            ? 'In progress'
            : 'Available',
        progressText:
            '${operationsState.completedCount}/$availableOperations completed - ${operationsState.inventory.length} rewards owned',
        status: readyOperations > 0
            ? ArcCommandStatus.ready
            : inProgressOperations > 0
            ? ArcCommandStatus.active
            : ArcCommandStatus.neutral,
        action: const ArcCommandAction(
          label: 'Open Operations',
          intent: ArcCommandActionIntent.operations,
        ),
      ),
      ArcCommandObjective(
        title: 'Complete Favourite Loadout',
        reason: loadoutSummary.ready
            ? 'Your saved loadout is ready for review before raid planning.'
            : loadoutSummary.missingText,
        statusLabel: loadoutSummary.statusLabel,
        progressText: loadoutSummary.ready
            ? loadoutSummary.detail
            : 'Missing: ${loadoutSummary.missingShortText}',
        status: loadoutSummary.ready
            ? ArcCommandStatus.success
            : ArcCommandStatus.warning,
        action: const ArcCommandAction(
          label: 'Open Loadout',
          intent: ArcCommandActionIntent.favouriteLoadout,
        ),
      ),
      ArcCommandObjective(
        title: 'Review Trade Centre',
        reason: tradeActivity.hasActionableTrades
            ? 'Listings, offers, sessions or notifications need attention.'
            : 'No live trade action is waiting right now.',
        statusLabel: tradeActivity.hasActionableTrades ? 'Actionable' : 'Quiet',
        progressText:
            '${tradeActivity.activeMyListings} live listings - ${tradeActivity.pendingOffers} pending offers - ${tradeActivity.activeSessions} sessions',
        status: tradeActivity.hasActionableTrades
            ? ArcCommandStatus.ready
            : ArcCommandStatus.neutral,
        action: const ArcCommandAction(
          label: 'Open Trades',
          routeName: TraderHubScreen.routeName,
        ),
      ),
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
      ArcCommandObjective(
        title: 'Review Duplicate Blueprints',
        reason: duplicateBlueprints > 0
            ? 'Duplicates can become trade leverage.'
            : 'No duplicate blueprint value is currently tracked.',
        statusLabel: duplicateBlueprints > 0 ? 'Trade ready' : 'Clear',
        progressText: '$duplicateBlueprints duplicate tracked',
        status: duplicateBlueprints > 0
            ? ArcCommandStatus.ready
            : ArcCommandStatus.neutral,
        action: const ArcCommandAction(
          label: 'Smart Trade',
          intent: ArcCommandActionIntent.smartTrade,
        ),
      ),
      ArcCommandObjective(
        title: 'Plan Next Trade',
        reason: (missingBlueprints ?? 0) > 0
            ? 'Missing blueprints can be routed through trade before farming.'
            : 'Trade tools are ready when a new target appears.',
        statusLabel: 'Optional',
        progressText: (missingBlueprints ?? 0) > 0
            ? '${missingBlueprints ?? 0} possible needs'
            : 'No tracked blockers',
        status: ArcCommandStatus.neutral,
        action: const ArcCommandAction(
          label: 'View Trades',
          routeName: TraderHubScreen.routeName,
        ),
      ),
    ];
  }

  static List<ArcCommandAlert> _alerts({
    required bool blueprintStateKnown,
    required int duplicateBlueprints,
    required int? missingBlueprints,
    required _ArcLoadoutCommandSummary loadoutSummary,
    required ArcCommandTradeActivity tradeActivity,
    required int readyOperations,
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
      const ArcCommandChecklistItem(
        id: 'nomadic-trader',
        label: 'Check Nomadic Trader',
        reason: 'Review trader goals before spending resources.',
        action: ArcCommandAction(
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
      const ArcCommandChecklistItem(
        id: 'hand-in-quest',
        label: 'Hand In Quest',
        reason: 'Quest live data is pending, but the tracker is ready.',
        action: ArcCommandAction(
          label: 'Quest Tracker',
          routeName: ScrappyGridScreen.questRouteName,
        ),
      ),
      const ArcCommandChecklistItem(
        id: 'upgrade-bench',
        label: 'Upgrade Bench',
        reason: 'Check requirements before recycling or trading materials.',
        action: ArcCommandAction(
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

  static List<ArcCommandResourceStatus> _resources() {
    return const [
      ArcCommandResourceStatus(
        name: 'Queen Reactor',
        ownedLabel: 'Not tracked yet',
        requiredLabel: 'Track resources',
        status: ArcCommandStatus.neutral,
      ),
      ArcCommandResourceStatus(
        name: 'Matriarch Parts',
        ownedLabel: 'Not tracked yet',
        requiredLabel: 'Track resources',
        status: ArcCommandStatus.neutral,
      ),
      ArcCommandResourceStatus(
        name: 'Titanium',
        ownedLabel: 'Not tracked yet',
        requiredLabel: 'Track resources',
        status: ArcCommandStatus.neutral,
      ),
      ArcCommandResourceStatus(
        name: 'Circuit Boards',
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
  }) {
    final lookingFor = <String>[
      if (tradeActivity.pendingOffers > 0)
        '${tradeActivity.pendingOffers} pending ${_plural(tradeActivity.pendingOffers, 'offer', 'offers')}',
      if (tradeActivity.activeSessions > 0)
        '${tradeActivity.activeSessions} active trade ${_plural(tradeActivity.activeSessions, 'session', 'sessions')}',
      if (tradeActivity.bestIntelligenceConfidence > 0)
        '${tradeActivity.bestIntelligenceConfidence}% ${tradeActivity.bestIntelligenceLabel}',
      if (prioritizedMissing.isNotEmpty) ...prioritizedMissing.take(3),
      if (prioritizedMissing.isEmpty && tradeActivity.pendingOffers == 0)
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

  static ArcCommandSummaryPanel _questSummary() {
    return const ArcCommandSummaryPanel(
      title: 'Quest Progress',
      statusLabel: 'Setup available',
      body: 'Quest item ownership is not live in Command Centre yet.',
      details: [
        'Active quest: Not tracked yet',
        'Required items: Open Quest Tracker',
        'Owned/missing: Coming online',
      ],
      status: ArcCommandStatus.neutral,
      action: ArcCommandAction(
        label: 'Open Quest Tracker',
        routeName: ScrappyGridScreen.questRouteName,
      ),
    );
  }

  static ArcCommandSummaryPanel _benchSummary() {
    final first = ArcBenchUpgradeSeedData.requirements.first;
    return ArcCommandSummaryPanel(
      title: 'Bench Progress',
      statusLabel: 'Requirements ready',
      body:
          'Bench requirements are available; stash ownership wiring is pending.',
      details: [
        'Current level: Not tracked yet',
        'Next sample: ${first.upgradeLabel}',
        '${first.quantity}x ${first.itemName}',
      ],
      status: ArcCommandStatus.neutral,
      action: const ArcCommandAction(
        label: 'Open Bench Tracker',
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

  static ArcCommandSummaryPanel _weeklyTraderSummary() {
    return const ArcCommandSummaryPanel(
      title: 'Weekly Nomadic Trader',
      statusLabel: 'Coming online',
      body:
          'Weekly stock and reset timing are ready for live-data integration.',
      details: [
        'Current stock: Placeholder',
        'Required resources: Not tracked yet',
        'Reset reminder: Notifications deferred',
      ],
      status: ArcCommandStatus.neutral,
      action: ArcCommandAction(
        label: 'Open Nomadic Trader',
        intent: ArcCommandActionIntent.nomadicTrader,
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
