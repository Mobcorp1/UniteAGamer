import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_item_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_repair_catalog.dart';

void main() {
  test('legacy shield names migrate to live names', () {
    expect(
      ArcLoadoutRepairCatalog.migrateLegacyShield('Shield Level 1'),
      'Light Shield',
    );
    expect(
      ArcLoadoutRepairCatalog.migrateLegacyShield('Shield Level 2'),
      'Medium Shield',
    );
    expect(
      ArcLoadoutRepairCatalog.migrateLegacyShield('Shield Level 3'),
      'Heavy Shield',
    );
  });

  test('verified shield craft and repair data is encoded', () {
    final light = ArcLoadoutRepairCatalog.shieldFor('Light Shield')!;
    final medium = ArcLoadoutRepairCatalog.shieldFor('Medium Shield')!;
    final heavy = ArcLoadoutRepairCatalog.shieldFor('Heavy Shield')!;
    expect(light.craftRecipe, {'arc_alloy': 2, 'plastic_parts': 4});
    expect(light.repairRecipe, {'plastic_parts': 4});
    expect(medium.craftRecipe, {'battery': 4, 'arc_circuitry': 1});
    expect(medium.repairRecipe, {'arc_circuitry': 1, 'battery': 1});
    expect(heavy.craftRecipe, {'power_rod': 1, 'voltage_converter': 2});
    expect(heavy.repairRecipe, {'arc_circuitry': 2, 'voltage_converter': 1});
  });

  test('Anvil IV repair rolls refined materials to raw resources', () {
    final recipe = ArcLoadoutRepairCatalog.repairForWeapon('Anvil', tier: 4)!;
    final rollup = ArcItemIntelligenceEngine.planForRequirements(
      targetName: 'Anvil IV repair',
      requirements: recipe.materials,
    );
    expect(recipe.durabilityRestored, 65);
    expect(rollup.rawMaterials['metal_parts'], 35);
    expect(rollup.rawMaterials['rubber_parts'], 15);
    expect(rollup.rawMaterials['simple_gun_parts'], 5);
  });

  test('Stitcher IV repair rolls refined materials to raw resources', () {
    final recipe = ArcLoadoutRepairCatalog.repairForWeapon(
      'Stitcher',
      tier: 4,
    )!;
    final rollup = ArcItemIntelligenceEngine.planForRequirements(
      targetName: 'Stitcher IV repair',
      requirements: recipe.materials,
    );
    expect(recipe.durabilityRestored, 65);
    expect(rollup.rawMaterials['metal_parts'], 14);
    expect(rollup.rawMaterials['rubber_parts'], 6);
    expect(rollup.rawMaterials['simple_gun_parts'], 2);
  });
}
