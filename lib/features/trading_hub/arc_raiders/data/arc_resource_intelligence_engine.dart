import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_upgrade_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_compatibility_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_requirement_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_scrappy_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/trade_items_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/unified_item_index.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_bench_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_nomadic_trader_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_quest_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_resource_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';

class ArcResourceIntelligenceEngine {
  const ArcResourceIntelligenceEngine();

  ArcResourceIntelligence build({
    required Map<String, ArcScrappyState> scrappyStates,
    required ArcQuestIntelligence questIntel,
    required ArcBenchIntelligence benchIntel,
    required ArcNomadicTraderIntelligence traderIntel,
    ArcSavedLoadout? favouriteLoadout,
    Map<String, ArcBlueprintState> blueprintStates =
        const <String, ArcBlueprintState>{},
    ArcCommandTradeActivity tradeActivity = ArcCommandTradeActivity.empty,
  }) {
    final drafts = <String, _ResourceDraft>{};
    final ownedByName = _ownedByResourceName(scrappyStates);

    void addRequirement({
      required String name,
      required String system,
      required String source,
      required int requiredCount,
      required int ownedCount,
      required String? locationHint,
      bool currentBlocker = false,
      bool futureOnly = false,
    }) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) return;
      final safeRequired = math.max(0, requiredCount);
      final safeOwned = math.max(0, ownedCount);
      final missing = math.max(0, safeRequired - safeOwned);
      final draft = drafts.putIfAbsent(
        _resourceId(trimmed),
        () => _ResourceDraft(id: _resourceId(trimmed), name: trimmed),
      );
      draft.addSignal(
        ArcResourceRequirementSignal(
          system: system,
          source: source,
          requiredCount: safeRequired,
          ownedCount: safeOwned,
          missingCount: missing,
          locationHint: locationHint,
          currentBlocker: currentBlocker,
          futureOnly: futureOnly,
        ),
      );
    }

    for (final item
        in ArcQuestRequirementSeedData.items.whereType<ArcScrappyItem>()) {
      final state = scrappyStates[item.id] ?? ArcScrappyState.empty(item.id);
      final blocker = _questBlocks(item.name, questIntel);
      addRequirement(
        name: item.name,
        system: 'Quest',
        source: '${item.category} - ${item.group}',
        requiredCount: item.neededCount,
        ownedCount: state.collectedCount.clamp(0, item.neededCount).toInt(),
        locationHint: item.locationHint,
        currentBlocker: blocker,
        futureOnly: !blocker,
      );
    }

    for (final item
        in ArcBenchUpgradeSeedData.items.whereType<ArcScrappyItem>()) {
      final state = scrappyStates[item.id] ?? ArcScrappyState.empty(item.id);
      final blocker = _benchBlocks(item.name, benchIntel);
      addRequirement(
        name: item.name,
        system: 'Bench',
        source: '${item.category} - ${item.group}',
        requiredCount: item.neededCount,
        ownedCount: state.collectedCount.clamp(0, item.neededCount).toInt(),
        locationHint: item.locationHint,
        currentBlocker: blocker,
        futureOnly: !blocker,
      );
    }

    for (final item in ArcScrappySeedData.items.whereType<ArcScrappyItem>()) {
      final state = scrappyStates[item.id] ?? ArcScrappyState.empty(item.id);
      addRequirement(
        name: item.name,
        system: 'Future Wipe',
        source: 'Scrappy ${item.group}',
        requiredCount: item.neededCount,
        ownedCount: state.collectedCount.clamp(0, item.neededCount).toInt(),
        locationHint: item.locationHint,
        futureOnly: true,
      );
    }

    for (final purchase in traderIntel.topPurchases) {
      for (final requirement in purchase.purchase.requirements) {
        addRequirement(
          name: requirement.name,
          system: 'Nomadic Trader',
          source: purchase.purchase.name,
          requiredCount: requirement.requiredQty,
          ownedCount: requirement.ownedQty,
          locationHint: null,
          currentBlocker:
              purchase.purchase.id == traderIntel.bestPurchase?.purchase.id &&
              requirement.remainingQty > 0,
        );
      }
    }

    if (favouriteLoadout != null) {
      for (final material in _loadoutMaterials(favouriteLoadout)) {
        addRequirement(
          name: material.name,
          system: 'Favourite Loadout',
          source: material.source,
          requiredCount: material.count,
          ownedCount: ownedByName[_resourceId(material.name)] ?? 0,
          locationHint: material.hint,
          currentBlocker: true,
        );
      }
    }

    final duplicateBlueprints = blueprintStates.values.fold<int>(
      0,
      (total, state) => total + state.dupesOwned,
    );
    if (duplicateBlueprints > 0) {
      final draft = drafts.putIfAbsent(
        'duplicate-blueprint',
        () => _ResourceDraft(
          id: 'duplicate-blueprint',
          name: 'Duplicate Blueprint',
        ),
      );
      draft.explicitDuplicateCount += duplicateBlueprints;
      draft.ownedCount = math.max(draft.ownedCount, duplicateBlueprints);
      draft.systems.addAll(<String>['Blueprints', 'Trade']);
      draft.sourceHints.add('Blueprint tracker duplicate count');
    }

    final entries =
        drafts.values
            .map((draft) => _entryFor(draft, tradeActivity: tradeActivity))
            .toList(growable: false)
          ..sort((left, right) {
            final score = right.progressionValue.compareTo(
              left.progressionValue,
            );
            if (score != 0) return score;
            return left.name.compareTo(right.name);
          });

    final trackingKnown =
        scrappyStates.isNotEmpty ||
        traderIntel.trackingKnown ||
        favouriteLoadout != null ||
        blueprintStates.isNotEmpty;
    final missing = entries
        .where((entry) => entry.isMissing)
        .toList(growable: false);
    final safeTrade = entries
        .where((entry) => entry.safeToTrade)
        .toList(growable: false);
    final protected = entries
        .where((entry) => entry.neverTrade)
        .toList(growable: false);
    final multiSystem = entries
        .where((entry) => entry.usedByMultipleSystems)
        .toList(growable: false);
    final top = entries.isEmpty ? null : entries.first;
    final farmTargets = missing
        .where((entry) => entry.farmHint.trim().isNotEmpty)
        .take(5)
        .toList(growable: false);
    final tradeTargets = missing
        .where(
          (entry) =>
              tradeActivity.communityListings > 0 || entry.scarcityScore >= 60,
        )
        .take(5)
        .toList(growable: false);
    final inventory = _inventoryFor(
      entries: entries,
      safeTrade: safeTrade,
      protected: protected,
    );

    if (!trackingKnown) {
      return ArcResourceIntelligence(
        trackingKnown: false,
        statusLabel: 'Set up',
        summary: 'Resource ownership is not tracked yet.',
        recommendation:
            'Track quest, bench or trader resources to activate inventory intelligence.',
        actionLabel: 'Track Resources',
        status: ArcCommandStatus.neutral,
        totalTrackedResources: 0,
        totalRequiredResources: entries.fold<int>(
          0,
          (total, entry) => total + entry.requiredCount,
        ),
        totalMissingResources: entries.fold<int>(
          0,
          (total, entry) => total + entry.missingCount,
        ),
        totalDuplicateResources: 0,
        entries: entries,
        highestPriorityResources: const <ArcResourceIntelligenceEntry>[],
        lowestPriorityResources: const <ArcResourceIntelligenceEntry>[],
        missingResources: const <ArcResourceIntelligenceEntry>[],
        multiSystemResources: const <ArcResourceIntelligenceEntry>[],
        safeTradeCandidates: const <ArcResourceIntelligenceEntry>[],
        neverTradeResources: const <ArcResourceIntelligenceEntry>[],
        farmTargets: const <ArcResourceIntelligenceEntry>[],
        tradeTargets: const <ArcResourceIntelligenceEntry>[],
        inventory: inventory,
      );
    }

    return ArcResourceIntelligence(
      trackingKnown: true,
      statusLabel: top == null
          ? 'Clear'
          : top.blocksMultipleSystems
          ? 'Multi-system blocker'
          : safeTrade.isNotEmpty
          ? 'Surplus available'
          : missing.isNotEmpty
          ? 'Missing resources'
          : 'Stable',
      summary: _summaryFor(top, safeTrade),
      recommendation: _recommendationFor(top, safeTrade),
      actionLabel: safeTrade.isNotEmpty ? 'Review Trades' : 'Farm Resources',
      status: top?.status ?? ArcCommandStatus.neutral,
      totalTrackedResources: entries
          .where((entry) => entry.ownedCount > 0)
          .length,
      totalRequiredResources: entries.fold<int>(
        0,
        (total, entry) => total + entry.requiredCount,
      ),
      totalMissingResources: entries.fold<int>(
        0,
        (total, entry) => total + entry.missingCount,
      ),
      totalDuplicateResources: entries.fold<int>(
        0,
        (total, entry) => total + entry.duplicateCount,
      ),
      entries: entries,
      highestPriorityResources: entries.take(5).toList(growable: false),
      lowestPriorityResources: entries.reversed
          .where((entry) => !entry.neverTrade && !entry.isMissing)
          .take(5)
          .toList(growable: false),
      missingResources: missing,
      multiSystemResources: multiSystem,
      safeTradeCandidates: safeTrade.take(5).toList(growable: false),
      neverTradeResources: protected.take(5).toList(growable: false),
      farmTargets: farmTargets,
      tradeTargets: tradeTargets,
      inventory: inventory,
      topResource: top,
    );
  }

  ArcResourceIntelligenceEntry _entryFor(
    _ResourceDraft draft, {
    required ArcCommandTradeActivity tradeActivity,
  }) {
    final tradeItem = _tradeItemFor(draft.name);
    final unified = _unifiedEntryFor(draft.name);
    final requiredCount = draft.requirements.fold<int>(
      0,
      (total, signal) => total + signal.requiredCount,
    );
    final missingCount = draft.requirements.fold<int>(
      0,
      (total, signal) => total + signal.missingCount,
    );
    final currentBlockers = draft.requirements
        .where((signal) => signal.currentBlocker && signal.missingCount > 0)
        .map((signal) => signal.system)
        .toSet()
        .toList(growable: false);
    final systems = <String>{
      ...draft.systems,
      ...draft.requirements.map((signal) => signal.system),
      ...?unified?.usedIn,
    }.toList(growable: false)..sort();
    final sourceHints = <String>{
      ...draft.sourceHints,
      ...draft.requirements
          .map((signal) => signal.locationHint)
          .whereType<String>(),
      ...?tradeItem?.sourceHints,
    }.where((hint) => hint.trim().isNotEmpty).toList(growable: false);
    final futureLabels = draft.requirements
        .where((signal) => signal.futureOnly && signal.missingCount > 0)
        .map((signal) => signal.system)
        .toSet()
        .toList(growable: false);
    final duplicateCount = draft.explicitDuplicateCount > 0
        ? draft.explicitDuplicateCount
        : math.max(0, draft.ownedCount - requiredCount);
    final scarcity = _scarcityScore(
      missingCount: missingCount,
      tradeItem: tradeItem,
      sourceHints: sourceHints,
    );
    final usefulness = _usefulnessScore(
      systems: systems,
      currentBlockers: currentBlockers,
      futureLabels: futureLabels,
    );
    final progression = (scarcity * 0.42 + usefulness * 0.58).round().clamp(
      0,
      100,
    );
    final neverTrade =
        missingCount > 0 &&
        (currentBlockers.isNotEmpty ||
            systems.length >= 2 ||
            progression >= 65);
    final safeToTrade = duplicateCount > 0 && !neverTrade;
    final safeToSell =
        duplicateCount > 2 && !neverTrade && usefulness < 35 && scarcity < 45;
    final status = currentBlockers.length >= 2
        ? ArcCommandStatus.critical
        : missingCount > 0
        ? ArcCommandStatus.warning
        : safeToTrade
        ? ArcCommandStatus.ready
        : requiredCount > 0
        ? ArcCommandStatus.active
        : ArcCommandStatus.neutral;

    return ArcResourceIntelligenceEntry(
      id: draft.id,
      name: draft.name,
      ownedCount: draft.ownedCount,
      requiredCount: requiredCount,
      missingCount: missingCount,
      duplicateCount: duplicateCount,
      systemLabels: systems,
      currentBlockerLabels: currentBlockers,
      sourceHints: sourceHints,
      farmHint: _farmHintFor(sourceHints),
      scarcityScore: scarcity,
      usefulnessScore: usefulness,
      progressionValue: progression,
      priorityLabel: _priorityLabel(
        name: draft.name,
        currentBlockers: currentBlockers,
        missingCount: missingCount,
        safeToTrade: safeToTrade,
        systems: systems,
      ),
      protectionLabel: neverTrade
          ? 'Never trade'
          : safeToTrade
          ? 'Safe surplus'
          : 'Keep tracked',
      recommendation: _entryRecommendation(
        name: draft.name,
        missingCount: missingCount,
        currentBlockers: currentBlockers,
        safeToTrade: safeToTrade,
        duplicateCount: duplicateCount,
        sourceHints: sourceHints,
      ),
      tradeActionLabel: neverTrade
          ? 'Keep'
          : safeToTrade
          ? 'Offer surplus'
          : missingCount > 0 && tradeActivity.communityListings > 0
          ? 'Buy or trade'
          : missingCount > 0
          ? 'Farm'
          : 'Hold',
      status: status,
      neverTrade: neverTrade,
      safeToTrade: safeToTrade,
      safeToSell: safeToSell,
      futureRequirementLabels: futureLabels,
      requirements: draft.requirements,
    );
  }

  Map<String, int> _ownedByResourceName(
    Map<String, ArcScrappyState> scrappyStates,
  ) {
    final owned = <String, int>{};
    void collect(Iterable<Object?> items) {
      for (final item in items.whereType<ArcScrappyItem>()) {
        final state = scrappyStates[item.id];
        if (state == null || state.collectedCount <= 0) continue;
        final key = _resourceId(item.name);
        owned[key] = math.max(owned[key] ?? 0, state.collectedCount);
      }
    }

    collect(ArcQuestRequirementSeedData.items);
    collect(ArcBenchUpgradeSeedData.items);
    collect(ArcScrappySeedData.items);
    return owned;
  }

  List<_LoadoutMaterial> _loadoutMaterials(ArcSavedLoadout loadout) {
    final materials = <_LoadoutMaterial>[];
    for (final attachmentName in [
      ...loadout.primaryAttachments,
      ...loadout.secondaryAttachments,
    ]) {
      final spec = ArcLoadoutCompatibilityRegistry.attachmentSpecForName(
        attachmentName,
      );
      if (spec == null) continue;
      for (final raw in spec.materials) {
        final parsed = _parseMaterial(raw);
        if (parsed == null) continue;
        materials.add(
          _LoadoutMaterial(
            name: parsed.name,
            count: parsed.count,
            source: spec.name,
            hint: spec.benchLabel,
          ),
        );
      }
    }
    return materials;
  }

  _ParsedMaterial? _parseMaterial(String raw) {
    final match = RegExp(
      r'^\s*(\d+)\s*x\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (match != null) {
      return _ParsedMaterial(
        name: match.group(2)!.trim(),
        count: int.tryParse(match.group(1) ?? '') ?? 1,
      );
    }
    final fallback = raw.trim();
    if (fallback.isEmpty) return null;
    return _ParsedMaterial(name: fallback, count: 1);
  }

  bool _questBlocks(String name, ArcQuestIntelligence questIntel) {
    return questIntel.trackingKnown &&
        questIntel.missingItems.any((item) => _sameSignal(item.itemName, name));
  }

  bool _benchBlocks(String name, ArcBenchIntelligence benchIntel) {
    return benchIntel.trackingKnown &&
        benchIntel.missingResources.any(
          (item) => _sameSignal(item.itemName, name),
        );
  }

  ArcTradeItem? _tradeItemFor(String name) {
    final key = _resourceId(name);
    for (final item in ArcTradeItemsData.items) {
      if (_resourceId(item.name) == key || item.id == key) return item;
    }
    return null;
  }

  UnifiedItemEntry? _unifiedEntryFor(String name) {
    final key = _resourceId(name);
    for (final item in UnifiedItemIndex.items) {
      if (_resourceId(item.name) == key ||
          item.id == key ||
          item.aliases.any((alias) => _resourceId(alias) == key)) {
        return item;
      }
    }
    return null;
  }

  int _scarcityScore({
    required int missingCount,
    required ArcTradeItem? tradeItem,
    required List<String> sourceHints,
  }) {
    var score = math.min(46, missingCount * 8);
    switch (tradeItem?.tradeValue) {
      case ArcTradeValueTier.elite:
        score += 30;
      case ArcTradeValueTier.high:
        score += 22;
      case ArcTradeValueTier.mid:
        score += 12;
      case ArcTradeValueTier.low:
        score += 4;
      case null:
        score += 8;
    }
    if (sourceHints.isEmpty && missingCount > 0) score += 8;
    return score.clamp(0, 100);
  }

  int _usefulnessScore({
    required List<String> systems,
    required List<String> currentBlockers,
    required List<String> futureLabels,
  }) {
    final score =
        systems.length * 14 +
        currentBlockers.length * 24 +
        futureLabels.length * 5;
    return score.clamp(0, 100);
  }

  String _priorityLabel({
    required String name,
    required List<String> currentBlockers,
    required int missingCount,
    required bool safeToTrade,
    required List<String> systems,
  }) {
    if (currentBlockers.length >= 2) {
      return '$name blocks ${currentBlockers.length} systems';
    }
    if (currentBlockers.length == 1) return '${currentBlockers.first} blocker';
    if (missingCount > 0 && systems.length >= 2) {
      return 'Multi-system requirement';
    }
    if (missingCount > 0) return 'Farm priority';
    if (safeToTrade) return 'Safe trade surplus';
    return 'Low pressure';
  }

  String _entryRecommendation({
    required String name,
    required int missingCount,
    required List<String> currentBlockers,
    required bool safeToTrade,
    required int duplicateCount,
    required List<String> sourceHints,
  }) {
    if (currentBlockers.length >= 2) {
      return '$name blocks ${currentBlockers.length} systems. Farm or trade for it before spending elsewhere.';
    }
    if (currentBlockers.length == 1) {
      return '$name blocks ${currentBlockers.first}. Keep all copies until that requirement clears.';
    }
    if (missingCount > 0) {
      return 'Farm $name${sourceHints.isEmpty ? '' : ' via ${sourceHints.first}'} before trading it away.';
    }
    if (safeToTrade) {
      return 'Safe to trade $duplicateCount surplus $name.';
    }
    return 'Keep $name tracked for future requirements.';
  }

  String _summaryFor(
    ArcResourceIntelligenceEntry? top,
    List<ArcResourceIntelligenceEntry> safeTrade,
  ) {
    if (top == null) return 'No resource requirements are currently visible.';
    if (top.blocksMultipleSystems) {
      return '${top.name} blocks ${top.currentBlockerLabels.length} systems.';
    }
    if (top.isMissing) return 'Farm ${top.missingLabel} next.';
    if (safeTrade.isNotEmpty) {
      final safe = safeTrade.first;
      return 'Safe to trade ${safe.duplicateCount} ${safe.name}.';
    }
    return 'Resource pressure is stable across tracked systems.';
  }

  String _recommendationFor(
    ArcResourceIntelligenceEntry? top,
    List<ArcResourceIntelligenceEntry> safeTrade,
  ) {
    if (top == null) return 'Track resources in Quest, Bench or Trader tools.';
    if (top.isMissing) return top.recommendation;
    if (safeTrade.isNotEmpty) return safeTrade.first.recommendation;
    return 'Keep protected resources until future requirements clear.';
  }

  ArcInventoryIntelligence _inventoryFor({
    required List<ArcResourceIntelligenceEntry> entries,
    required List<ArcResourceIntelligenceEntry> safeTrade,
    required List<ArcResourceIntelligenceEntry> protected,
  }) {
    final safeSell = entries
        .where((entry) => entry.safeToSell)
        .take(5)
        .toList(growable: false);
    final futureLabels = entries
        .expand((entry) => entry.futureRequirementLabels)
        .toSet()
        .take(5)
        .toList(growable: false);
    if (protected.isNotEmpty) {
      return ArcInventoryIntelligence(
        pressureLabel: 'Protected',
        pressureDetail:
            '${protected.length} resource ${protected.length == 1 ? 'is' : 'are'} blocking progression.',
        status: ArcCommandStatus.warning,
        safeTradeCandidates: safeTrade,
        safeSellCandidates: safeSell,
        protectedResources: protected.take(5).toList(growable: false),
        futureRequirementLabels: futureLabels,
      );
    }
    if (safeTrade.isNotEmpty) {
      return ArcInventoryIntelligence(
        pressureLabel: 'Surplus',
        pressureDetail:
            '${safeTrade.first.name} has ${safeTrade.first.duplicateCount} tracked surplus.',
        status: ArcCommandStatus.ready,
        safeTradeCandidates: safeTrade,
        safeSellCandidates: safeSell,
        protectedResources: protected,
        futureRequirementLabels: futureLabels,
      );
    }
    return ArcInventoryIntelligence(
      pressureLabel: 'Stable',
      pressureDetail: 'No safe surplus or protected blocker is dominant.',
      status: ArcCommandStatus.neutral,
      safeTradeCandidates: safeTrade,
      safeSellCandidates: safeSell,
      protectedResources: protected,
      futureRequirementLabels: futureLabels,
    );
  }

  String _farmHintFor(List<String> sourceHints) {
    if (sourceHints.isEmpty) return '';
    return sourceHints.first.replaceFirst('Best intel: ', '').trim();
  }

  String _resourceId(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  bool _sameSignal(String left, String right) {
    final leftKey = _resourceId(left);
    final rightKey = _resourceId(right);
    return leftKey == rightKey ||
        leftKey.contains(rightKey) ||
        rightKey.contains(leftKey);
  }
}

class _ResourceDraft {
  _ResourceDraft({required this.id, required this.name});

  final String id;
  final String name;
  final List<ArcResourceRequirementSignal> requirements = [];
  final Set<String> systems = <String>{};
  final Set<String> sourceHints = <String>{};
  var ownedCount = 0;
  var explicitDuplicateCount = 0;

  void addSignal(ArcResourceRequirementSignal signal) {
    requirements.add(signal);
    systems.add(signal.system);
    ownedCount = math.max(ownedCount, signal.ownedCount);
    final hint = signal.locationHint;
    if (hint != null && hint.trim().isNotEmpty) {
      sourceHints.add(hint.trim());
    }
  }
}

class _ParsedMaterial {
  const _ParsedMaterial({required this.name, required this.count});

  final String name;
  final int count;
}

class _LoadoutMaterial {
  const _LoadoutMaterial({
    required this.name,
    required this.count,
    required this.source,
    required this.hint,
  });

  final String name;
  final int count;
  final String source;
  final String hint;
}
