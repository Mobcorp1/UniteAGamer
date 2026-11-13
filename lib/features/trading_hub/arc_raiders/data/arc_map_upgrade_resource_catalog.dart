import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_upgrade_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_item_asset_registry.dart';

/// A map resource is one item, regardless of how many upgrades require it.
class ArcMapUpgradeResource {
  const ArcMapUpgradeResource({
    required this.itemId,
    required this.name,
    required this.requirements,
  });

  final String itemId;
  final String name;
  final List<ArcBenchUpgradeRequirement> requirements;

  String get subtypeId => 'upgrade_${itemId.replaceAll('-', '_')}';
  String get imageAsset => ArcItemAssetRegistry.assetPathForId(itemId);
  bool get usedForScrappy => requirements.any((r) => r.station == 'Scrappy');
  bool get usedForBench => requirements.any((r) => r.station != 'Scrappy');
  String get usageLabel => usedForScrappy && usedForBench
      ? 'Scrappy + Bench'
      : usedForScrappy
      ? 'Scrappy'
      : 'Bench';
  String get usageDetails =>
      requirements.map((r) => '${r.upgradeLabel} ×${r.quantity}').join(' • ');
}

class ArcMapUpgradeResourceCatalog {
  const ArcMapUpgradeResourceCatalog._();

  // This authoritative requirement source includes both workstation and
  // Scrappy upgrades. In particular, both Apricot tiers share `apricots`.
  static final List<ArcMapUpgradeResource> items = fromRequirements(
    ArcBenchUpgradeSeedData.requirements.cast<ArcBenchUpgradeRequirement>(),
  );

  static List<ArcMapUpgradeResource> fromRequirements(
    Iterable<ArcBenchUpgradeRequirement> requirements,
  ) {
    final grouped = <String, List<ArcBenchUpgradeRequirement>>{};
    for (final requirement in requirements) {
      grouped.putIfAbsent(requirement.itemId, () => []).add(requirement);
    }
    return List.unmodifiable(
      grouped.entries
          .map(
            (entry) => ArcMapUpgradeResource(
              itemId: entry.key,
              name: entry.value.first.itemName,
              requirements: List.unmodifiable(entry.value),
            ),
          )
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name)),
    );
  }

  static ArcMapUpgradeResource? byItemId(String? id) {
    for (final item in items) {
      if (item.itemId == id) return item;
    }
    return null;
  }

  static ArcMapUpgradeResource? bySubtypeId(String? id) {
    for (final item in items) {
      if (item.subtypeId == id) return item;
    }
    return null;
  }
}
