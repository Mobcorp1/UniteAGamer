import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_bench_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_nomadic_trader_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_quest_intelligence_models.dart';

class ArcNomadicTraderIntelligenceEngine {
  const ArcNomadicTraderIntelligenceEngine();

  ArcNomadicTraderIntelligence build({
    required ArcNomadicTraderTrackerSnapshot tracker,
    ArcQuestIntelligence? questIntel,
    ArcBenchIntelligence? benchIntel,
    ArcSavedLoadout? favouriteLoadout,
    Map<String, ArcBlueprintState> blueprintStates =
        const <String, ArcBlueprintState>{},
    ArcCommandTradeActivity tradeActivity = ArcCommandTradeActivity.empty,
    int duplicateBlueprints = 0,
  }) {
    if (!tracker.trackingKnown) {
      return const ArcNomadicTraderIntelligence(
        trackingKnown: false,
        goalName: 'Nomadic Trader',
        statusLabel: 'Set up',
        summary:
            'Nomadic Trader goals and purchase requirements are not tracked yet.',
        recommendation:
            'Open Nomadic Trader and add the current purchase target before spending resources.',
        actionLabel: 'Open Trader',
        status: ArcCommandStatus.neutral,
        completionPercent: 0,
        targetValue: 0,
        currentValue: 0,
        remainingValue: 0,
        trackedPurchaseCount: 0,
        completedPurchaseCount: 0,
        affordablePurchaseCount: 0,
        nearlyAffordablePurchaseCount: 0,
        tradeNeedLabels: <String>[],
        topPurchases: <ArcNomadicTraderPurchaseIntelligence>[],
      );
    }

    final rankedPurchases =
        tracker.purchases
            .map(
              (purchase) => _scorePurchase(
                purchase: purchase,
                tracker: tracker,
                questIntel: questIntel,
                benchIntel: benchIntel,
                favouriteLoadout: favouriteLoadout,
                blueprintStates: blueprintStates,
                tradeActivity: tradeActivity,
                duplicateBlueprints: duplicateBlueprints,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final scoreCompare = b.priorityScore.compareTo(a.priorityScore);
            if (scoreCompare != 0) return scoreCompare;
            final affordCompare = b.canAfford.toString().compareTo(
              a.canAfford.toString(),
            );
            if (affordCompare != 0) return affordCompare;
            return a.purchase.name.compareTo(b.purchase.name);
          });

    final best = rankedPurchases.isEmpty ? null : rankedPurchases.first;
    final affordable = rankedPurchases
        .where((item) => item.canAfford && !item.alreadyPurchased)
        .length;
    final nearlyAffordable = rankedPurchases
        .where(
          (item) =>
              item.nearlyAffords && !item.canAfford && !item.alreadyPurchased,
        )
        .length;
    final tradeNeeds = _tradeNeedLabels(
      best: best,
      tracker: tracker,
      duplicateBlueprints: duplicateBlueprints,
      tradeActivity: tradeActivity,
    );

    if (best != null && !best.alreadyPurchased) {
      final status = best.canAfford
          ? ArcCommandStatus.ready
          : best.hasProgressImpact
          ? ArcCommandStatus.warning
          : ArcCommandStatus.active;
      return ArcNomadicTraderIntelligence(
        trackingKnown: true,
        goalName: tracker.goalName,
        statusLabel: best.canAfford
            ? 'Buy now'
            : best.nearlyAffords
            ? 'Nearly affordable'
            : best.priorityLabel,
        summary: best.canAfford
            ? '${best.purchase.name} is ready to buy or mark purchased.'
            : '${best.purchase.name} is the highest-value tracked trader target.',
        recommendation: best.reason,
        actionLabel: best.recommendedAction,
        status: status,
        completionPercent: tracker.completionPercent,
        targetValue: tracker.targetValue,
        currentValue: tracker.currentValue,
        remainingValue: tracker.remainingValue,
        trackedPurchaseCount: tracker.purchases.length,
        completedPurchaseCount: tracker.completedPurchaseCount,
        affordablePurchaseCount: affordable,
        nearlyAffordablePurchaseCount: nearlyAffordable,
        tradeNeedLabels: tradeNeeds,
        topPurchases: rankedPurchases.take(4).toList(growable: false),
        bestPurchase: best,
      );
    }

    final goalAffordable = tracker.goalAffordable;
    return ArcNomadicTraderIntelligence(
      trackingKnown: true,
      goalName: tracker.goalName,
      statusLabel: goalAffordable
          ? 'Goal ready'
          : tracker.hasPurchaseTracking
          ? 'Tracked'
          : 'Tracking',
      summary: tracker.hasPurchaseTracking
          ? '${tracker.completedPurchaseCount}/${tracker.purchases.length} tracked trader purchases are complete.'
          : 'Trader value is ${tracker.completionPercent}% ready for ${tracker.goalName}.',
      recommendation: goalAffordable
          ? 'Visit the Nomadic Trader before spending these resources elsewhere.'
          : tracker.hasPurchaseTracking
          ? 'Add requirement details to any purchase that still needs resources.'
          : 'Add the current stock item as a tracked purchase for precise affordability guidance.',
      actionLabel: goalAffordable ? 'Open Trader' : 'Track Purchase',
      status: goalAffordable ? ArcCommandStatus.ready : ArcCommandStatus.active,
      completionPercent: tracker.completionPercent,
      targetValue: tracker.targetValue,
      currentValue: tracker.currentValue,
      remainingValue: tracker.remainingValue,
      trackedPurchaseCount: tracker.purchases.length,
      completedPurchaseCount: tracker.completedPurchaseCount,
      affordablePurchaseCount: affordable,
      nearlyAffordablePurchaseCount: nearlyAffordable,
      tradeNeedLabels: tradeNeeds,
      topPurchases: rankedPurchases.take(4).toList(growable: false),
      bestPurchase: best,
    );
  }

  ArcNomadicTraderPurchaseIntelligence _scorePurchase({
    required ArcNomadicTraderPurchaseSnapshot purchase,
    required ArcNomadicTraderTrackerSnapshot tracker,
    required ArcQuestIntelligence? questIntel,
    required ArcBenchIntelligence? benchIntel,
    required ArcSavedLoadout? favouriteLoadout,
    required Map<String, ArcBlueprintState> blueprintStates,
    required ArcCommandTradeActivity tradeActivity,
    required int duplicateBlueprints,
  }) {
    final missingResources = purchase.requirements
        .where((requirement) => requirement.remainingQty > 0)
        .map(
          (requirement) => '${requirement.name} x${requirement.remainingQty}',
        )
        .toList(growable: false);
    final requirementsComplete =
        purchase.requirements.isNotEmpty &&
        purchase.requirements.every((requirement) => requirement.complete);
    final matchesGoal = _sameSignal(purchase.name, tracker.goalName);
    final goalCanFund = matchesGoal && tracker.goalAffordable;
    final canAfford =
        !purchase.alreadyPurchased && (requirementsComplete || goalCanFund);
    final missingCount = purchase.missingRequirementCount;
    final nearlyAffords =
        !canAfford &&
        !purchase.alreadyPurchased &&
        (missingCount > 0 && missingCount <= 2 ||
            matchesGoal &&
                tracker.targetValue > 0 &&
                tracker.remainingValue <=
                    math.max(1000, tracker.targetValue ~/ 10));
    final neededForQuest = _matchesQuestNeed(purchase, questIntel);
    final neededForBench = _matchesBenchNeed(purchase, benchIntel);
    final neededForLoadout = _matchesLoadoutNeed(purchase, favouriteLoadout);
    final neededForBlueprint = _matchesBlueprintProgression(
      purchase,
      tracker,
      blueprintStates,
      duplicateBlueprints,
    );
    final inventoryExpansion = _containsAny(purchase.name, const [
      'stash',
      'vault',
      'backpack',
      'expansion',
    ]);
    final highValueResource = purchase.requirements.any(
      (requirement) => _containsAny(requirement.name, const [
        'reactor',
        'matrix',
        'regulator',
        'compressor',
        'driver',
        'cell',
        'pulse',
      ]),
    );
    final rarePurchase = _containsAny(purchase.name, const [
      'queen',
      'matriarch',
      'reactor',
      'vaporizer',
      'electrocore',
      'spectrum',
      'teleron',
    ]);

    var score = 20;
    if (purchase.alreadyPurchased) score = 6;
    if (neededForQuest) score += 55;
    if (neededForBench) score += 48;
    if (neededForLoadout) score += 38;
    if (neededForBlueprint) score += 34;
    if (inventoryExpansion) score += 28;
    if (purchase.isGalleryProject) score += 24;
    if (highValueResource) score += 18;
    if (rarePurchase) score += 14;
    if (canAfford) score += 18;
    if (nearlyAffords) score += 10;
    if (tradeActivity.communityListings > 0 && missingResources.isNotEmpty) {
      score += 6;
    }

    final priority = _priorityLabel(
      neededForQuest: neededForQuest,
      neededForBench: neededForBench,
      neededForLoadout: neededForLoadout,
      neededForBlueprint: neededForBlueprint,
      inventoryExpansion: inventoryExpansion,
      highValueResource: highValueResource,
      rarePurchase: rarePurchase,
      purchase: purchase,
    );
    final reason = _reason(
      purchase: purchase,
      priority: priority,
      canAfford: canAfford,
      nearlyAffords: nearlyAffords,
      missingResources: missingResources,
      duplicateBlueprints: duplicateBlueprints,
      tradeActivity: tradeActivity,
    );
    final action = purchase.alreadyPurchased
        ? 'Tracked'
        : canAfford
        ? 'Buy now'
        : missingResources.isNotEmpty &&
              (tradeActivity.communityListings > 0 || duplicateBlueprints > 0)
        ? 'Trade for missing'
        : nearlyAffords
        ? 'Gather final resources'
        : 'Track resources';

    return ArcNomadicTraderPurchaseIntelligence(
      purchase: purchase,
      priorityScore: score.clamp(0, 100),
      priorityLabel: priority,
      reason: reason,
      recommendedAction: action,
      progressImpact: _progressImpact(
        neededForQuest: neededForQuest,
        neededForBench: neededForBench,
        neededForLoadout: neededForLoadout,
        neededForBlueprint: neededForBlueprint,
        inventoryExpansion: inventoryExpansion,
        highValueResource: highValueResource,
        purchase: purchase,
      ),
      canAfford: canAfford,
      nearlyAffords: nearlyAffords,
      impossibleToBuy:
          !canAfford &&
          !nearlyAffords &&
          missingResources.isNotEmpty &&
          purchase.requirements.every(
            (requirement) => requirement.ownedQty == 0,
          ),
      neededForQuest: neededForQuest,
      neededForBench: neededForBench,
      neededForLoadout: neededForLoadout,
      neededForBlueprintProgression: neededForBlueprint,
      missingResources: missingResources,
      status: purchase.alreadyPurchased
          ? ArcCommandStatus.success
          : canAfford
          ? ArcCommandStatus.ready
          : nearlyAffords
          ? ArcCommandStatus.warning
          : ArcCommandStatus.active,
    );
  }

  List<String> _tradeNeedLabels({
    required ArcNomadicTraderPurchaseIntelligence? best,
    required ArcNomadicTraderTrackerSnapshot tracker,
    required int duplicateBlueprints,
    required ArcCommandTradeActivity tradeActivity,
  }) {
    final needs = <String>[
      if (best != null)
        ...best.missingResources.take(3).map((resource) => 'Trader: $resource'),
      if (best == null && tracker.remainingValue > 0)
        'Trader value ${tracker.remainingValue}',
      if (duplicateBlueprints > 0)
        '$duplicateBlueprints duplicate blueprint trade ${duplicateBlueprints == 1 ? 'signal' : 'signals'}',
      if (tradeActivity.communityListings > 0)
        '${tradeActivity.communityListings} listings can be checked',
    ];
    return needs.take(4).toList(growable: false);
  }

  bool _matchesQuestNeed(
    ArcNomadicTraderPurchaseSnapshot purchase,
    ArcQuestIntelligence? questIntel,
  ) {
    if (questIntel == null ||
        !questIntel.trackingKnown ||
        !questIntel.hasBlocker) {
      return false;
    }
    return questIntel.missingItems.any(
      (item) => _purchaseMentions(purchase, item.itemName),
    );
  }

  bool _matchesBenchNeed(
    ArcNomadicTraderPurchaseSnapshot purchase,
    ArcBenchIntelligence? benchIntel,
  ) {
    if (benchIntel == null ||
        !benchIntel.trackingKnown ||
        !benchIntel.hasBlocker) {
      return false;
    }
    return benchIntel.missingResources.any(
      (resource) => _purchaseMentions(purchase, resource.itemName),
    );
  }

  bool _matchesLoadoutNeed(
    ArcNomadicTraderPurchaseSnapshot purchase,
    ArcSavedLoadout? loadout,
  ) {
    if (loadout == null) return false;
    final signals = <String>[
      loadout.augment,
      loadout.primaryWeapon,
      loadout.secondaryWeapon,
      ...loadout.primaryAttachments,
      ...loadout.secondaryAttachments,
      ...loadout.equipment,
      ...loadout.consumables,
    ].where((value) => value.trim().isNotEmpty);
    return signals.any((signal) => _purchaseMentions(purchase, signal));
  }

  bool _matchesBlueprintProgression(
    ArcNomadicTraderPurchaseSnapshot purchase,
    ArcNomadicTraderTrackerSnapshot tracker,
    Map<String, ArcBlueprintState> blueprintStates,
    int duplicateBlueprints,
  ) {
    if (_purchaseMentions(purchase, 'blueprint') ||
        _sameSignal(tracker.goalName, 'Blueprint')) {
      return true;
    }
    if (duplicateBlueprints <= 0 && blueprintStates.isEmpty) return false;
    return purchase.requirements.any(
      (requirement) => _sameSignal(requirement.name, 'Duplicate Blueprint'),
    );
  }

  bool _purchaseMentions(
    ArcNomadicTraderPurchaseSnapshot purchase,
    String signal,
  ) {
    return _sameSignal(purchase.name, signal) ||
        purchase.requirements.any(
          (requirement) => _sameSignal(requirement.name, signal),
        );
  }

  String _priorityLabel({
    required bool neededForQuest,
    required bool neededForBench,
    required bool neededForLoadout,
    required bool neededForBlueprint,
    required bool inventoryExpansion,
    required bool highValueResource,
    required bool rarePurchase,
    required ArcNomadicTraderPurchaseSnapshot purchase,
  }) {
    if (neededForQuest) return 'Critical quest blocker';
    if (neededForBench) return 'Bench unlock';
    if (neededForLoadout) return 'Favourite loadout unlock';
    if (neededForBlueprint) return 'Blueprint progression';
    if (inventoryExpansion) return 'Inventory expansion';
    if (highValueResource) return 'High-value resource';
    if (rarePurchase || purchase.isGalleryProject) return 'Rare purchase';
    if (purchase.alreadyPurchased) return 'Tracked complete';
    return purchase.progress > 0 ? 'Optional purchase' : 'Low priority';
  }

  String _reason({
    required ArcNomadicTraderPurchaseSnapshot purchase,
    required String priority,
    required bool canAfford,
    required bool nearlyAffords,
    required List<String> missingResources,
    required int duplicateBlueprints,
    required ArcCommandTradeActivity tradeActivity,
  }) {
    if (purchase.alreadyPurchased) {
      return '${purchase.name} is already marked complete in Nomadic Trader tracking.';
    }
    if (canAfford) {
      return '${purchase.name} is affordable now and ranked as $priority.';
    }
    if (missingResources.isNotEmpty) {
      final tradeHint =
          tradeActivity.communityListings > 0 || duplicateBlueprints > 0
          ? ' Trade Centre may help close the gap.'
          : '';
      return '${purchase.name} needs ${missingResources.take(2).join(', ')}.$tradeHint';
    }
    if (nearlyAffords) {
      return '${purchase.name} is close to affordable based on tracked trader value.';
    }
    return '${purchase.name} is ranked as $priority from tracked trader context.';
  }

  String _progressImpact({
    required bool neededForQuest,
    required bool neededForBench,
    required bool neededForLoadout,
    required bool neededForBlueprint,
    required bool inventoryExpansion,
    required bool highValueResource,
    required ArcNomadicTraderPurchaseSnapshot purchase,
  }) {
    if (neededForQuest) return 'Clears or accelerates an active quest blocker.';
    if (neededForBench) return 'Feeds the next bench upgrade path.';
    if (neededForLoadout) return 'Supports the saved Favourite Loadout.';
    if (neededForBlueprint) {
      return 'Supports blueprint progression or trade value.';
    }
    if (inventoryExpansion) return 'Expands practical inventory capacity.';
    if (purchase.isGalleryProject) {
      return 'Progresses a tracked gallery project.';
    }
    if (highValueResource) return 'Protects high-value resource spend.';
    return 'Keeps the current trader purchase plan visible.';
  }

  bool _sameSignal(String source, String target) {
    final sourceTokens = _normalise(source);
    final targetTokens = _normalise(target);
    if (sourceTokens.isEmpty || targetTokens.isEmpty) return false;
    return sourceTokens.contains(targetTokens) ||
        targetTokens.contains(sourceTokens);
  }

  bool _containsAny(String source, List<String> signals) {
    final normalised = _normalise(source);
    return signals.any((signal) => normalised.contains(_normalise(signal)));
  }

  String _normalise(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
