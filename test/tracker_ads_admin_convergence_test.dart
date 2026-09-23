import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_scrappy_food_queue_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/scrappy_feed_queue_section.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test('Scrappy feed filters are direct reward-pool choices', () {
    expect(ScrappyFeedQueueSection.goals, const [
      'Overall',
      'Gunsmith',
      'Explosives',
      'Gear',
      'Medical',
      'Utility',
      'Mods',
    ]);

    final fruitMix = ArcScrappyFoodQueueData.items.singleWhere(
      (item) => item.id == 'fruit-mix',
    );
    expect(fruitMix.goals, const ['Overall']);

    for (final goal in ScrappyFeedQueueSection.goals.skip(1)) {
      final direct = ArcScrappyFoodQueueData.items
          .where((item) => item.goals.contains(goal))
          .toList();
      expect(direct, hasLength(1), reason: goal);
    }
  });

  test('Progress Tracker landing reuses existing hub hero assets', () {
    final text = source(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_progress_trackers_screen.dart',
    );

    for (final asset in const [
      'assets/arc_raiders/hub/arc_hub_scrappy_tracker.webp',
      'assets/arc_raiders/hub/arc_hub_bench_tracker.webp',
      'assets/arc_raiders/hub/arc_hub_quest_tracker.webp',
      'assets/arc_raiders/hub/arc_hub_hunt_targets.webp',
    ]) {
      expect(text, contains(asset), reason: asset);
    }
    expect(text, contains('Image.asset('));
    expect(text, contains('link.heroAsset,'));
    expect(text, contains('bottomPadding: 36'));
  });

  test('Admin map icon review reuses tracker assets in place', () {
    final text = source(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_map_filter_icon_review_screen.dart',
    );

    expect(text, contains('ArcScrappySeedData.items'));
    expect(text, contains('ArcBenchUpgradeSeedData.items'));
    expect(text, contains('ArcQuestRequirementSeedData.items'));
    expect(text, contains('item.imageAsset'));
    expect(text, contains('Scrappy Tracker Assets'));
    expect(text, contains('Bench Tracker Assets'));
    expect(text, contains('Quest Tracker Assets'));
  });

  test('Internal admin builds can QA the free banner policy', () {
    final text = source('lib/features/monetisation/ads/uag_ad_service.dart');

    expect(text, contains('!kReleaseMode'));
    expect(text, contains('entitlement.hasAdminBypass'));
    expect(text, contains('!entitlement.hasTestOverride'));
    expect(text, contains('UagAdPolicy.free'));
  });

  test('Scrappy tracker removes the old 120px dead bottom padding', () {
    final text = source(
      'lib/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart',
    );
    expect(text, isNot(contains('bottomPadding: 120')));
    expect(text, contains('bottomPadding: 36'));
    expect(
      text,
      contains('Feed bonuses stay useful after Scrappy upgrades are complete.'),
    );
  });
}
