import '../models/arc_blueprint_demand.dart';
import '../models/arc_trade_bundle_models.dart';

/// A recommendation is never an automatic acceptance or inventory mutation.
/// Buyers must submit a qualifying structured offer, and both Raiders confirm.
enum ArcSmartTradeStrategy { fast, balanced, maximumValue }

class ArcSmartTradeRecommendation {
  const ArcSmartTradeRecommendation({
    required this.minimumDistinctWanted,
    required this.confident,
    required this.reason,
  });
  final int minimumDistinctWanted;
  final bool confident;
  final String reason;
}

class ArcSmartTradeTerms {
  const ArcSmartTradeTerms._();
  static const marker = 'UAG_SMART_TRADE_V1';

  /// Community demand is user-reported, not verified market sales. Without
  /// adequate recent observations we intentionally recommend a 1-for-1 trade.
  static ArcSmartTradeRecommendation recommend({
    required ArcSmartTradeStrategy strategy,
    required int availableWanted,
    String rarity = 'unknown',
    ArcBlueprintDemand? demand,
    DateTime? now,
    int? explicitMinimum,
  }) {
    if (availableWanted == 0) {
      return const ArcSmartTradeRecommendation(
        minimumDistinctWanted: 0, confident: false,
        reason: 'No missing Blueprints are available for an exchange.',
      );
    }
    if (explicitMinimum != null) {
      final minimum = explicitMinimum.clamp(1, 2).toInt().clamp(1, availableWanted).toInt();
      return ArcSmartTradeRecommendation(minimumDistinctWanted: minimum,
        confident: false, reason: 'Manually selected by the sharing Raider.');
    }
    if (strategy == ArcSmartTradeStrategy.fast) {
      return const ArcSmartTradeRecommendation(minimumDistinctWanted: 1,
        confident: false, reason: 'Fast Trades prioritises 1-for-1 exchanges.');
    }
    final instant = (now ?? DateTime.now()).toUtc();
    final sampled = demand != null &&
        demand.wantedCount >= 0 && demand.tradeableCount >= 3 &&
        demand.wantedCount + demand.tradeableCount >= 30 &&
        demand.updatedAt != null &&
        !demand.updatedAt!.toUtc().isAfter(instant) &&
        instant.difference(demand.updatedAt!.toUtc()) <= const Duration(days: 14);
    if (!sampled) {
      return const ArcSmartTradeRecommendation(minimumDistinctWanted: 1,
        confident: false, reason: 'Demand sample is insufficient or out of date.');
    }
    final rare = <String>{'rare', 'epic', 'legendary'}.contains(rarity.toLowerCase());
    final threshold = strategy == ArcSmartTradeStrategy.maximumValue
        ? (rare ? 2.0 : 3.0)
        : (rare ? 2.5 : 4.0);
    final high = demand.demandRatio >= threshold && availableWanted >= 2;
    return ArcSmartTradeRecommendation(minimumDistinctWanted: high ? 2 : 1,
      confident: true,
      reason: high
        ? 'Recent community demand exceeds available offers. Suggested 2:1; verify before confirming.'
        : 'Recent community demand supports a 1:1 starting point.');
  }

  /// Build ONE existing TradingRepository accepted-bundle template. Every
  /// wanted Blueprint is an allowed candidate but only [minimum] DIFFERENT
  /// requested Blueprints are needed to satisfy the flexible template.
  static ArcTradeBundleTemplate bundleFor({
    required String offeredId,
    required List<({String id, String name})> wanted,
    required int minimum,
  }) {
    if (offeredId.trim().isEmpty || wanted.isEmpty || minimum < 1 || minimum > 2) {
      throw ArgumentError('Invalid smart trade request.');
    }
    final seen = <String>{};
    final filtered = wanted.where((item) => item.id.trim().isNotEmpty &&
      item.id != offeredId && seen.add(item.id)).toList(growable: false);
    if (filtered.length < minimum) {
      throw StateError('Not enough different missing Blueprints for this trade.');
    }
    return ArcTradeBundleTemplate(
      id: 'uag-smart-${offeredId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '-')}',
      name: '$minimum distinct wanted Blueprint${minimum == 1 ? '' : 's'}',
      components: [
        for (final item in filtered)
          ArcTradeBundleComponent(
            id: 'wanted-${item.id}',
            type: ArcTradeBundleComponentType.blueprint,
            itemId: item.id,
            itemName: item.name,
            quantity: 1,
          ),
      ],
      terms: ArcTradeBundleTerms(
        acceptedCategories: const [ArcTradeBundleComponentType.blueprint],
        minimumRequiredComponents: minimum,
        minimumRequiredQuantity: minimum,
        allowFlexibleAlternatives: true,
        requiresFinalConfirmation: true,
        notes: marker,
      ),
      notes: 'Offer any $minimum DIFFERENT missing Blueprints from this list. Both Raiders confirm.',
    );
  }
}
