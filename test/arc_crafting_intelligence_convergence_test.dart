import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_item_intelligence_engine.dart';

void main() {
  test('canonical item aliases support spoken singular/plural forms', () {
    expect(ArcItemIntelligenceEngine.resolve('lemons')?.id, 'lemon');
    expect(
      ArcItemIntelligenceEngine.resolve('explosive compounds')?.id,
      'explosive_compound',
    );
    expect(
      ArcItemIntelligenceEngine.resolve('steel springs')?.id,
      'steel_spring',
    );
  });

  test('unlevelled weapon names resolve to the highest craftable tier', () {
    expect(
      ArcItemIntelligenceEngine.resolveCraftTarget('Anvil')?.id,
      'anvil_iv',
    );
  });

  test('weapon upgrade chain expands from scratch', () {
    final plan = ArcItemIntelligenceEngine.planForItem('Anvil IV');
    expect(plan.unresolvedTargets, isEmpty);
    expect(plan.craftSteps.any((step) => step.itemId == 'anvil_i'), isTrue);
    expect(plan.craftSteps.any((step) => step.itemId == 'anvil_ii'), isTrue);
    expect(plan.craftSteps.any((step) => step.itemId == 'anvil_iii'), isTrue);
    expect(plan.craftSteps.any((step) => step.itemId == 'anvil_iv'), isTrue);
    expect(plan.rawMaterials, isNotEmpty);
  });

  test('Topside recycling and salvage remain separate', () {
    final toaster = ArcItemIntelligenceEngine.byId('toaster');
    expect(toaster, isNotNull);
    expect(toaster!.recyclesInto['wires'], 3);
    expect(toaster.recyclesInto['plastic_parts'], 5);
    expect(toaster.salvagesInto['wires'], 3);
    expect(toaster.salvagesInto.containsKey('plastic_parts'), isFalse);
  });

  test('medical mapping includes user-confirmed feed-independent items', () {
    expect(
      ArcItemIntelligenceEngine.byId('adrenaline_shot')?.primaryStation,
      'Medical',
    );
    expect(
      ArcItemIntelligenceEngine.byId('bandage')?.primaryStation,
      'Medical',
    );
  });

  test('catalog coverage stays broad enough for launch intelligence', () {
    expect(ArcItemIntelligenceEngine.items.length, greaterThan(400));
    expect(
      ArcItemIntelligenceEngine.craftables.length,
      greaterThanOrEqualTo(180),
    );
    expect(
      ArcItemIntelligenceEngine.recyclables.length,
      greaterThanOrEqualTo(285),
    );
  });

  test('routing and Scrappy cleanup are wired into source', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final trackerSource = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_progress_trackers_screen.dart',
    ).readAsStringSync();
    final scrappySource = File(
      'lib/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart',
    ).readAsStringSync();

    expect(mainSource, contains('ArcCraftingPlannerScreen.routeName'));
    expect(trackerSource, contains('Crafting Planner'));
    expect(scrappySource, isNot(contains('_buildFeedGoalBar()')));
    expect(scrappySource, contains('Crafting Planner'));
  });
}
