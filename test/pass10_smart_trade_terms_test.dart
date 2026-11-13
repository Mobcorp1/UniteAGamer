import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_smart_trade_terms.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_bundle_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_demand.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_bundle_models.dart';

void main() {
  final now = DateTime.utc(2026, 10, 16);
  ArcBlueprintDemand demand(int wanted, int available, DateTime observed) =>
    ArcBlueprintDemand(blueprintId: 'bantam', wantedCount: wanted,
      tradeableCount: available, updatedAt: observed);

  test('unknown and stale demand never silently increase exchange requirements', () {
    for (final sample in <ArcBlueprintDemand?>[
      null,
      demand(60, 5, now.subtract(const Duration(days: 20))),
      demand(4, 1, now),
    ]) {
      expect(ArcSmartTradeTerms.recommend(
        strategy: ArcSmartTradeStrategy.maximumValue, availableWanted: 5,
        rarity: 'legendary', demand: sample, now: now).minimumDistinctWanted, 1);
    }
  });

  test('recent well-sampled community scarcity can suggest two distinct missing Blueprints', () {
    final recommendation = ArcSmartTradeTerms.recommend(
      strategy: ArcSmartTradeStrategy.balanced, availableWanted: 3,
      rarity: 'rare', demand: demand(65, 12, now), now: now);
    expect(recommendation.minimumDistinctWanted, 2);
    expect(recommendation.confident, isTrue);
    expect(ArcSmartTradeTerms.recommend(
      strategy: ArcSmartTradeStrategy.fast, availableWanted: 3,
      demand: demand(65, 12, now), now: now).minimumDistinctWanted, 1);
  });

  test('manual 2:1 cannot demand more missing Blueprints than exist', () {
    expect(ArcSmartTradeTerms.recommend(
      strategy: ArcSmartTradeStrategy.balanced, availableWanted: 1,
      explicitMinimum: 2).minimumDistinctWanted, 1);
  });

  test('bundle qualification is strict about distinct IDs, list membership and quantity', () {
    final template = ArcSmartTradeTerms.bundleFor(
      offeredId: 'bantam', minimum: 2,
      wanted: [(id: 'anvil', name: 'Anvil'),
        (id: 'bobcat', name: 'Bobcat'), (id: 'ferro', name: 'Ferro')]);
    final all = template.components;
    expect(const ArcTradeBundleEngine().validateTemplates([template]), isEmpty);
    ArcExactTradeBundleOffer offer(List<ArcTradeBundleComponent> components) =>
      ArcExactTradeBundleOffer(templateId: template.id, components: components);
    final engine = const ArcTradeBundleEngine();
    expect(engine.compare(template: template, offer: offer([all[0], all[2]])).isExact, isTrue);
    expect(engine.compare(template: template, offer: offer([all[1]])).isExact, isFalse);
    expect(engine.compare(template: template, offer: offer([all[0], all[0]])).isExact, isFalse);
    expect(engine.compare(template: template, offer: offer([all[0],
      const ArcTradeBundleComponent(id: 'other', type: ArcTradeBundleComponentType.blueprint,
        itemId: 'unowned-blueprint', itemName: 'Unrelated', quantity: 1)])).isExact, isFalse);
    expect(engine.compare(template: template, offer: offer([all[0],
      const ArcTradeBundleComponent(id: 'stack', type: ArcTradeBundleComponentType.blueprint,
        itemId: 'ferro', itemName: 'Ferro', quantity: 2)])).isExact, isFalse);
  });

  test('smart terms do not alter normal existing exact-bundle behavior', () {
    final template = ArcTradeBundleTemplate(id: 'legacy', name: 'Legacy',
      components: [const ArcTradeBundleComponent(id: 'one',
        type: ArcTradeBundleComponentType.blueprint,
        itemId: 'anvil', itemName: 'Anvil', quantity: 1)]);
    expect(const ArcTradeBundleEngine().compare(template: template,
      offer: const ArcExactTradeBundleOffer(templateId: 'legacy', components: [
        ArcTradeBundleComponent(id: 'one', type: ArcTradeBundleComponentType.blueprint,
          itemId: 'anvil', itemName: 'Anvil', quantity: 1)])).isExact, isTrue);
  });
}
