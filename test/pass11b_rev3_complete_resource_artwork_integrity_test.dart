import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_upgrade_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_item_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_upgrade_resource_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_requirement_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_scrappy_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';

void main() {
  const newResources = <String>{
    'radial-presses',
    'magnetic-accelerators',
    'emperor-modulators',
    'planks',
    'battered-paperbacks',
    'mini-pumps',
    'calculators',
    'raider-logbooks',
    'skulker-targeters',
    'differential-microphones',
    'exodus-technical-handbooks',
    'bully-fragmenters',
    'thermal-shakers',
    'arc-data-modules',
    'frigate-inductors',
  };
  const pendingArt = <String>{
    'radial-presses',
    'emperor-modulators',
    'planks',
    'battered-paperbacks',
    'mini-pumps',
    'calculators',
    'raider-logbooks',
    'skulker-targeters',
    'differential-microphones',
    'exodus-technical-handbooks',
    'bully-fragmenters',
    'thermal-shakers',
    'arc-data-modules',
    'frigate-inductors',
  };

  test('all 15 newly introduced upgrade resources are mapped explicitly', () {
    final requirements = ArcBenchUpgradeSeedData.requirements
        .cast<ArcBenchUpgradeRequirement>();
    final introduced = requirements
        .where(
          (requirement) =>
              requirement.station == 'Research Station' ||
              (requirement.station == 'Gunsmith' && requirement.level == 4),
        )
        .map((requirement) => requirement.itemId)
        .toSet();
    expect(introduced, newResources);
    expect(pendingArt.length, 14);
    expect(newResources.difference(pendingArt), <String>{
      'magnetic-accelerators',
    });

    for (final id in introduced) {
      final asset = ArcItemAssetRegistry.assetPathForId(id);
      final expected = id == 'magnetic-accelerators'
          ? 'assets/arc_raiders/scrappy_resources/magnetic_accelerator.webp'
          : ArcItemAssetRegistry.upgradeArtworkPending;
      expect(asset, expected, reason: id);
      expect(File(asset).existsSync(), isTrue, reason: 'Missing $id: $asset');
      final resource = ArcMapUpgradeResourceCatalog.byItemId(id);
      expect(resource, isNotNull, reason: id);
      expect(resource!.imageAsset, asset, reason: id);
    }
    expect(
      ArcItemAssetRegistry.assetPathForId('firefly-burner'),
      'assets/arc_raiders/scrappy_resources/firefly_burner.webp',
    );
  });

  test(
    'all Bench, Scrappy, Quest and map-upgrade resource artwork resolves',
    () {
      final runtimePaths = <String>{
        ...ArcScrappySeedData.items.whereType<ArcScrappyItem>().map(
          (item) => item.imageAsset,
        ),
        ...ArcBenchUpgradeSeedData.items.whereType<ArcScrappyItem>().map(
          (item) => item.imageAsset,
        ),
        ...ArcQuestRequirementSeedData.items.whereType<ArcScrappyItem>().map(
          (item) => item.imageAsset,
        ),
        ...ArcMapUpgradeResourceCatalog.items.map((item) => item.imageAsset),
      };
      final missing = runtimePaths
          .where((path) => !File(path).existsSync())
          .toList();
      expect(
        missing,
        isEmpty,
        reason: 'Unresolved runtime asset paths: $missing',
      );
      expect(
        File(ArcItemAssetRegistry.upgradeArtworkPending).existsSync(),
        isTrue,
      );
    },
  );
}
