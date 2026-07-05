import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_upgrade_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_market_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_create_listing_screen.dart';

class ArcCommandCentreEngine {
  const ArcCommandCentreEngine._();

  static ArcCommandCentreState build({
    required Map<String, ArcBlueprintState> blueprintStates,
    required List<ArcSavedLoadout> savedLoadouts,
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
    final loadoutReady = _loadoutReady(loadout);

    return ArcCommandCentreState(
      priority: _priority(
        blueprintStateKnown: blueprintStateKnown,
        ownedBlueprints: ownedBlueprints,
        totalBlueprints: totalBlueprints,
        missingBlueprints: missingBlueprints,
        duplicateBlueprints: duplicateBlueprints,
        prioritizedMissing: prioritizedMissing,
        loadoutReady: loadoutReady,
      ),
      snapshots: _snapshots(
        blueprintStateKnown: blueprintStateKnown,
        ownedBlueprints: ownedBlueprints,
        totalBlueprints: totalBlueprints,
        missingBlueprints: missingBlueprints,
        duplicateBlueprints: duplicateBlueprints,
        loadout: loadout,
        loadoutReady: loadoutReady,
      ),
      objectives: _objectives(
        blueprintStateKnown: blueprintStateKnown,
        ownedBlueprints: ownedBlueprints,
        totalBlueprints: totalBlueprints,
        missingBlueprints: missingBlueprints,
        duplicateBlueprints: duplicateBlueprints,
        loadoutReady: loadoutReady,
      ),
      alerts: _alerts(
        blueprintStateKnown: blueprintStateKnown,
        duplicateBlueprints: duplicateBlueprints,
        missingBlueprints: missingBlueprints,
        loadoutReady: loadoutReady,
      ),
      recommendations: _recommendations(
        blueprintStateKnown: blueprintStateKnown,
        duplicateBlueprints: duplicateBlueprints,
        loadoutReady: loadoutReady,
      ),
      checklist: _checklist(loadoutReady: loadoutReady),
      resources: _resources(),
      tradeSummary: _tradeSummary(
        prioritizedMissing: prioritizedMissing,
        duplicateBlueprints: duplicateBlueprints,
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
      weeklyTraderSummary: _weeklyTraderSummary(),
      communitySummary: _communitySummary(),
      statisticsSummary: _statisticsSummary(
        blueprintStateKnown: blueprintStateKnown,
        ownedBlueprints: ownedBlueprints,
        duplicateBlueprints: duplicateBlueprints,
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
    required bool loadoutReady,
  }) {
    if (!loadoutReady) {
      return const ArcCommandPriority(
        title: 'Finish Favourite Loadout',
        explanation:
            'Lock in a primary, secondary, augment and field kit before planning raids.',
        progressLabel: 'Loadout setup incomplete',
        statusTag: 'High impact',
        detail: 'This is the fastest way to reduce pre-raid decision fatigue.',
        status: ArcCommandStatus.warning,
        primaryAction: ArcCommandAction(
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
    required bool loadoutReady,
  }) {
    return [
      const ArcCommandSnapshotMetric(
        label: 'Player Level',
        value: 'Not tracked',
        detail: 'Profile sync pending',
        status: ArcCommandStatus.neutral,
      ),
      const ArcCommandSnapshotMetric(
        label: 'Active Quest',
        value: 'Set up',
        detail: 'Open Quest Tracker',
        status: ArcCommandStatus.warning,
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
        value: loadoutReady ? 'Ready' : 'Incomplete',
        detail: loadout?.name ?? 'No saved loadout',
        status: loadoutReady
            ? ArcCommandStatus.success
            : ArcCommandStatus.warning,
      ),
      const ArcCommandSnapshotMetric(
        label: 'Trade Activity',
        value: 'No active trades',
        detail: 'Trade sync coming online',
        status: ArcCommandStatus.neutral,
      ),
      const ArcCommandSnapshotMetric(
        label: 'Wipe Progress',
        value: 'Coming online',
        detail: 'Season state pending',
        status: ArcCommandStatus.neutral,
      ),
      const ArcCommandSnapshotMetric(
        label: 'Inventory',
        value: 'Track resources',
        detail: 'Stash totals pending',
        status: ArcCommandStatus.neutral,
      ),
    ];
  }

  static List<ArcCommandObjective> _objectives({
    required bool blueprintStateKnown,
    required int ownedBlueprints,
    required int totalBlueprints,
    required int? missingBlueprints,
    required int duplicateBlueprints,
    required bool loadoutReady,
  }) {
    return [
      ArcCommandObjective(
        title: 'Complete Favourite Loadout',
        reason: loadoutReady
            ? 'Your saved loadout is ready for review before raid planning.'
            : 'A complete loadout lets the hub recommend trades and resource targets.',
        statusLabel: loadoutReady ? 'Ready' : 'Needs setup',
        progressText: loadoutReady ? 'Saved loadout found' : 'Save one loadout',
        status: loadoutReady
            ? ArcCommandStatus.success
            : ArcCommandStatus.warning,
        action: const ArcCommandAction(
          label: 'Open Loadout',
          intent: ArcCommandActionIntent.favouriteLoadout,
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
      const ArcCommandObjective(
        title: 'Track Bench Upgrade',
        reason: 'Bench requirements help avoid wasting scarce materials.',
        statusLabel: 'Resource check',
        progressText: 'Live stash counts pending',
        status: ArcCommandStatus.neutral,
        action: ArcCommandAction(
          label: 'Open Bench',
          routeName: ScrappyGridScreen.benchRouteName,
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
    required bool loadoutReady,
  }) {
    final alerts = <ArcCommandAlert>[];
    if (!loadoutReady) {
      alerts.add(
        const ArcCommandAlert(
          title: 'Loadout incomplete',
          body:
              'Save a Favourite Loadout before relying on raid prep guidance.',
          statusLabel: 'Action needed',
          status: ArcCommandStatus.warning,
          action: ArcCommandAction(
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
    alerts.add(
      const ArcCommandAlert(
        title: 'Resource counts pending',
        body:
            'Bench, quest and stash math will activate after live inventory wiring.',
        statusLabel: 'Coming online',
        status: ArcCommandStatus.neutral,
        action: ArcCommandAction(
          label: 'Track Resources',
          routeName: ScrappyGridScreen.routeName,
        ),
      ),
    );
    return alerts;
  }

  static List<ArcCommandRecommendation> _recommendations({
    required bool blueprintStateKnown,
    required int duplicateBlueprints,
    required bool loadoutReady,
  }) {
    return [
      ArcCommandRecommendation(
        title: loadoutReady
            ? 'Review your Favourite Loadout before raids.'
            : 'Finish your Favourite Loadout before entering raids.',
        body:
            'The loadout is the anchor for equipment, attachments and trade asks.',
        action: const ArcCommandAction(
          label: 'Open Loadout',
          intent: ArcCommandActionIntent.favouriteLoadout,
        ),
      ),
      ArcCommandRecommendation(
        title: duplicateBlueprints > 0
            ? 'Review duplicate blueprints for potential trades.'
            : 'Keep duplicate blueprint tracking current.',
        body: 'Trade value is easiest to act on when duplicates are visible.',
        action: const ArcCommandAction(
          label: 'Smart Trade',
          intent: ArcCommandActionIntent.smartTrade,
        ),
      ),
      const ArcCommandRecommendation(
        title: 'Check weekly trader before farming resources.',
        body: 'Trader goals can change which resources are worth keeping.',
        action: ArcCommandAction(
          label: 'Nomadic Trader',
          intent: ArcCommandActionIntent.nomadicTrader,
        ),
      ),
      ArcCommandRecommendation(
        title: blueprintStateKnown
            ? 'Complete active objectives before adding more trackers.'
            : 'Start with blueprint tracking for sharper recommendations.',
        body: 'A smaller tracked queue keeps the next step obvious.',
        action: const ArcCommandAction(
          label: 'Open Blueprints',
          routeName: BlueprintGridScreen.routeName,
        ),
      ),
    ];
  }

  static List<ArcCommandChecklistItem> _checklist({
    required bool loadoutReady,
  }) {
    return [
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
      const ArcCommandChecklistItem(
        id: 'review-trades',
        label: 'Review Trades',
        reason: 'Check listings, offers and duplicate value.',
        action: ArcCommandAction(
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
  }) {
    return ArcCommandTradeSummary(
      lookingFor: prioritizedMissing.isEmpty
          ? const [
              'Blueprint needs not tracked',
              'Resources not tracked',
              'Attachments not tracked',
            ]
          : prioritizedMissing.take(3).toList(growable: false),
      offering: [
        duplicateBlueprints > 0
            ? '$duplicateBlueprints duplicate blueprints'
            : 'No duplicate blueprints tracked',
        'Resources not tracked yet',
        'Weapons not tracked yet',
      ],
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

  static ArcCommandSummaryPanel _communitySummary() {
    return const ArcCommandSummaryPanel(
      title: 'Community Activity',
      statusLabel: 'Safe empty state',
      body:
          'Community activity will surface matching demand once trade data is wired.',
      details: [
        'Similar item demand: Coming online',
        'Potential trade matches: No active data',
        'Live trading sessions: Open Trader Hub',
      ],
      status: ArcCommandStatus.neutral,
      action: ArcCommandAction(
        label: 'Open Intel',
        routeName: ArcMarketIntelligenceScreen.routeName,
      ),
    );
  }

  static ArcCommandSummaryPanel _statisticsSummary({
    required bool blueprintStateKnown,
    required int ownedBlueprints,
    required int duplicateBlueprints,
  }) {
    return ArcCommandSummaryPanel(
      title: 'Statistics',
      statusLabel: 'Phase 1 baseline',
      body: 'Command Centre is collecting safe summary signals first.',
      details: [
        'Trades completed: No data yet',
        blueprintStateKnown
            ? 'Blueprints collected: $ownedBlueprints'
            : 'Blueprints collected: Not tracked yet',
        'Resources traded: Coming online',
        'Inventory space saved: $duplicateBlueprints duplicate signals',
        'Estimated time saved: Coming online',
      ],
      status: ArcCommandStatus.neutral,
      action: const ArcCommandAction(
        label: 'Open Tool Deck',
        intent: ArcCommandActionIntent.toolDeck,
      ),
    );
  }

  static bool _loadoutReady(ArcSavedLoadout? loadout) {
    if (loadout == null) return false;
    return loadout.augment.trim().isNotEmpty &&
        loadout.primaryWeapon.trim().isNotEmpty &&
        loadout.secondaryWeapon.trim().isNotEmpty &&
        (loadout.equipment.isNotEmpty || loadout.consumables.isNotEmpty);
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
