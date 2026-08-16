import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_upgrade_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_item_asset_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_requirement_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_scrappy_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';

void main() {
  test('PASS 346F Firefly resolves to the real singular asset', () {
    expect(
      ArcItemAssetRegistry.assetPathForId('firefly-burner'),
      'assets/arc_raiders/scrappy_resources/firefly_burner.webp',
    );
  });

  test('Scrappy remains const-safe', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/data/arc_scrappy_seed_data.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('ArcItemAssetRegistry.assetPathForId(')));
  });

  test('all routed tracker assets exist', () {
    final paths = <String>{
      ...ArcScrappySeedData.items.whereType<ArcScrappyItem>().map(
        (item) => item.imageAsset,
      ),
      ...ArcBenchUpgradeSeedData.items.whereType<ArcScrappyItem>().map(
        (item) => item.imageAsset,
      ),
      ...ArcQuestRequirementSeedData.items.whereType<ArcScrappyItem>().map(
        (item) => item.imageAsset,
      ),
    };

    final missing = paths.where((path) => !File(path).existsSync()).toList();
    expect(missing, isEmpty, reason: 'Missing runtime assets: $missing');
  });

  test('reference artifacts are retained outside runtime item assets', () {
    const names = <String>[
      'arc_item_download_results.json',
      'arc_item_reference_manifest.json',
      'arcraiders_wiki_loot_catalogue.json',
      'arcraiders_wiki_loot_page.html',
      'arctracker_raw_image_catalogue.json',
      'arctracker_rendered_page.html',
    ];

    for (final name in names) {
      expect(File('assets/arc_raiders/items/$name').existsSync(), isFalse);
      expect(
        File('reference/arc_raiders/item_sources/$name').existsSync(),
        isTrue,
      );
    }
  });
}
