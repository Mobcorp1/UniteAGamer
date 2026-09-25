import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_ad_placement_policy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_quest_reward_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_unlock_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_item_intelligence_engine.dart';

void main() {
  String source(String path) => File(path).readAsStringSync();

  test(
    'five verified Riven Tides quest Blueprint rewards resolve to graph nodes',
    () {
      expect(ArcBlueprintQuestRewardCatalog.rewards, hasLength(5));
      for (final reward in ArcBlueprintQuestRewardCatalog.rewards) {
        expect(reward.quest, isNotNull, reason: reward.questName);
        expect(reward.questId, isNotEmpty, reason: reward.questName);
      }
      final hullcracker = ArcBlueprintQuestRewardCatalog.forBlueprint(
        'Hullcracker Blueprint',
      );
      expect(hullcracker?.questName, "The Major's Footlocker");
      expect(hullcracker?.bonusUnlocks, contains('Launcher Ammo recipe'));
    },
  );

  test(
    'Hullcracker unlock plan derives prerequisites from the 100-quest graph',
    () {
      final plan = ArcBlueprintUnlockEngine.planForBlueprint('Hullcracker');
      expect(plan, isNotNull);
      expect(plan!.quest.displayName, "The Major's Footlocker");
      expect(plan.pathNodes.last.id, plan.quest.id);
      expect(plan.prerequisiteCount, greaterThan(0));
    },
  );

  test(
    'weapon planning resolves directly to Level IV with recursive raw materials',
    () {
      final anvil = ArcItemIntelligenceEngine.planForItem('Anvil');
      expect(anvil.targetName, contains('IV'));
      expect(anvil.rawMaterials, isNotEmpty);
      expect(anvil.craftSteps, isNotEmpty);
    },
  );

  test(
    'mobile landscape Blueprint chrome gives the grid back its vertical space',
    () {
      final tracker = source(
        'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
      );
      expect(tracker, contains('compactMobileLandscape'));
      expect(tracker, contains("ArcCompanionBottomDock(activeLabel: 'Track')"));
      expect(tracker, contains('if (!compactMobileLandscape)'));
      expect(tracker, contains('ArcBlueprintWorkspaceDock('));
      expect(tracker, contains("case 'loadout':"));
      expect(tracker, contains("case 'watches':"));
      expect(tracker, contains("label: 'Guaranteed Quest Unlock'"));
    },
  );

  test(
    'Favourite Loadout has compact in-game mobile board and Level IV roll-up',
    () {
      final loadout = source(
        'lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart',
      );
      expect(loadout, contains('_buildCompactMobileBoard'));
      expect(loadout, contains('_buildPortraitInGameBoard'));
      expect(loadout, contains('_buildCompactWeaponRow'));
      expect(loadout, contains('_buildWantedBlueprintGrid'));
      expect(loadout, contains('wantedBlueprintSlotCount'));
      expect(loadout, contains("'LEVEL IV BUILD COST'"));
      expect(loadout, contains('ArcItemIntelligenceEngine.planForItem'));
      expect(loadout, contains("label: 'Quest Unlock Path'"));
    },
  );

  test('Quest cards surface guaranteed Blueprint rewards', () {
    final quest = source(
      'lib/features/trading_hub/arc_raiders/widgets/arc_quest_tracker_workspace.dart',
    );
    expect(quest, contains('ArcBlueprintQuestRewardCatalog.forQuest'));
    expect(quest, contains('GUARANTEED BLUEPRINT'));
    expect(quest, contains('initialQuestId'));
  });

  test('avatar uses decode-sized asset and visible first-frame fallback', () {
    final avatar = source(
      'lib/features/trading_hub/arc_raiders/widgets/uag_raider_avatar.dart',
    );
    expect(avatar, contains('cacheWidth: cacheWidth'));
    expect(avatar, contains('frameBuilder:'));
    expect(avatar, contains('filterQuality: FilterQuality.medium'));
  });

  test('full-screen ads only allow reviewed natural completion placements', () {
    expect(
      UagAdPlacementPolicy.permitsInterstitial(
        '/trading-hub/arc-raiders/blueprints',
      ),
      isFalse,
    );
    expect(
      UagAdPlacementPolicy.permitsNaturalBreakInterstitial(
        UagAdPlacementPolicy.blueprintImportCompleted,
        '/trading-hub/arc-raiders/blueprints',
      ),
      isTrue,
    );
    expect(
      UagAdPlacementPolicy.permitsNaturalBreakInterstitial(
        UagAdPlacementPolicy.favouriteLoadoutSaved,
        '/favourite-loadout',
      ),
      isTrue,
    );
    expect(
      UagAdPlacementPolicy.permitsNaturalBreakInterstitial(
        UagAdPlacementPolicy.favouriteLoadoutSaved,
        '/trading-hub/arc-raiders/blueprints',
      ),
      isFalse,
    );
  });
}
