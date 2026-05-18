import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/unified_item_index.dart';

enum ArcVoiceItemAction { keep, sell, recycle, trade, learn, use, check }

class ArcVoiceItemRecord {
  const ArcVoiceItemRecord({
    required this.name,
    required this.rarity,
    required this.category,
    required this.action,
    required this.summary,
    this.aliases = const <String>[],
    this.usedToCraft = const <String>[],
  });

  final String name;
  final String rarity;
  final String category;
  final ArcVoiceItemAction action;
  final String summary;
  final List<String> aliases;
  final List<String> usedToCraft;

  String get actionLabel {
    switch (action) {
      case ArcVoiceItemAction.keep:
        return 'KEEP';
      case ArcVoiceItemAction.sell:
        return 'SELL';
      case ArcVoiceItemAction.recycle:
        return 'RECYCLE';
      case ArcVoiceItemAction.trade:
        return 'SAVE TO TRADE';
      case ArcVoiceItemAction.learn:
        return 'KEEP + LEARN';
      case ArcVoiceItemAction.use:
        return 'USE / KEEP';
      case ArcVoiceItemAction.check:
        return 'CHECK';
    }
  }

  bool get isBlueprint =>
      category.toLowerCase() == 'blueprint' ||
      name.toLowerCase().endsWith(' blueprint');
}

class ArcVoiceItemMatch {
  const ArcVoiceItemMatch(this.item, this.score);
  final ArcVoiceItemRecord item;
  final int score;
}

class ArcVoiceItemDatabase {
  const ArcVoiceItemDatabase._();

  static ArcVoiceItemMatch? findBest(String query) {
    final normalized = UnifiedItemIndex.normalize(query);
    if (normalized.isEmpty) return null;

    ArcVoiceItemRecord? best;
    var bestScore = 0;
    for (final item in allItems) {
      final score = _score(item, normalized);
      if (score > bestScore) {
        best = item;
        bestScore = score;
      }
    }

    if (best == null || bestScore < 58) return null;
    return ArcVoiceItemMatch(best, bestScore);
  }

  static List<ArcVoiceItemRecord> search(String query, {int limit = 20}) {
    final normalized = UnifiedItemIndex.normalize(query);
    if (normalized.isEmpty) return const <ArcVoiceItemRecord>[];
    final matches = <ArcVoiceItemMatch>[];
    for (final item in allItems) {
      final score = _score(item, normalized);
      if (score > 0) matches.add(ArcVoiceItemMatch(item, score));
    }
    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches.take(limit).map((m) => m.item).toList(growable: false);
  }

  static int _score(ArcVoiceItemRecord item, String normalizedQuery) {
    final candidates = <String>{
      UnifiedItemIndex.normalize(item.name),
      UnifiedItemIndex.normalize(item.name.replaceAll(' Blueprint', '')),
      for (final alias in item.aliases) UnifiedItemIndex.normalize(alias),
    }..removeWhere((value) => value.isEmpty);

    var best = 0;
    final queryTokens = normalizedQuery
        .split(' ')
        .where((t) => t.isNotEmpty)
        .toSet();
    for (final candidate in candidates) {
      if (candidate == normalizedQuery) best = best < 100 ? 100 : best;
      if (candidate.contains(normalizedQuery) ||
          normalizedQuery.contains(candidate)) {
        best = best < 88 ? 88 : best;
      }
      final candidateTokens = candidate
          .split(' ')
          .where((t) => t.isNotEmpty)
          .toSet();
      if (candidateTokens.isEmpty || queryTokens.isEmpty) continue;
      final overlap = candidateTokens.intersection(queryTokens).length;
      final tokenScore = ((overlap / candidateTokens.length) * 78).round();
      if (tokenScore > best) best = tokenScore;
    }
    return best;
  }

  static ArcVoiceItemAction _actionFromUnified(UnifiedItemEntry item) {
    final n = UnifiedItemIndex.normalize(item.name);
    if (n.contains('blueprint')) return ArcVoiceItemAction.learn;
    if (item.neededForBench || item.neededForQuest || item.neededForScrappy) {
      return ArcVoiceItemAction.keep;
    }
    if (_looksLikeKey(n)) return ArcVoiceItemAction.trade;
    if (_looksLikeUseItem(n)) return ArcVoiceItemAction.use;
    if (_looksLikeRecycle(n)) return ArcVoiceItemAction.recycle;
    if (_looksLikeSell(n)) return ArcVoiceItemAction.sell;
    if (item.tradeRelevant) return ArcVoiceItemAction.trade;
    return ArcVoiceItemAction.check;
  }

  static String _categoryFromUnified(UnifiedItemEntry item) {
    final n = UnifiedItemIndex.normalize(item.name);
    if (n.contains('blueprint')) return 'Blueprint';
    if (_looksLikeKey(n)) return 'Key';
    if (_looksLikeUseItem(n)) return 'Quick Use / Gear';
    if (_looksLikeRecycle(n)) return 'Recyclable';
    if (_looksLikeSell(n)) return 'Trinket';
    if (item.neededForBench || item.neededForQuest || item.neededForScrappy) {
      return 'Progression Material';
    }
    return 'Item';
  }

  static String _summaryFromUnified(UnifiedItemEntry item) {
    final usage = item.usedIn.isEmpty
        ? 'No tracker usage mapped yet.'
        : 'Mapped to: ${item.usedIn.join(', ')}.';
    switch (_actionFromUnified(item)) {
      case ArcVoiceItemAction.keep:
        return 'Progression-linked item. Keep until your tracker confirms you have enough. $usage';
      case ArcVoiceItemAction.sell:
        return 'Value/trinket-style item. Usually safe to sell unless you personally want to keep it. $usage';
      case ArcVoiceItemAction.recycle:
        return 'Salvage-style item. Usually better recycled for materials unless trade demand is active. $usage';
      case ArcVoiceItemAction.trade:
        return 'Trade-aware item. Check demand before selling because another Raider may want it. $usage';
      case ArcVoiceItemAction.learn:
        return 'Blueprint item. Learn it if missing; keep duplicate copies for trading before selling. $usage';
      case ArcVoiceItemAction.use:
        return 'Usable item or gear. Keep if you will run it; trade or sell spare stock. $usage';
      case ArcVoiceItemAction.check:
        return 'Recognised item, but it needs manual checking until more tracker data is available. $usage';
    }
  }

  static bool _looksLikeKey(String n) =>
      n.contains(' key') ||
      n.endsWith('key') ||
      n.contains('security code') ||
      n.contains('access card') ||
      n.contains('keycard');
  static bool _looksLikeUseItem(String n) => <String>[
    'shot',
    'bandage',
    'grenade',
    'mine',
    'trap',
    'ammo',
    'shield',
    'augment',
    'stock',
    'grip',
    'silencer',
    'compensator',
    'choke',
    'mag',
    'barrel',
    'zipline',
    'binoculars',
    'flag',
    'guitar',
    'recorder',
    'shaker',
    'light stick',
    'descender',
    'snap hook',
  ].any(n.contains);
  static bool _looksLikeRecycle(String n) => <String>[
    'broken',
    'burned',
    'burnt',
    'cracked',
    'damaged',
    'degraded',
    'deflated',
    'dried out',
    'impure',
    'polluted',
    'ripped',
    'ruined',
    'rusty',
    'tattered',
    'torn',
    'unusable',
    'pump',
    'fan',
    'coil',
    'radio',
    'scanner',
    'filter',
    'relay',
    'controller',
    'thermostat',
    'compressor',
    'processor',
    'projector',
    'microscope',
    'headphones',
    'battery',
  ].any(n.contains);
  static bool _looksLikeSell(String n) => <String>[
    'duck',
    'jewelry',
    'jewellery',
    'vase',
    'statuette',
    'pottery',
    'poster',
    'photograph',
    'album',
    'mixtape',
    'books',
    'book',
    'card',
    'tapes',
    'wristwatch',
    'teaspoon',
    'snow globe',
    'ship model',
    'business card',
    'patch',
    'note',
    'documentation',
    'rations',
  ].any(n.contains);

  static final List<ArcVoiceItemRecord> allItems = <ArcVoiceItemRecord>[
    ..._manualItems,
    for (final item in UnifiedItemIndex.items)
      if (!_manualNames.contains(item.name))
        ArcVoiceItemRecord(
          name: item.name,
          rarity: 'Unknown',
          category: _categoryFromUnified(item),
          action: _actionFromUnified(item),
          summary: _summaryFromUnified(item),
          aliases: item.aliases,
        ),
  ];

  static final Set<String> _manualNames = _manualItems
      .map((item) => item.name)
      .toSet();

  static const List<ArcVoiceItemRecord> _manualItems = <ArcVoiceItemRecord>[
    ArcVoiceItemRecord(
      name: 'Acoustic Guitar',
      rarity: 'Legendary',
      category: 'Quick Use',
      action: ArcVoiceItemAction.keep,
      summary:
          'Playable distraction item; useful for noise, attention control, and Raider flair.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Adrenaline Shot',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.keep,
      summary:
          'Stamina recovery serum. Keep if you need stamina support during raids.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Advanced ARC Powercell',
      rarity: 'Rare',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Valuable ARC enemy resource. Keep for progression and trading.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Advanced Electrical Components',
      rarity: 'Rare',
      category: 'Refined Material',
      action: ArcVoiceItemAction.keep,
      summary:
          'Advanced crafting component used across high-tier augments. Keep until upgrade needs are covered.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Advanced Mechanical Components',
      rarity: 'Rare',
      category: 'Refined Material',
      action: ArcVoiceItemAction.keep,
      summary:
          'Advanced weapon crafting component. Keep for weapon progression.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Agave',
      rarity: 'Uncommon',
      category: 'Nature',
      action: ArcVoiceItemAction.keep,
      summary:
          'Consumable plant item for small health recovery. Keep if you need healing supplies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Agave Juice',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.keep,
      summary:
          'Stamina regeneration drink with a small health trade-off. Use or keep for raids.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Antiseptic',
      rarity: 'Rare',
      category: 'Refined Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Medical crafting component. Keep for healing item production.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Apricot',
      rarity: 'Uncommon',
      category: 'Nature',
      action: ArcVoiceItemAction.keep,
      summary: 'Consumable fruit that restores a small amount of stamina.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'ARC Alloy',
      rarity: 'Uncommon',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary: 'ARC material used to craft components. Keep for progression.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'ARC Circuitry',
      rarity: 'Rare',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary:
          'ARC component used in advanced crafting. Keep or trade only if surplus.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'ARC Coolant',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary:
          'ARC salvage that can break down into chemicals. Keep unless you need recycle outputs.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'ARC Flex Rubber',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary:
          'Useful ARC salvage. Keep until rubber/material needs are covered.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'ARC Motion Core',
      rarity: 'Rare',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary: 'ARC component used in advanced crafting. Keep for progression.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'ARC Performance Steel',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary:
          'High-grade ARC salvage. Keep unless you specifically need recycle output.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'ARC Powercell',
      rarity: 'Common',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary:
          'Common ARC drop used for shields and repairs. Keep a working stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'ARC Synthetic Resin',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare ARC salvage. Keep for crafting/material demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'ARC Thermo Lining',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary:
          'Rare ARC salvage. Keep unless trade/recycle needs say otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Assessor Matrix',
      rarity: 'Epic',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary:
          'Epic ARC salvage. Keep due to rarity and trade/progression value.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Bastion Cell',
      rarity: 'Epic',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary:
          'Epic ARC part. Keep; only recycle when you know the material output is needed.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Battery',
      rarity: 'Uncommon',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary:
          'Crafting material used in several items. Keep until stock is safe.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Bombardier Cell',
      rarity: 'Epic',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Epic ARC part. Keep for rare material/trade value.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Breathtaking Snow Globe',
      rarity: 'Epic',
      category: 'Trinket',
      action: ArcVoiceItemAction.keep,
      summary:
          'High-rarity collectible trinket. Keep if collecting, otherwise check trade/sell value.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Camera Lens',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Useful salvage item. Keep if tracker or recycle needs apply.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Candle Holder',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'General salvage. Keep if material demand is active.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Candleberries',
      rarity: 'Rare',
      category: 'Nature',
      action: ArcVoiceItemAction.keep,
      summary:
          'Rare natural resource. Keep for food/medicine-style progression value.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Canister',
      rarity: 'Uncommon',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary:
          'Crafting material for weapons and utility. Keep a working stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Cat Bed',
      rarity: 'Uncommon',
      category: 'Trinket',
      action: ArcVoiceItemAction.keep,
      summary:
          'Comfort item with tracker value in this app. Keep unless surplus.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Celeste\'s Journal',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.keep,
      summary:
          'Named lore/trinket item. Keep if quest/collection value matters.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Chemicals',
      rarity: 'Common',
      category: 'Basic Material',
      action: ArcVoiceItemAction.keep,
      summary:
          'Core crafting material for ammo, meds, explosives, and utility. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Coffee Pot',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.keep,
      summary:
          'Quest/tracker-linked trinket in this app. Keep until requirements are covered.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Complex Gun Parts',
      rarity: 'Epic',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary:
          'Advanced weapon parts. Keep or trade; only sell if you are sure it is surplus.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Crude Explosives',
      rarity: 'Uncommon',
      category: 'Refined Material',
      action: ArcVoiceItemAction.keep,
      summary:
          'Explosive crafting material. Keep for grenade/mine progression.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Durable Cloth',
      rarity: 'Uncommon',
      category: 'Refined Material',
      action: ArcVoiceItemAction.keep,
      summary:
          'Medical crafting material. Keep for bandages and healing supplies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Electrical Components',
      rarity: 'Uncommon',
      category: 'Refined Material',
      action: ArcVoiceItemAction.keep,
      summary: 'General electronics crafting component. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Exodus Modules',
      rarity: 'Epic',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary:
          'Epic crafting component for several high-value weapons/items. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Explosive Compound',
      rarity: 'Rare',
      category: 'Refined Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare explosive crafting material. Keep for mines and grenades.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Fabric',
      rarity: 'Common',
      category: 'Basic Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Basic material for medical supplies and shields. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Fertilizer',
      rarity: 'Uncommon',
      category: 'Nature',
      action: ArcVoiceItemAction.keep,
      summary:
          'Nature item with possible sell value. Keep if a tracker needs it; otherwise sell surplus.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Film Reel',
      rarity: 'Rare',
      category: 'Trinket',
      action: ArcVoiceItemAction.keep,
      summary:
          'Rare trinket. Keep if collector/tracker value applies; otherwise sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Fine Wristwatch',
      rarity: 'Rare',
      category: 'Trinket',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare value trinket. Keep if collecting; otherwise sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Fireball Burner',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary:
          'ARC salvage that can become ARC Alloy. Keep if you need ARC materials.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Firefly Burner',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare ARC salvage. Keep for material/trade value.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'First Wave Compass',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.keep,
      summary: 'Old-world keepsake. Keep if collection/tracker value matters.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'First Wave Rations',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.keep,
      summary:
          'Old-world supply item. Keep if tracker/collection value matters.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'First Wave Tape',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.keep,
      summary: 'Old media item. Keep if tracker/collection value matters.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Flow Controller',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare salvage. Keep if material demand is active.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Frequency Modulation Box',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary:
          'Rare electronics salvage. Keep unless recycle output is needed.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Fried Motherboard',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary:
          'Rare electronics salvage. Keep if materials or trade demand matter.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Frying Pan',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare salvage item. Keep if tracker/material demand applies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Geiger Counter',
      rarity: 'Epic',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Epic salvage. Keep for rarity and trade/material value.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Great Mullein',
      rarity: 'Uncommon',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Medical crafting plant. Keep for healing item production.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Heavy Gun Parts',
      rarity: 'Rare',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary:
          'Weapon crafting parts. Keep if building heavy weapons; sell only surplus.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Hornet Driver',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'ARC salvage/utility item. Keep for trade or material value.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Humidifier',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare salvage. Keep if material demand applies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Industrial Battery',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Large power component. Keep for material/trade value.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Industrial Charger',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare salvage. Keep if material demand applies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Ion Sputter',
      rarity: 'Epic',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Epic salvage. Keep due to rarity.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Laboratory Reagents',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare chemical salvage. Keep for material needs.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Leaper Pulse Unit',
      rarity: 'Epic',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Epic ARC salvage with utility value. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Lemon',
      rarity: 'Uncommon',
      category: 'Nature',
      action: ArcVoiceItemAction.keep,
      summary: 'Consumable stamina item. Keep or use.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: '"Leviathan\'s Crown" Ship Model',
      rarity: 'Legendary',
      category: 'Trinket',
      action: ArcVoiceItemAction.keep,
      summary: 'Legendary collectible. Keep or check high trade/sell value.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Light Bulb',
      rarity: 'Uncommon',
      category: 'Trinket',
      action: ArcVoiceItemAction.keep,
      summary: 'Small trinket with possible tracker value. Keep if needed.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Magnetic Accelerator',
      rarity: 'Epic',
      category: 'Refined Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Epic advanced weapon material. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Magnetron',
      rarity: 'Epic',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Epic electronics salvage. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Matriarch Reactor',
      rarity: 'Legendary',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Legendary ARC salvage. Keep; do not casually recycle or sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Mechanical Components',
      rarity: 'Uncommon',
      category: 'Refined Material',
      action: ArcVoiceItemAction.keep,
      summary: 'General mechanical crafting component. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Metal Parts',
      rarity: 'Common',
      category: 'Basic Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Core crafting material. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Moss',
      rarity: 'Rare',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Healing nature item. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Motor',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare mechanical salvage. Keep if material demand applies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Mushroom',
      rarity: 'Uncommon',
      category: 'Nature',
      action: ArcVoiceItemAction.keep,
      summary: 'Consumable healing item. Keep or use.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Music Album',
      rarity: 'Rare',
      category: 'Trinket',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare trinket. Keep if collecting; otherwise check sell value.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Oil',
      rarity: 'Uncommon',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Crafting material for weapons and explosives. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Olives',
      rarity: 'Uncommon',
      category: 'Nature',
      action: ArcVoiceItemAction.keep,
      summary: 'Consumable stamina item. Keep or use.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Plastic Parts',
      rarity: 'Common',
      category: 'Basic Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Core crafting material. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Pop Trigger',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Useful salvage. Keep if material demand applies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Portable TV',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare salvage item. Keep if material/trade demand applies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Power Cable',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare electrical salvage. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Power Rod',
      rarity: 'Epic',
      category: 'Refined Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Epic crafting component. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Prickly Pear',
      rarity: 'Common',
      category: 'Nature',
      action: ArcVoiceItemAction.keep,
      summary: 'Consumable stamina item. Keep or use.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Queen Reactor',
      rarity: 'Legendary',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Legendary ARC salvage. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Red Coral Jewelry',
      rarity: 'Rare',
      category: 'Trinket',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare value item. Keep if collecting; otherwise sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Rocketeer Driver',
      rarity: 'Epic',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Epic ARC salvage. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Roots',
      rarity: 'Uncommon',
      category: 'Nature',
      action: ArcVoiceItemAction.keep,
      summary: 'Nature item. Keep if needed; sell surplus.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Rubber Parts',
      rarity: 'Common',
      category: 'Basic Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Core crafting material. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Rusted Bolts',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Metal salvage. Keep if metal parts are needed.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Rusted Gear',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare mechanical salvage. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Rusted Shut Medical Kit',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare medical salvage. Keep for progression/material value.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Rusted Tools',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare tool salvage. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Sensors',
      rarity: 'Rare',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare crafting component used in utilities. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Sentinel Firing Core',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare ARC salvage. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Shredder Gyro',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare salvage. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Snitch Scanner',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary:
          'ARC salvage that can call in ARC and recycle to alloy. Keep if useful.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Speaker Component',
      rarity: 'Rare',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare crafting component. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Spotter Relay',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Useful ARC salvage. Keep if material demand applies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Steel Spring',
      rarity: 'Uncommon',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Crafting material for mags and weapons. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Surveyor Vault',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare salvage. Keep if material demand applies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Synthesized Fuel',
      rarity: 'Rare',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare fuel component. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Syringe',
      rarity: 'Rare',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Medical crafting component. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tick Pod',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'ARC salvage. Keep if material demand applies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Toaster',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare salvage. Keep if material demand applies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Turbine Compressor',
      rarity: 'Epic',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Epic salvage. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: '"Twilight Compass" Ship Model',
      rarity: 'Uncommon',
      category: 'Trinket',
      action: ArcVoiceItemAction.keep,
      summary: 'Collectible ship model. Keep if collecting; otherwise sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Vaporizer Regulator',
      rarity: 'Epic',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Epic salvage. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: '"Velocity" Ship Model',
      rarity: 'Rare',
      category: 'Trinket',
      action: ArcVoiceItemAction.keep,
      summary:
          'Rare collectible ship model. Keep if collecting; otherwise sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Very Comfortable Pillow',
      rarity: 'Uncommon',
      category: 'Trinket',
      action: ArcVoiceItemAction.keep,
      summary: 'Comfort collectible. Keep if collecting or tracker needs it.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Voltage Converter',
      rarity: 'Rare',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare crafting component. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Wasp Driver',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'ARC salvage with utility value. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Water Filter',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare survival salvage. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Water Pump',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.keep,
      summary: 'Rare salvage. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Wires',
      rarity: 'Uncommon',
      category: 'Topside Material',
      action: ArcVoiceItemAction.keep,
      summary: 'Crafting material for traps and mods. Keep.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Air Freshener',
      rarity: 'Uncommon',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Low-priority trinket. Usually safe to sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Alien Duck',
      rarity: 'Uncommon',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary:
          'Throwable noise trinket. Sell unless you want it for distraction fun.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Assorted Seeds',
      rarity: 'Common',
      category: 'Nature',
      action: ArcVoiceItemAction.sell,
      summary:
          'Common nature/trinket item. Sell unless a quest/tracker asks for it.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Bloated Tuna Can',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Low-value consumable trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Burnt-Out Candles',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common trinket. Usually safe to sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Dart Board',
      rarity: 'Uncommon',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Trinket item. Usually sell unless collecting.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Dodger\'s Note',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Note/trinket item. Usually sell unless quest-linked.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Doodly Duck',
      rarity: 'Rare',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Rare duck trinket. Sell unless collecting or using as noise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Dusty Film Reel',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Espresso Machine Parts',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common trinket-style parts. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'ESR Analyzer',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common trinket. Usually sell unless quest-linked.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Experimental Seed Sample',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common research trinket. Usually sell unless quest-linked.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Expired Pasta',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common trinket/poor consumable. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Expired Security Code',
      rarity: 'Common',
      category: 'Key',
      action: ArcVoiceItemAction.sell,
      summary: 'Expired code with no practical use. Sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Faded Photograph',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common keepsake trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Familiar Duck',
      rarity: 'Epic',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary:
          'Epic duck trinket. Sell if you want coins; keep only if collecting.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Flashy Duck',
      rarity: 'Rare',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Rare duck trinket. Sell unless collecting or using as noise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Flushing Terminal Key',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary:
          'Quest-related trinket/key. Sell only if the quest use is finished.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Gentle Duck',
      rarity: 'Uncommon',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary:
          'Duck trinket. Usually sell unless collecting or using as noise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Lance\'s Mixtape (5th Edition)',
      rarity: 'Epic',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Epic value trinket. Usually sell unless collecting.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Lidar Scanner',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common scanner trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Major Aiva\'s Mementos',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common lore trinket. Usually sell unless collecting.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Major Aiva\'s Patch',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common patch trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Marano Market Business Card',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Moisture Meter',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary:
          'Quest item for Unexpected Initiative. Sell only after quest use is complete.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Music Box',
      rarity: 'Rare',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Rare value trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Nutrient Meter',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary:
          'Quest item for Unexpected Initiative. Sell only after quest use is complete.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Official Shutdown Documentation',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common document trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Old World Books',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common books/trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Painted Box',
      rarity: 'Uncommon',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Uncommon trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Playing Cards',
      rarity: 'Rare',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Rare trinket. Usually sell unless collecting.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Possibly Toxic Plant',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common questionable plant trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Poster of Natural Wonders',
      rarity: 'Uncommon',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Uncommon trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Pottery',
      rarity: 'Uncommon',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Uncommon value trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Precision Gimbal',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Project Heartwood Blueprints',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary:
          'Common old blueprint trinket. Usually sell unless quest-linked.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Raider Flag',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Resin',
      rarity: 'Common',
      category: 'Nature',
      action: ArcVoiceItemAction.sell,
      summary:
          'Common nature item with light healing value. Sell if not needed.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Rosary',
      rarity: 'Rare',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Rare trinket. Usually sell unless collecting.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Rubber Duck',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common duck trinket. Usually sell unless using as noise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Scout Patrol Note',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common note trinket. Usually sell unless quest-linked.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Secret Meeting Info',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common info trinket. Usually sell unless quest-linked.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Silver Teaspoon Set',
      rarity: 'Rare',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Rare value trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Stack of Movie Tapes',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Statuette',
      rarity: 'Rare',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Rare value trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Torn Book',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common book trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tropical Duck',
      rarity: 'Uncommon',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary:
          'Duck trinket. Usually sell unless collecting or using as noise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Vase',
      rarity: 'Rare',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Rare value trinket. Usually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: '"Wind Sprite" Ship Model',
      rarity: 'Common',
      category: 'Trinket',
      action: ArcVoiceItemAction.sell,
      summary: 'Common ship model trinket. Usually sell unless collecting.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Alarm Clock',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Bicycle Pump',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Broken Flashlight',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Broken Handheld Radio',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Broken Taser',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Burned Arc Circuitry',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Coolant',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Crumpled Plastic Bottle',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Damaged ARC Motion Core',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Damaged ARC Powercell',
      rarity: 'Common',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Damaged Fireball Burner',
      rarity: 'Common',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Damaged Hornet Driver',
      rarity: 'Common',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Damaged Rocketeer Driver',
      rarity: 'Common',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Damaged Tick Pod',
      rarity: 'Common',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Damaged Wasp Driver',
      rarity: 'Common',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Deflated Football',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Degraded ARC Rubber',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Diving Goggles',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Dried-Out ARC Resin',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Fossilized Lightning',
      rarity: 'Epic',
      category: 'Topside Material',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Garlic Press',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Headphones',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Household Cleaner',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Ice Cream Scooper',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Impure ARC Coolant',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Industrial Magnet',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Magnet',
      rarity: 'Uncommon',
      category: 'Topside Material',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Metal Brackets',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Microscope',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Mini Centrifuge',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Mod Components',
      rarity: 'Rare',
      category: 'Refined Material',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Number Plate',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Polluted Air Filter',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Power Bank',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Processor',
      rarity: 'Rare',
      category: 'Topside Material',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Projector',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Radio',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Radio Relay',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Rocket Thruster',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Rope',
      rarity: 'Rare',
      category: 'Topside Material',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Rotary Encoder',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Rubber Pad',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Ruined Accordion',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Ruined Augment',
      rarity: 'Common',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Ruined Baton',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Ruined Handcuffs',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Ruined Parachute',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Ruined Riot Shield',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Ruined Tactical Vest',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Rusty ARC Steel',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Sample Cleaner',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Signal Amplifier',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Simple Gun Parts',
      rarity: 'Uncommon',
      category: 'Topside Material',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Spectrometer',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Spectrum Analyzer',
      rarity: 'Epic',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Spring Cushion',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tattered Arc Lining',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tattered Clothes',
      rarity: 'Uncommon',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Telemetry Transceiver',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Thermostat',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Torn Blanket',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Turbo Pump',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Unusable Weapon',
      rarity: 'Rare',
      category: 'Recyclable',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Recycle candidate. Break it down for crafting materials unless active trade demand says otherwise.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Ancient Fort Security Code',
      rarity: 'Common',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Blue Gate Cellar Key',
      rarity: 'Rare',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Blue Gate Communication Tower Key',
      rarity: 'Rare',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Blue Gate Confiscation Room Key',
      rarity: 'Epic',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Blue Gate Village Key',
      rarity: 'Uncommon',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Buried City Hospital Key',
      rarity: 'Rare',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Buried City JKV Employee Access Card',
      rarity: 'Uncommon',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Buried City Residential Master Key',
      rarity: 'Uncommon',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Buried City Town Hall Key',
      rarity: 'Epic',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Dam Control Tower Key',
      rarity: 'Epic',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Dam Controlled Access Zone Key',
      rarity: 'Epic',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Dam Staff Room Key',
      rarity: 'Uncommon',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Dam Surveillance Key',
      rarity: 'Uncommon',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Dam Testing Annex Key',
      rarity: 'Rare',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Hidden Bunker Key',
      rarity: 'Common',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Patrol Car Key',
      rarity: 'Uncommon',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Pilgrim\'s Peak Security Code',
      rarity: 'Common',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Raider Hatch Key',
      rarity: 'Rare',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Raider\'s Refuge Security Code',
      rarity: 'Common',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Reinforced Reception Security Code',
      rarity: 'Common',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Riven Tides Classifed Records Keycard',
      rarity: 'Uncommon',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Riven Tides Classified Records Keycard',
      rarity: 'Uncommon',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Riven Tides Crane House Keycard',
      rarity: 'Common',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Riven Tides Hotel Keycard No. 102',
      rarity: 'Common',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Riven Tides Hotel Keycard No. 107',
      rarity: 'Common',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Riven Tides Hotel Keycard No. 113',
      rarity: 'Common',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Riven Tides Hotel Keycard No. 205',
      rarity: 'Common',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Riven Tides Hotel Keycard No. 208',
      rarity: 'Common',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Riven Tides Hotel Keycard No. 311',
      rarity: 'Common',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Riven Tides Hotel Keycard No. 404',
      rarity: 'Common',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Riven Tides Secure Storage Keycard',
      rarity: 'Epic',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Seed Vault Box Key',
      rarity: 'Common',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Spaceport Container Storage Key',
      rarity: 'Rare',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Spaceport Control Tower Key',
      rarity: 'Rare',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Spaceport Trench Tower Key',
      rarity: 'Uncommon',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Spaceport Warehouse Key',
      rarity: 'Uncommon',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Stella Montis Archives Key',
      rarity: 'Epic',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Stella Montis Assembly Admin Key',
      rarity: 'Uncommon',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Stella Montis Medical Storage Key',
      rarity: 'Uncommon',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Stella Montis Security Checkpoint Key',
      rarity: 'Rare',
      category: 'Key',
      action: ArcVoiceItemAction.trade,
      summary:
          'Access item. Keep for locked areas or trade value; do not recycle.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Bandage',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Barricade Kit',
      rarity: 'Uncommon',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Binoculars',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Blaze Grenade',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Blaze Grenade Trap',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Blue Light Stick',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Crash Mat',
      rarity: 'Uncommon',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Deadline',
      rarity: 'Epic',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Defibrillator',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Dockmaster\'s Detector',
      rarity: 'Uncommon',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Door Blocker',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Energy Clip',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Explosive Mine',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Firecracker',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Fireworks Box',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Flame Spray',
      rarity: 'Uncommon',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Fruit Mix',
      rarity: 'Uncommon',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Gas Grenade',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Gas Grenade Trap',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Gas Mine',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Green Light Stick',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Heavy Ammo',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Heavy Fuze Grenade',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Jolt Mine',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Launcher Ammo',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Light Ammo',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Light Impact Grenade',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Li\'l Smoke Grenade',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Lure Grenade',
      rarity: 'Uncommon',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Lure Grenade Trap',
      rarity: 'Uncommon',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Medium Ammo',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Noisemaker',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Photoelectric Cloak',
      rarity: 'Epic',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Powered Descender',
      rarity: 'Epic',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Pulse Mine',
      rarity: 'Uncommon',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Recorder',
      rarity: 'Uncommon',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Red Light Stick',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Remote Raider Flare',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Seeker Grenade',
      rarity: 'Uncommon',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Shaker',
      rarity: 'Uncommon',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Shield Recharger',
      rarity: 'Uncommon',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Shotgun Ammo',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Showstopper',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Shrapnel Grenade',
      rarity: 'Uncommon',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Smoke Grenade',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Smoke Grenade Trap',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Snap Blast Grenade',
      rarity: 'Uncommon',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Snap Hook',
      rarity: 'Legendary',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Snowball',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Sterilized Bandage',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Surge Coil',
      rarity: 'Uncommon',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Surge Shield Recharger',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tagging Grenade',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Trailblazer',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Trigger \'Nade',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Vita Shot',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Vita Spray',
      rarity: 'Epic',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Volcanic Rock',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'White Flag',
      rarity: 'Uncommon',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Wolfpack',
      rarity: 'Epic',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Yellow Light Stick',
      rarity: 'Common',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Zipline',
      rarity: 'Rare',
      category: 'Quick Use',
      action: ArcVoiceItemAction.use,
      summary:
          'Usable raid item. Keep if you will run it; trade or sell spare stock.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Anvil I',
      rarity: 'Uncommon',
      category: 'Hand Cannon',
      action: ArcVoiceItemAction.use,
      summary:
          'Anvil weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Anvil II',
      rarity: 'Uncommon',
      category: 'Hand Cannon',
      action: ArcVoiceItemAction.use,
      summary:
          'Anvil weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Anvil III',
      rarity: 'Uncommon',
      category: 'Hand Cannon',
      action: ArcVoiceItemAction.use,
      summary:
          'Anvil weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Anvil IV',
      rarity: 'Uncommon',
      category: 'Hand Cannon',
      action: ArcVoiceItemAction.use,
      summary:
          'Anvil weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Arpeggio I',
      rarity: 'Uncommon',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Arpeggio weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Arpeggio II',
      rarity: 'Uncommon',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Arpeggio weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Arpeggio III',
      rarity: 'Uncommon',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Arpeggio weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Arpeggio IV',
      rarity: 'Uncommon',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Arpeggio weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Bettina I',
      rarity: 'Epic',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Bettina weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Bettina II',
      rarity: 'Epic',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Bettina weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Bettina III',
      rarity: 'Epic',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Bettina weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Bettina IV',
      rarity: 'Epic',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Bettina weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Bobcat I',
      rarity: 'Epic',
      category: 'SMG',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Bobcat weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Bobcat II',
      rarity: 'Epic',
      category: 'SMG',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Bobcat weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Bobcat III',
      rarity: 'Epic',
      category: 'SMG',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Bobcat weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Bobcat IV',
      rarity: 'Epic',
      category: 'SMG',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Bobcat weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Burletta I',
      rarity: 'Uncommon',
      category: 'Pistol',
      action: ArcVoiceItemAction.use,
      summary:
          'Burletta weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Burletta II',
      rarity: 'Uncommon',
      category: 'Pistol',
      action: ArcVoiceItemAction.use,
      summary:
          'Burletta weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Burletta III',
      rarity: 'Uncommon',
      category: 'Pistol',
      action: ArcVoiceItemAction.use,
      summary:
          'Burletta weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Burletta IV',
      rarity: 'Uncommon',
      category: 'Pistol',
      action: ArcVoiceItemAction.use,
      summary:
          'Burletta weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Canto I',
      rarity: 'Rare',
      category: 'SMG',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Canto weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Canto II',
      rarity: 'Rare',
      category: 'SMG',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Canto weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Canto III',
      rarity: 'Rare',
      category: 'SMG',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Canto weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Canto IV',
      rarity: 'Rare',
      category: 'SMG',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Canto weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Ferro I',
      rarity: 'Common',
      category: 'Battle Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Ferro weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Ferro II',
      rarity: 'Common',
      category: 'Battle Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Ferro weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Ferro III',
      rarity: 'Common',
      category: 'Battle Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Ferro weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Ferro IV',
      rarity: 'Common',
      category: 'Battle Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Ferro weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Hairpin I',
      rarity: 'Common',
      category: 'Pistol',
      action: ArcVoiceItemAction.use,
      summary:
          'Hairpin weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Hairpin II',
      rarity: 'Common',
      category: 'Pistol',
      action: ArcVoiceItemAction.use,
      summary:
          'Hairpin weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Hairpin III',
      rarity: 'Common',
      category: 'Pistol',
      action: ArcVoiceItemAction.use,
      summary:
          'Hairpin weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Hairpin IV',
      rarity: 'Common',
      category: 'Pistol',
      action: ArcVoiceItemAction.use,
      summary:
          'Hairpin weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Hullcracker I',
      rarity: 'Epic',
      category: 'Special',
      action: ArcVoiceItemAction.use,
      summary:
          'Hullcracker weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Hullcracker II',
      rarity: 'Epic',
      category: 'Special',
      action: ArcVoiceItemAction.use,
      summary:
          'Hullcracker weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Hullcracker III',
      rarity: 'Epic',
      category: 'Special',
      action: ArcVoiceItemAction.use,
      summary:
          'Hullcracker weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Hullcracker IV',
      rarity: 'Epic',
      category: 'Special',
      action: ArcVoiceItemAction.use,
      summary:
          'Hullcracker weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Il Toro I',
      rarity: 'Uncommon',
      category: 'Shotgun',
      action: ArcVoiceItemAction.use,
      summary:
          'Il Toro weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Il Toro II',
      rarity: 'Uncommon',
      category: 'Shotgun',
      action: ArcVoiceItemAction.use,
      summary:
          'Il Toro weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Il Toro III',
      rarity: 'Uncommon',
      category: 'Shotgun',
      action: ArcVoiceItemAction.use,
      summary:
          'Il Toro weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Il Toro IV',
      rarity: 'Uncommon',
      category: 'Shotgun',
      action: ArcVoiceItemAction.use,
      summary:
          'Il Toro weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Kettle I',
      rarity: 'Common',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Kettle weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Kettle II',
      rarity: 'Common',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Kettle weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Kettle III',
      rarity: 'Common',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Kettle weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Kettle IV',
      rarity: 'Common',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Kettle weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Osprey I',
      rarity: 'Rare',
      category: 'Sniper Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Osprey weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Osprey II',
      rarity: 'Rare',
      category: 'Sniper Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Osprey weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Osprey III',
      rarity: 'Rare',
      category: 'Sniper Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Osprey weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Osprey IV',
      rarity: 'Rare',
      category: 'Sniper Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Osprey weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Rattler I',
      rarity: 'Common',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Rattler weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Rattler II',
      rarity: 'Common',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Rattler weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Rattler III',
      rarity: 'Common',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Rattler weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Rattler IV',
      rarity: 'Common',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Rattler weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Renegade I',
      rarity: 'Rare',
      category: 'Battle Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Renegade weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Renegade II',
      rarity: 'Rare',
      category: 'Battle Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Renegade weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Renegade III',
      rarity: 'Rare',
      category: 'Battle Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Renegade weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Renegade IV',
      rarity: 'Rare',
      category: 'Battle Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Renegade weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Stitcher I',
      rarity: 'Common',
      category: 'SMG',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Stitcher weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Stitcher II',
      rarity: 'Common',
      category: 'SMG',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Stitcher weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Stitcher III',
      rarity: 'Common',
      category: 'SMG',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Stitcher weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Stitcher IV',
      rarity: 'Common',
      category: 'SMG',
      action: ArcVoiceItemAction.recycle,
      summary:
          'Stitcher weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tempest I',
      rarity: 'Epic',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Tempest weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tempest II',
      rarity: 'Epic',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Tempest weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tempest III',
      rarity: 'Epic',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Tempest weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tempest IV',
      rarity: 'Epic',
      category: 'Assault Rifle',
      action: ArcVoiceItemAction.use,
      summary:
          'Tempest weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Torrente I',
      rarity: 'Rare',
      category: 'LMG',
      action: ArcVoiceItemAction.use,
      summary:
          'Torrente weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Torrente II',
      rarity: 'Rare',
      category: 'LMG',
      action: ArcVoiceItemAction.use,
      summary:
          'Torrente weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Torrente III',
      rarity: 'Rare',
      category: 'LMG',
      action: ArcVoiceItemAction.use,
      summary:
          'Torrente weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Torrente IV',
      rarity: 'Rare',
      category: 'LMG',
      action: ArcVoiceItemAction.use,
      summary:
          'Torrente weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Venator I',
      rarity: 'Rare',
      category: 'Pistol',
      action: ArcVoiceItemAction.use,
      summary:
          'Venator weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Venator II',
      rarity: 'Rare',
      category: 'Pistol',
      action: ArcVoiceItemAction.use,
      summary:
          'Venator weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Venator III',
      rarity: 'Rare',
      category: 'Pistol',
      action: ArcVoiceItemAction.use,
      summary:
          'Venator weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Venator IV',
      rarity: 'Rare',
      category: 'Pistol',
      action: ArcVoiceItemAction.use,
      summary:
          'Venator weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Vulcano I',
      rarity: 'Epic',
      category: 'Shotgun',
      action: ArcVoiceItemAction.use,
      summary:
          'Vulcano weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Vulcano II',
      rarity: 'Epic',
      category: 'Shotgun',
      action: ArcVoiceItemAction.use,
      summary:
          'Vulcano weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Vulcano III',
      rarity: 'Epic',
      category: 'Shotgun',
      action: ArcVoiceItemAction.use,
      summary:
          'Vulcano weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Vulcano IV',
      rarity: 'Epic',
      category: 'Shotgun',
      action: ArcVoiceItemAction.use,
      summary:
          'Vulcano weapon. Keep if you will run it; recycle/sell/trade spare copies based on demand.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Aphelion',
      rarity: 'Legendary',
      category: 'Special',
      action: ArcVoiceItemAction.use,
      summary: 'Legendary weapon. Keep or trade; do not casually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Dolabra',
      rarity: 'Legendary',
      category: 'Shotgun',
      action: ArcVoiceItemAction.use,
      summary: 'Legendary weapon. Keep or trade; do not casually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Equalizer',
      rarity: 'Legendary',
      category: 'LMG',
      action: ArcVoiceItemAction.use,
      summary: 'Legendary weapon. Keep or trade; do not casually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Jupiter',
      rarity: 'Legendary',
      category: 'Sniper Rifle',
      action: ArcVoiceItemAction.use,
      summary: 'Legendary weapon. Keep or trade; do not casually sell.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Combat Mk. 1',
      rarity: 'Uncommon',
      category: 'Augment',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Combat Mk. 2',
      rarity: 'Rare',
      category: 'Augment',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Combat Mk. 3 (Aggressive)',
      rarity: 'Epic',
      category: 'Augment',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Combat Mk. 3 (Flanking)',
      rarity: 'Epic',
      category: 'Augment',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Free Loadout Augment',
      rarity: 'Common',
      category: 'Augment',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Looting Mk. 1',
      rarity: 'Uncommon',
      category: 'Augment',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Looting Mk. 2',
      rarity: 'Rare',
      category: 'Augment',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Looting Mk. 3 (Cautious)',
      rarity: 'Epic',
      category: 'Augment',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Looting Mk. 3 (Safekeeper)',
      rarity: 'Epic',
      category: 'Augment',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Looting Mk. 3 (Survivor)',
      rarity: 'Epic',
      category: 'Augment',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tactical Mk. 1',
      rarity: 'Uncommon',
      category: 'Augment',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tactical Mk. 2',
      rarity: 'Rare',
      category: 'Augment',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tactical Mk. 3 (Defensive)',
      rarity: 'Epic',
      category: 'Augment',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tactical Mk. 3 (Healing)',
      rarity: 'Epic',
      category: 'Augment',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tactical Mk. 3 (Revival)',
      rarity: 'Epic',
      category: 'Augment',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tactical Mk. 3 (Smoke)',
      rarity: 'Epic',
      category: 'Augment',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Light Shield',
      rarity: 'Uncommon',
      category: 'Shield',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Medium Shield',
      rarity: 'Rare',
      category: 'Shield',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Heavy Shield',
      rarity: 'Epic',
      category: 'Shield',
      action: ArcVoiceItemAction.use,
      summary:
          'Gear item. Keep if useful for your build; trade or recycle/sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Angled Grip I',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Angled Grip II',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Angled Grip III',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Anvil Splitter',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Compensator I',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Compensator II',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Compensator III',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Extended Barrel',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Extended Light Mag I',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Extended Light Mag II',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Extended Light Mag III',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Extended Medium Mag I',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Extended Medium Mag II',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Extended Medium Mag III',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Extended Shotgun Mag I',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Extended Shotgun Mag II',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Extended Shotgun Mag III',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Horizontal Grip',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Kinetic Converter',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Lightweight Stock',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Muzzle Brake I',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Muzzle Brake II',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Muzzle Brake III',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Padded Stock',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Shotgun Choke I',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Shotgun Choke II',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Shotgun Choke III',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Shotgun Silencer',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Silencer I',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Silencer II',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Silencer III',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Stable Stock I',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Stable Stock II',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Stable Stock III',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Vertical Grip I',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Vertical Grip II',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Vertical Grip III',
      rarity: 'Unknown',
      category: 'Modification',
      action: ArcVoiceItemAction.use,
      summary:
          'Weapon modification. Keep if it fits your build; trade or sell spare copies.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Angled Grip II Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Angled Grip III Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Anvil Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Aphelion Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Barricade Kit Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Bettina Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Blaze Grenade Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Blue Light Stick Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Bobcat Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Burletta Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Canto Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Combat Mk. 3 (Aggressive) Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Combat Mk. 3 (Flanking) Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Compensator II Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Compensator III Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Complex Gun Parts Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Crash Mat Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Deadline Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Defibrillator Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Dolabra Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Equalizer Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Explosive Mine Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Extended Barrel Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Extended Light Mag II Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Extended Light Mag III Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Extended Medium Mag II Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Extended Medium Mag III Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Extended Shotgun Mag II Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Extended Shotgun Mag III Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Fireworks Box Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Gas Mine Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Green Light Stick Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Heavy Gun Parts Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Hullcracker Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Il Toro Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Jolt Mine Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Jupiter Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Light Gun Parts Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Lightweight Stock Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Looting Mk. 3 (Safekeeper) Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Looting Mk. 3 (Survivor) Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Lure Grenade Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Medium Gun Parts Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Muzzle Brake II Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Muzzle Brake III Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Osprey Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Padded Stock Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Powered Descender Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Pulse Mine Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Red Light Stick Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Remote Raider Flare Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Seeker Grenade Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Shotgun Choke II Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Shotgun Choke III Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Shotgun Silencer Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Showstopper Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Silencer I Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Silencer II Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Smoke Grenade Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Snap Hook Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Stable Stock II Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Stable Stock III Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Surge Coil Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tactical Mk. 3 (Defensive) Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tactical Mk. 3 (Healing) Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tactical Mk. 3 (Revival) Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tactical Mk. 3 (Smoke) Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tagging Grenade Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Tempest Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Torrente Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Trailblazer Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Trigger Nade Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Venator Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Vertical Grip II Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Vertical Grip III Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Vita Shot Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Vita Spray Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Vulcano Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'White Flag Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Wolfpack Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
    ArcVoiceItemRecord(
      name: 'Yellow Light Stick Blueprint',
      rarity: 'Common',
      category: 'Blueprint',
      action: ArcVoiceItemAction.learn,
      summary:
          'Blueprint. If missing, consume/learn it. If already owned, keep the duplicate for trading before selling.',
      aliases: <String>[],
      usedToCraft: <String>[],
    ),
  ];
}
