import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_two_content.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_item_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/trade_items_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/unified_item_index.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_repair_catalog.dart';

void main() {
  test(
    'five modules exist, map to exactly fifteen original rarity weapons',
    () {
      final marks = ArcFrozenTrailProgressionCatalog.amplificationMarkByWeapon;
      expect(marks.length, 15);
      expect(marks.values.toSet(), {1, 2, 3, 4, 5});
      expect(marks['Anvil'], 3);
      expect(marks.containsKey('Bantam'), false);
      expect(marks.containsKey('Stiletto'), false);
    },
  );
  test(
    'outpost and research stations have four verified levels and separate prerequisite gates',
    () {
      expect(ArcFrozenTrailProgressionCatalog.outpost.length, 4);
      expect(ArcFrozenTrailProgressionCatalog.researchStation.length, 4);
      expect(
        ArcFrozenTrailProgressionCatalog.outpost[2].materials['hand_drill'],
        3,
      );
      expect(
        ArcFrozenTrailProgressionCatalog
            .researchStation[3]
            .materials['frigate_inductors'],
        1,
      );
      expect(
        ArcFrozenTrailProgressionCatalog.canAmplify(
          weapon: 'Anvil',
          outpostLevel: 3,
          gunsmithLevel: 4,
          researchLevel: 4,
          modulePresent: true,
          weaponTierFour: true,
        ),
        false,
      );
      expect(
        ArcFrozenTrailProgressionCatalog.canAmplify(
          weapon: 'Anvil',
          outpostLevel: 4,
          gunsmithLevel: 4,
          researchLevel: 4,
          modulePresent: true,
          weaponTierFour: true,
        ),
        true,
      );
    },
  );
  test(
    'all newly introduced tangible resources are discoverable and have trade candidates',
    () {
      for (final item in ArcFrozenTrailTwoContent.items) {
        expect(
          ArcItemIntelligenceEngine.byId(item.id),
          isNotNull,
          reason: item.id,
        );
        final id = item.id.replaceAll('_', '-');
        expect(
          ArcTradeCatalog.items.where((i) => i.id == id),
          hasLength(1),
          reason: id,
        );
        expect(ArcTradeItemsData.byId(id), isNotNull, reason: id);
        expect(UnifiedItemIndex.findBest(id), isNotNull, reason: id);
      }
    },
  );
  test(
    'research currency not listed as physical trade, and conduit recipe is exact',
    () {
      expect(
        ArcTradeCatalog.items.any((i) => i.id == 'research-points'),
        isFalse,
      );
      final conduit = ArcItemIntelligenceEngine.byId(
        'emperor_gateway_conduit',
      )!;
      expect(conduit.recipe, {
        'arc_insulated_coupler': 1,
        'arc_conductive_coupler': 1,
        'arc_plated_coupler': 1,
      });
      expect(ArcItemIntelligenceEngine.byId('anvil_i')!.recipe, {
        'advanced_mechanical_components': 2,
        'heavy_gun_parts': 3,
        'hand_drill': 3,
      });
      expect(ArcItemIntelligenceEngine.byId('anvil_i')!.stationLevel, 2);
      expect(ArcItemIntelligenceEngine.byId('anvil_blueprint')!.recipe, {
        'research_points': 3000,
        'bully_fragmenters': 5,
        'rusted_tools': 1,
      });
      expect(ArcItemIntelligenceEngine.byId('canto_blueprint')!.recipe, {
        'research_points': 2000,
        'skulker_targeters': 10,
        'steel_spring': 5,
      });
      expect(ArcItemIntelligenceEngine.byId('canto_i')!.recipe, {
        'advanced_mechanical_components': 2,
        'magnet': 5,
        'medium_gun_parts': 3,
      });
      expect(ArcItemIntelligenceEngine.byId('canto_iv')!.recipe, {
        'canto_iii': 1,
        'mechanical_components': 2,
        'medium_gun_parts': 2,
      });
      expect(
        ArcItemIntelligenceEngine.byId('anvil_splitter')!.recyclesInto,
        isEmpty,
      );
      expect(
        ArcItemIntelligenceEngine.byId('anvil_splitter')!.salvagesInto,
        isEmpty,
      );
    },
  );
  test('old Anvil repairs cannot silently quote pre 2.0 costs', () {
    expect(ArcLoadoutRepairCatalog.repairForWeapon('Anvil', tier: 1), isNull);
    expect(
      ArcLoadoutRepairCatalog.repairForWeapon(
        'Anvil',
        tier: 2,
      )?.materials['heavy_gun_parts'],
      2,
    );
    expect(
      ArcLoadoutRepairCatalog.repairForWeapon(
        'Anvil',
        tier: 3,
      )?.materials['advanced_mechanical_components'],
      2,
    );
    expect(ArcLoadoutRepairCatalog.repairForWeapon('Anvil', tier: 4), isNull);
  });
}
