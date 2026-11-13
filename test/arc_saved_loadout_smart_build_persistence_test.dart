import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';

void main() {
  test('saved loadout preserves Smart Build metadata', () {
    final plan = ArcLoadoutIntelligenceEngine.generate(
      primaryWeapon: 'Anvil',
      focus: ArcLoadoutCombatFocus.balanced,
      tier: ArcLoadoutBuildTier.value,
    );
    final now = DateTime.utc(2026, 8, 3);
    final loadout = ArcSavedLoadout(
      id: 'favourite-loadout',
      name: plan.displayName,
      category: ArcLoadoutCategory.saved,
      playStyle: plan.focus.playStyle,
      augment: 'Survivor',
      shield: 'Shield Level 2',
      primaryWeapon: plan.primaryWeapon,
      primaryAttachments: plan.primaryAttachments,
      secondaryWeapon: plan.secondaryWeapon,
      secondaryAttachments: plan.secondaryAttachments,
      equipment: const <String>[],
      consumables: const <String>[],
      smartBuildData: plan.toMap(),
      createdAt: now,
      updatedAt: now,
    );

    final restored = ArcSavedLoadout.fromMap(loadout.id, loadout.toMap());
    final restoredPlan = ArcGeneratedLoadoutPlan.fromMap(
      restored.smartBuildData,
    );

    expect(restoredPlan, isNotNull);
    expect(restoredPlan!.displayName, plan.displayName);
    expect(restoredPlan.resourceNeeds.length, plan.resourceNeeds.length);
  });

  test('saved loadout preserves a user-selected recommended secondary', () {
    final options = ArcLoadoutIntelligenceEngine.secondaryOptionsFor(
      primaryWeapon: 'Venator',
      focus: ArcLoadoutCombatFocus.pvp,
      tier: ArcLoadoutBuildTier.meta,
    );
    final selectedSecondary = options.last;
    final plan = ArcLoadoutIntelligenceEngine.generate(
      primaryWeapon: 'Venator',
      focus: ArcLoadoutCombatFocus.pvp,
      tier: ArcLoadoutBuildTier.meta,
      secondaryWeaponOverride: selectedSecondary,
    );
    final now = DateTime.utc(2026, 8, 3);
    final loadout = ArcSavedLoadout(
      id: 'favourite-loadout',
      name: plan.displayName,
      category: ArcLoadoutCategory.saved,
      playStyle: plan.focus.playStyle,
      augment: 'Survivor',
      shield: 'Shield Level 2',
      primaryWeapon: plan.primaryWeapon,
      primaryAttachments: plan.primaryAttachments,
      secondaryWeapon: plan.secondaryWeapon,
      secondaryAttachments: plan.secondaryAttachments,
      equipment: const <String>[],
      consumables: const <String>[],
      smartBuildData: plan.toMap(),
      createdAt: now,
      updatedAt: now,
    );

    final restored = ArcSavedLoadout.fromMap(loadout.id, loadout.toMap());
    final restoredPlan = ArcGeneratedLoadoutPlan.fromMap(
      restored.smartBuildData,
    );

    expect(restoredPlan, isNotNull);
    expect(restoredPlan!.secondaryWeapon, selectedSecondary);
  });
}
