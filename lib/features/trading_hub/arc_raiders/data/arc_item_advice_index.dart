import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/unified_item_index.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_voice_item_database.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';

/// UAG Raider's local item intelligence layer.
///
/// This deliberately builds on the app's own `UnifiedItemIndex` instead of
/// scraping restricted editorial/database sites into the app. The rules below
/// classify the full local item catalogue and combine it with live user state
/// from the Blueprint Tracker.
enum ArcItemPrimaryAction { keep, learn, trade, sell, recycle, use, check }

class ArcVoiceItemDecision {
  const ArcVoiceItemDecision({
    required this.title,
    required this.spokenAdvice,
    required this.displayAdvice,
    required this.primaryAction,
    required this.confidence,
    required this.reasons,
    this.item,
    this.blueprint,
    this.blueprintState,
  });

  final String title;
  final String spokenAdvice;
  final String displayAdvice;
  final ArcItemPrimaryAction primaryAction;
  final double confidence;
  final List<String> reasons;
  final UnifiedItemEntry? item;
  final ArcBlueprint? blueprint;
  final ArcBlueprintState? blueprintState;

  String get actionLabel {
    switch (primaryAction) {
      case ArcItemPrimaryAction.keep:
        return 'KEEP';
      case ArcItemPrimaryAction.learn:
        return 'KEEP + LEARN';
      case ArcItemPrimaryAction.trade:
        return 'SAVE TO TRADE';
      case ArcItemPrimaryAction.sell:
        return 'SELL';
      case ArcItemPrimaryAction.recycle:
        return 'RECYCLE';
      case ArcItemPrimaryAction.use:
        return 'USE / KEEP';
      case ArcItemPrimaryAction.check:
        return 'CHECK';
    }
  }
}

class ArcItemAdviceIndex {
  const ArcItemAdviceIndex._();

  static ArcVoiceItemDecision? decide({
    required String query,
    Map<String, ArcBlueprintState> blueprintStates =
        const <String, ArcBlueprintState>{},
  }) {
    final cleanedQuery = _cleanVoiceQuery(query);
    final blueprint = _findBlueprint(cleanedQuery);
    final item = _findItem(cleanedQuery);

    if (blueprint != null &&
        _queryLooksBlueprint(cleanedQuery, blueprint, item)) {
      return _blueprintDecision(blueprint, blueprintStates[blueprint.id]);
    }

    if (item != null && _entryLooksBlueprint(item)) {
      final matchedBlueprint = _findBlueprint(item.name) ?? blueprint;
      if (matchedBlueprint != null) {
        return _blueprintDecision(
          matchedBlueprint,
          blueprintStates[matchedBlueprint.id],
        );
      }
    }

    if (blueprint != null && item == null) {
      return _blueprintDecision(blueprint, blueprintStates[blueprint.id]);
    }

    final databaseMatch = ArcVoiceItemDatabase.findBest(cleanedQuery);

    if (item == null && databaseMatch == null) {
      return null;
    }

    if (databaseMatch != null && (item == null || databaseMatch.score >= 72)) {
      if (databaseMatch.item.isBlueprint) {
        final matchedBlueprint = _findBlueprint(databaseMatch.item.name);
        if (matchedBlueprint != null) {
          return _blueprintDecision(
            matchedBlueprint,
            blueprintStates[matchedBlueprint.id],
          );
        }
      }
      return _databaseDecision(databaseMatch.item, databaseMatch.score);
    }

    return _itemDecision(item!);
  }

  static List<UnifiedItemEntry> search(String query) {
    final cleanedQuery = _cleanVoiceQuery(query);
    final normalized = UnifiedItemIndex.normalize(cleanedQuery);
    if (normalized.isEmpty) {
      return const <UnifiedItemEntry>[];
    }

    final scored = <_ScoredItem>[];
    for (final item in UnifiedItemIndex.items) {
      final score = _scoreItem(item, normalized);
      if (score > 0) {
        scored.add(_ScoredItem(item, score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((entry) => entry.item).take(20).toList(growable: false);
  }

  static ArcVoiceItemDecision _blueprintDecision(
    ArcBlueprint blueprint,
    ArcBlueprintState? state,
  ) {
    final rarity = blueprint.rarityLabel;
    final owned = state?.owned ?? false;
    final duplicates = state?.dupesOwned ?? 0;

    if (!owned) {
      final reasons = <String>[
        'Blueprint Tracker says this blueprint is not owned.',
        'Blueprint unlock value is higher than sale value until learned.',
        'Rarity: $rarity.',
      ];
      final advice =
          '${blueprint.name}: keep it and consume it to learn the blueprint. You do not have this marked as owned yet. Rarity: $rarity.';
      return ArcVoiceItemDecision(
        title: blueprint.name,
        spokenAdvice: advice,
        displayAdvice: _formatDecision(
          action: 'KEEP + CONSUME / LEARN',
          advice: advice,
          reasons: reasons,
        ),
        primaryAction: ArcItemPrimaryAction.learn,
        confidence: 1,
        reasons: reasons,
        blueprint: blueprint,
        blueprintState: state,
      );
    }

    final dupeText = duplicates > 0
        ? 'You already have this learned and have $duplicates tracked duplicate${duplicates == 1 ? '' : 's'}.'
        : 'You already have this learned. If this drop is another copy, treat it as a duplicate.';
    final tradeStrength = _blueprintTradeStrength(blueprint.rarity);
    final reasons = <String>[
      'Blueprint Tracker says this blueprint is already owned.',
      'A second copy does not unlock extra progress.',
      tradeStrength,
    ];
    final advice =
        '${blueprint.name}: duplicate blueprint. Do not consume it. Save it to trade first; sell it only if you do not need trade stock. $dupeText Rarity: $rarity. $tradeStrength';

    return ArcVoiceItemDecision(
      title: blueprint.name,
      spokenAdvice: advice,
      displayAdvice: _formatDecision(
        action: 'SAVE TO TRADE / SELL IF NOT TRADING',
        advice: advice,
        reasons: reasons,
      ),
      primaryAction: ArcItemPrimaryAction.trade,
      confidence: 1,
      reasons: reasons,
      blueprint: blueprint,
      blueprintState: state,
    );
  }

  static ArcVoiceItemDecision _databaseDecision(
    ArcVoiceItemRecord item,
    int score,
  ) {
    final reasons = <String>[
      'Matched against the local UAG Raider item database.',
      'Category: ${item.category}.',
      'Rarity: ${item.rarity}.',
      if (item.usedToCraft.isNotEmpty)
        'Used to craft: ${item.usedToCraft.join(', ')}.',
    ];

    ArcItemPrimaryAction primaryAction;
    switch (item.action) {
      case ArcVoiceItemAction.keep:
        primaryAction = ArcItemPrimaryAction.keep;
        break;
      case ArcVoiceItemAction.sell:
        primaryAction = ArcItemPrimaryAction.sell;
        break;
      case ArcVoiceItemAction.recycle:
        primaryAction = ArcItemPrimaryAction.recycle;
        break;
      case ArcVoiceItemAction.trade:
        primaryAction = ArcItemPrimaryAction.trade;
        break;
      case ArcVoiceItemAction.learn:
        primaryAction = ArcItemPrimaryAction.learn;
        break;
      case ArcVoiceItemAction.use:
        primaryAction = ArcItemPrimaryAction.use;
        break;
      case ArcVoiceItemAction.check:
        primaryAction = ArcItemPrimaryAction.check;
        break;
    }

    final advice =
        '${item.name}: ${item.summary} Recommended action: ${item.actionLabel}.';
    return ArcVoiceItemDecision(
      title: item.name,
      spokenAdvice: advice,
      displayAdvice: _formatDecision(
        action: item.actionLabel,
        advice: advice,
        reasons: reasons,
      ),
      primaryAction: primaryAction,
      confidence: score >= 100 ? 1 : (score / 100).clamp(0.58, 0.98),
      reasons: reasons,
    );
  }

  static ArcVoiceItemDecision _itemDecision(UnifiedItemEntry item) {
    final name = item.name;
    final normalizedName = UnifiedItemIndex.normalize(
      '${item.name} ${item.id} ${item.aliases.join(' ')}',
    );
    final usedIn = item.usedIn.isEmpty
        ? 'No tracker usage currently mapped.'
        : item.usedIn.join(', ');

    if (item.neededForBench || item.neededForQuest || item.neededForScrappy) {
      final buckets = <String>[];
      if (item.neededForBench) buckets.add('bench upgrades');
      if (item.neededForQuest) buckets.add('quests');
      if (item.neededForScrappy) buckets.add('Scrappy');
      final reasons = <String>[
        'Mapped to ${_joinHuman(buckets)}.',
        'Used in: $usedIn.',
        'Progression items should not be sold until the tracker says you have enough.',
      ];
      final advice =
          '$name: keep it. It is currently linked to ${_joinHuman(buckets)}. Used in: $usedIn.';
      return ArcVoiceItemDecision(
        title: name,
        spokenAdvice: advice,
        displayAdvice: _formatDecision(
          action: 'KEEP',
          advice: advice,
          reasons: reasons,
        ),
        primaryAction: ArcItemPrimaryAction.keep,
        confidence: 0.96,
        reasons: reasons,
        item: item,
      );
    }

    if (_looksLikeKey(normalizedName)) {
      final reasons = <String>[
        'Keys and access cards unlock loot routes or restricted areas.',
        'They can be more useful as access/trade items than quick cash.',
        'Used in: $usedIn.',
      ];
      final advice =
          '$name: keep it or trade it. Keys and access cards can unlock valuable areas, so do not recycle them.';
      return ArcVoiceItemDecision(
        title: name,
        spokenAdvice: advice,
        displayAdvice: _formatDecision(
          action: 'KEEP / TRADE',
          advice: advice,
          reasons: reasons,
        ),
        primaryAction: ArcItemPrimaryAction.trade,
        confidence: 0.88,
        reasons: reasons,
        item: item,
      );
    }

    if (_looksLikeConsumableOrGear(normalizedName)) {
      final reasons = <String>[
        'Looks like usable gear, meds, ammo, weapons, or attachments.',
        'Keep it if you will run it; otherwise list it for trade or sell spare stock.',
        'Used in: $usedIn.',
      ];
      final advice =
          '$name: usable item. Keep it if you will run it; otherwise trade or sell spare copies.';
      return ArcVoiceItemDecision(
        title: name,
        spokenAdvice: advice,
        displayAdvice: _formatDecision(
          action: 'USE / KEEP / TRADE SPARES',
          advice: advice,
          reasons: reasons,
        ),
        primaryAction: ArcItemPrimaryAction.use,
        confidence: 0.82,
        reasons: reasons,
        item: item,
      );
    }

    if (_looksRecycleFirst(normalizedName)) {
      final reasons = <String>[
        'Not currently mapped to bench, quest, or Scrappy progression.',
        'Name matches recyclable salvage/junk patterns.',
        'Used in: $usedIn.',
      ];
      final advice =
          '$name: recycle candidate. It is not currently mapped to your progression trackers and looks like salvage.';
      return ArcVoiceItemDecision(
        title: name,
        spokenAdvice: advice,
        displayAdvice: _formatDecision(
          action: 'RECYCLE',
          advice: advice,
          reasons: reasons,
        ),
        primaryAction: ArcItemPrimaryAction.recycle,
        confidence: 0.78,
        reasons: reasons,
        item: item,
      );
    }

    if (_looksSellFirst(normalizedName)) {
      final reasons = <String>[
        'Not currently mapped to bench, quest, or Scrappy progression.',
        'Name matches value/trinket patterns.',
        'Used in: $usedIn.',
      ];
      final advice =
          '$name: sell candidate. It looks more like a value item than a progression item.';
      return ArcVoiceItemDecision(
        title: name,
        spokenAdvice: advice,
        displayAdvice: _formatDecision(
          action: 'SELL',
          advice: advice,
          reasons: reasons,
        ),
        primaryAction: ArcItemPrimaryAction.sell,
        confidence: 0.78,
        reasons: reasons,
        item: item,
      );
    }

    if (item.tradeRelevant) {
      final reasons = <String>[
        'Present in the Trading Hub catalogue.',
        'Not currently mapped as required by your progression trackers.',
        'Used in: $usedIn.',
      ];
      final advice =
          '$name: trade-aware item. Keep it if demand is high, otherwise sell or recycle based on stash pressure.';
      return ArcVoiceItemDecision(
        title: name,
        spokenAdvice: advice,
        displayAdvice: _formatDecision(
          action: 'CHECK TRADE DEMAND',
          advice: advice,
          reasons: reasons,
        ),
        primaryAction: ArcItemPrimaryAction.trade,
        confidence: 0.70,
        reasons: reasons,
        item: item,
      );
    }

    final reasons = <String>[
      'Item was recognised but has no strong progression/trade/recycle/sell mapping yet.',
      'Used in: $usedIn.',
    ];
    final advice =
        '$name: check manually. I found the item, but it needs more item intelligence before Raider can make a strong call.';
    return ArcVoiceItemDecision(
      title: name,
      spokenAdvice: advice,
      displayAdvice: _formatDecision(
        action: 'CHECK MANUALLY',
        advice: advice,
        reasons: reasons,
      ),
      primaryAction: ArcItemPrimaryAction.check,
      confidence: 0.45,
      reasons: reasons,
      item: item,
    );
  }

  static String _formatDecision({
    required String action,
    required String advice,
    required List<String> reasons,
  }) {
    final reasonText = reasons.map((reason) => '• $reason').join('\n');
    return '$advice\n\nAction: $action.\n\nWhy:\n$reasonText';
  }

  static ArcBlueprint? _findBlueprint(String query) {
    final normalized = UnifiedItemIndex.normalize(
      query.replaceAll('blueprint', ''),
    );
    if (normalized.isEmpty) return null;

    ArcBlueprint? exact;
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      final name = UnifiedItemIndex.normalize(blueprint.name);
      final id = UnifiedItemIndex.normalize(blueprint.id);
      if (name == normalized ||
          id == normalized ||
          '$name blueprint' == normalized) {
        exact = blueprint;
        break;
      }
    }
    if (exact != null) return exact;

    ArcBlueprint? best;
    var bestScore = 0;
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      final name = UnifiedItemIndex.normalize(blueprint.name);
      final id = UnifiedItemIndex.normalize(blueprint.id);
      final score = _scoreCandidate(normalized, <String>[
        name,
        id,
        '$name blueprint',
      ]);
      if (score > bestScore) {
        best = blueprint;
        bestScore = score;
      }
    }

    return bestScore >= 70 ? best : null;
  }

  static UnifiedItemEntry? _findItem(String query) {
    final normalized = UnifiedItemIndex.normalize(query);
    if (normalized.isEmpty) return null;

    UnifiedItemEntry? best;
    var bestScore = 0;
    for (final item in UnifiedItemIndex.items) {
      final score = _scoreItem(item, normalized);
      if (score > bestScore) {
        best = item;
        bestScore = score;
      }
    }

    return bestScore >= 60 ? best : UnifiedItemIndex.findBest(query);
  }

  static int _scoreItem(UnifiedItemEntry item, String normalizedQuery) {
    final candidates = <String>[
      UnifiedItemIndex.normalize(item.name),
      UnifiedItemIndex.normalize(item.id),
      for (final alias in item.aliases) UnifiedItemIndex.normalize(alias),
    ];
    return _scoreCandidate(normalizedQuery, candidates);
  }

  static int _scoreCandidate(String normalizedQuery, List<String> candidates) {
    var best = 0;
    final queryTokens = normalizedQuery
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toSet();

    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      if (candidate == normalizedQuery) best = best < 100 ? 100 : best;
      if (candidate.contains(normalizedQuery) ||
          normalizedQuery.contains(candidate)) {
        best = best < 86 ? 86 : best;
      }

      final candidateTokens = candidate
          .split(' ')
          .where((token) => token.isNotEmpty)
          .toSet();
      if (candidateTokens.isEmpty || queryTokens.isEmpty) continue;
      final overlap = queryTokens.intersection(candidateTokens).length;
      final tokenScore = ((overlap / candidateTokens.length) * 75).round();
      if (tokenScore > best) best = tokenScore;
    }

    return best;
  }

  static bool _queryLooksBlueprint(
    String query,
    ArcBlueprint blueprint,
    UnifiedItemEntry? item,
  ) {
    final normalized = UnifiedItemIndex.normalize(query);
    if (normalized.contains('blueprint')) return true;
    if (item == null) return true;
    final blueprintName = UnifiedItemIndex.normalize(blueprint.name);
    final itemName = UnifiedItemIndex.normalize(item.name);
    return blueprintName == itemName || itemName.contains('blueprint');
  }

  static bool _entryLooksBlueprint(UnifiedItemEntry item) {
    final normalized = UnifiedItemIndex.normalize('${item.id} ${item.name}');
    return normalized.contains('blueprint');
  }

  static String _cleanVoiceQuery(String query) {
    var cleaned = query.toLowerCase();
    const phrases = <String>[
      'hey uag raider',
      'uag raider',
      'hey raider',
      'raider',
      'do i need',
      'do we need',
      'should i keep',
      'should we keep',
      'can i trade',
      'can we trade',
      'what can i trade',
      'safe to trade',
      'is this needed',
      'is it needed',
      'should i sell',
      'can i sell',
      'should i recycle',
      'can i recycle',
      'what about',
      'i found',
      'found a',
      'found an',
      'found some',
      'this item',
      'this blueprint',
      'a blueprint for',
      'the blueprint for',
      'please',
    ];
    for (final phrase in phrases) {
      cleaned = cleaned.replaceAll(phrase, ' ');
    }
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool _looksLikeKey(String normalizedName) {
    const keywords = <String>[
      ' key',
      'key ',
      'security code',
      'access card',
      'confiscation room',
      'cellar',
      'container storage',
      'warehouse',
      'control tower',
      'medical storage',
      'security checkpoint',
    ];
    return keywords.any(normalizedName.contains);
  }

  static bool _looksLikeConsumableOrGear(String normalizedName) {
    const keywords = <String>[
      'shot',
      'syringe',
      'bandage',
      'ammo',
      'grenade',
      'mine',
      'trap',
      'anvil',
      'bettina',
      'bobcat',
      'burletta',
      'canto',
      'tempest',
      'venator',
      'vulcano',
      'torrente',
      'stitcher',
      'osprey',
      'renegade',
      'aphelion',
      'arpeggio',
      'grip',
      'stock',
      'silencer',
      'muzzle',
      'compensator',
      'choke',
      'splitter',
      'igniter',
    ];
    return keywords.any(normalizedName.contains);
  }

  static bool _looksRecycleFirst(String normalizedName) {
    const keywords = <String>[
      'broken',
      'burned',
      'burnt',
      'cracked',
      'damaged',
      'degraded',
      'fossilized',
      'impure',
      'polluted',
      'rusty',
      'tattered',
      'torn',
      'unusable',
      'coolant',
      'rubber pad',
      'power bank',
      'radio relay',
      'remote control',
      'projector',
      'processor',
      'headphones',
      'microscope',
      'thermostat',
      'toaster',
      'wire',
      'cable',
      'spring',
      'battery',
      'canister',
      'components',
      'parts',
      'scrap',
    ];
    return keywords.any(normalizedName.contains);
  }

  static bool _looksSellFirst(String normalizedName) {
    const keywords = <String>[
      'duck',
      'jewelry',
      'jewellery',
      'vase',
      'statuette',
      'pottery',
      'snow globe',
      'wristwatch',
      'teaspoon',
      'playing cards',
      'poster',
      'photograph',
      'ship model',
      'movie tapes',
      'guitar',
      'journal',
      'candles',
      'candle holder',
      'alien duck',
      'rubber duck',
      'red coral',
      'comfortable pillows',
    ];
    return keywords.any(normalizedName.contains);
  }

  static String _blueprintTradeStrength(ArcBlueprintRarity rarity) {
    switch (rarity) {
      case ArcBlueprintRarity.common:
        return 'Common duplicate: trade value is usually lower.';
      case ArcBlueprintRarity.uncommon:
        return 'Uncommon duplicate: moderate trade value.';
      case ArcBlueprintRarity.rare:
        return 'Rare duplicate: good trade stock.';
      case ArcBlueprintRarity.epic:
        return 'Epic duplicate: strong trade stock.';
      case ArcBlueprintRarity.legendary:
        return 'Legendary duplicate: high-value trade stock.';
    }
  }

  static String _joinHuman(List<String> values) {
    if (values.isEmpty) return 'your trackers';
    if (values.length == 1) return values.first;
    if (values.length == 2) return '${values.first} and ${values.last}';
    return '${values.sublist(0, values.length - 1).join(', ')}, and ${values.last}';
  }
}

class _ScoredItem {
  const _ScoredItem(this.item, this.score);
  final UnifiedItemEntry item;
  final int score;
}
