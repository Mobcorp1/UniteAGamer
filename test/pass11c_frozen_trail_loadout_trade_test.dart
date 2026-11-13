import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_weapon_attachment_database.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_compatibility_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_repair_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_item_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_trade_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/trade_items_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/unified_item_index.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_crafting_station_registry.dart';

void main() {
  test('Bantam and Stiletto have sourced weapon slots and Gunsmith 1', () {
    final bantam = ArcLoadoutSeedData.weapons.singleWhere(
      (w) => w.name == 'Bantam',
    );
    final stiletto = ArcLoadoutSeedData.weapons.singleWhere(
      (w) => w.name == 'Stiletto',
    );
    final anvil = ArcLoadoutSeedData.weapons.singleWhere(
      (w) => w.name == 'Anvil',
    );
    expect(anvil.slots, <String>['Muzzle Mod']);
    expect(
      ArcWeaponAttachmentDatabase.attachmentForName('Anvil Splitter'),
      isNotNull,
    );
    expect(
      ArcLoadoutCompatibilityRegistry.isAttachmentCompatible(
        weaponName: 'Anvil',
        slotLabel: 'Tech Mod',
        attachmentName: 'Anvil Splitter',
      ),
      isFalse,
    );
    expect(bantam.slots, isEmpty);
    expect(stiletto.slots, <String>[
      'Muzzle Mod',
      'Underbarrel Mod',
      'Stock Mod',
    ]);
    expect(bantam.gunsmithLevel, 1);
    expect(stiletto.gunsmithLevel, 1);
    expect(stiletto.blueprintBased, isTrue);
    expect(
      ArcLoadoutCompatibilityRegistry.compatibleAttachmentsForSlot(
        weaponName: 'Stiletto',
        slotLabel: 'Muzzle Mod',
      ),
      isNotEmpty,
    );
    expect(
      ArcLoadoutCompatibilityRegistry.compatibleAttachmentsForSlot(
        weaponName: 'Bantam',
        slotLabel: 'Muzzle Mod',
      ),
      isEmpty,
    );
  });
  test('new weapon crafting costs and upgrade recipes are present', () {
    for (final name in <String>['bantam', 'stiletto']) {
      for (final tier in <String>['i', 'ii', 'iii', 'iv']) {
        expect(
          ArcItemIntelligenceEngine.byId('${name}_$tier')?.craftable,
          isTrue,
        );
      }
      final first = ArcItemIntelligenceEngine.byId('${name}_i')!;
      expect(first.recipe['simple_gun_parts'], 4);
      expect(first.recipe['mechanical_components'], 4);
      expect(
        ArcItemIntelligenceEngine.byId(
          '${name}_blueprint',
        )?.recipe['research_points'],
        3000,
      );
    }
    expect(
      ArcItemIntelligenceEngine.byId(
        'bantam_blueprint',
      )?.recipe['hornet_drivers'],
      8,
    );
    expect(
      ArcItemIntelligenceEngine.byId(
        'stiletto_blueprint',
      )?.recipe['wasp_drivers'],
      15,
    );
    expect(
      ArcCraftingStationRegistry.progressionStationForId('research_station'),
      'Research Station',
    );
  });
  test('Heavy Shield penalty updated and trade identities converged', () {
    expect(
      ArcLoadoutRepairCatalog.shieldFor('Heavy Shield')?.movementPenaltyPercent,
      10,
    );
    expect(ArcItemIntelligenceEngine.byId('anvil_i')?.rarity, 'Rare');
    expect(
      ArcItemIntelligenceEngine.byId('anvil_splitter')?.recyclesInto,
      isEmpty,
    );
    for (final id in <String>[
      'bantam',
      'stiletto',
      'bantam-blueprint',
      'stiletto-blueprint',
      'emperor-modulators',
    ]) {
      expect(ArcTradeCatalog.items.where((e) => e.id == id), hasLength(1));
      expect(ArcTradeItemsData.byId(id), isNotNull);
      expect(UnifiedItemIndex.items.where((e) => e.id == id), hasLength(1));
    }
    expect(
      ArcTradeCatalog.items.where((e) => e.id == 'research-points'),
      isEmpty,
    );
  });
}
