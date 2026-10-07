import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_value.dart';

/// UAG market-value baseline for Blueprint barter.
///
/// This is deliberately separate from Embark item rarity. The tier is a UAG
/// barter signal driven by usefulness, demand, scarcity and progression value.
/// Live market signals can later move an item without changing its in-game
/// rarity or the canonical Blueprint grid.
class ArcBlueprintTradeValueCatalog {
  const ArcBlueprintTradeValueCatalog._();

  static const Set<String> _sPlus = <String>{
    'looting-mk-3-survivor',
    'dolabra',
  };

  static const Set<String> _s = <String>{
    'snap-hook',
    'bobcat',
    'wolfpack',
    'tactical-mk-3-defensive',
    'tactical-mk-3-revival',
    'extended-medium-mag-iii',
    'extended-light-mag-iii',
  };

  static const Set<String> _a = <String>{
    'tempest',
    'canto',
    'anvil',
    'vulcano',
    'venator',
    'bettina',
    'compensator-iii',
    'muzzle-brake-iii',
    'vertical-grip-iii',
    'angled-grip-iii',
    'stable-stock-iii',
    'shotgun-choke-iii',
    'extended-shotgun-mag-iii',
    'medium-gun-parts',
    'complex-gun-parts',
    'combat-mk-3-aggressive',
    'tactical-mk-3-healing',
    'pulse-mine',
    'defibrillator',
    'powered-descender',
  };

  static const Set<String> _b = <String>{
    'torrente',
    'osprey',
    'rascal',
    'aphelion',
    'il-toro',
    'jupiter',
    'hullcracker',
    'showstopper',
    'deadline',
    'trailblazer',
    'combat-mk-3-flanking',
    'looting-mk-3-safekeeper',
    'extended-medium-mag-ii',
    'extended-light-mag-ii',
    'extended-shotgun-mag-ii',
    'shotgun-silencer',
    'shotgun-choke-ii',
    'silencer-ii',
    'compensator-ii',
    'muzzle-brake-ii',
    'angled-grip-ii',
    'vertical-grip-ii',
    'stable-stock-ii',
    'lightweight-stock',
    'padded-stock',
    'extended-barrel-ii',
    'heavy-gun-parts',
    'light-gun-parts',
    'vita-spray',
    'vita-shot',
    'jolt-mine',
    'gas-mine',
    'explosive-mine',
    'blaze-grenade',
    'seeker-grenade',
    'tagging-grenade',
    'lure-grenade',
    'crash-mat',
    'surge-coil',
  };

  static const Map<String, ArcUagValueTier> _gameplayTiers =
      <String, ArcUagValueTier>{
        'looting-mk-3-survivor': ArcUagValueTier.sPlus,
        'tactical-mk-3-defensive': ArcUagValueTier.s,
        'tactical-mk-3-revival': ArcUagValueTier.s,
        'dolabra': ArcUagValueTier.s,
        'vulcano': ArcUagValueTier.s,
        'anvil': ArcUagValueTier.s,
        'tactical-mk-3-healing': ArcUagValueTier.a,
        'combat-mk-3-aggressive': ArcUagValueTier.a,
        'tempest': ArcUagValueTier.a,
        'bettina': ArcUagValueTier.a,
        'bobcat': ArcUagValueTier.a,
        'venator': ArcUagValueTier.a,
        'canto': ArcUagValueTier.a,
        'combat-mk-3-flanking': ArcUagValueTier.b,
        'looting-mk-3-safekeeper': ArcUagValueTier.b,
        'torrente': ArcUagValueTier.b,
        'osprey': ArcUagValueTier.b,
        'rascal': ArcUagValueTier.b,
        'aphelion': ArcUagValueTier.c,
        'il-toro': ArcUagValueTier.c,
        'jupiter': ArcUagValueTier.c,
        'hullcracker': ArcUagValueTier.c,
        'equalizer': ArcUagValueTier.c,
        'burletta': ArcUagValueTier.c,
      };

  static ArcBlueprintValueProfile forBlueprint(ArcBlueprint blueprint) {
    final tier = _tradeTierFor(blueprint);
    return ArcBlueprintValueProfile(
      blueprintId: blueprint.id,
      tradeTier: tier,
      gameplayTier: _gameplayTiers[blueprint.id],
      reason: _reasonFor(blueprint, tier),
    );
  }

  static ArcUagValueTier tradeTierFor(ArcBlueprint blueprint) =>
      _tradeTierFor(blueprint);

  static int tradePointsFor(ArcBlueprint blueprint) =>
      _tradeTierFor(blueprint).points;

  static int compareBlueprints(ArcBlueprint a, ArcBlueprint b) {
    final aTier = _tradeTierFor(a);
    final bTier = _tradeTierFor(b);
    final tierCompare = bTier.sortWeight.compareTo(aTier.sortWeight);
    if (tierCompare != 0) return tierCompare;
    final rarityCompare = b.rarity.index.compareTo(a.rarity.index);
    if (rarityCompare != 0) return rarityCompare;
    return a.name.compareTo(b.name);
  }

  static ArcUagValueTier _tradeTierFor(ArcBlueprint blueprint) {
    if (_sPlus.contains(blueprint.id)) return ArcUagValueTier.sPlus;
    if (_s.contains(blueprint.id)) return ArcUagValueTier.s;
    if (_a.contains(blueprint.id)) return ArcUagValueTier.a;
    if (_b.contains(blueprint.id)) return ArcUagValueTier.b;

    // Complete coverage for expansion/new items until reviewed market data is
    // available. This fallback never mutates Blueprint rarity or ordering.
    return switch (blueprint.rarity) {
      ArcBlueprintRarity.legendary => ArcUagValueTier.a,
      ArcBlueprintRarity.epic => ArcUagValueTier.b,
      ArcBlueprintRarity.rare => ArcUagValueTier.b,
      ArcBlueprintRarity.uncommon => ArcUagValueTier.c,
      ArcBlueprintRarity.common => ArcUagValueTier.c,
    };
  }

  static String _reasonFor(ArcBlueprint blueprint, ArcUagValueTier tier) {
    if (_sPlus.contains(blueprint.id)) {
      return 'Top UAG barter tier: exceptional demand, scarcity or progression utility.';
    }
    if (_s.contains(blueprint.id)) {
      return 'High-value UAG barter target with strong demand or utility.';
    }
    if (_a.contains(blueprint.id)) {
      return 'Strong trade value from useful progression, meta or attachment demand.';
    }
    if (_b.contains(blueprint.id)) {
      return 'Useful trade stock with regular but less concentrated demand.';
    }
    return tier == ArcUagValueTier.a
        ? 'High in-game rarity gives this new/unreviewed Blueprint a provisional A value.'
        : tier == ArcUagValueTier.b
        ? 'Useful provisional value pending stronger live market evidence.'
        : 'Lower baseline barter value; bundle with other Blueprints for stronger offers.';
  }
}
