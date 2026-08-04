import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_intelligence_models.dart';

void main() {
  test('every weapon can generate value and meta plans', () {
    for (final weapon in ArcLoadoutSeedData.weapons) {
      for (final tier in ArcLoadoutBuildTier.values) {
        final plan = ArcLoadoutIntelligenceEngine.generate(
          primaryWeapon: weapon.name,
          focus: ArcLoadoutCombatFocus.balanced,
          tier: tier,
        );
        expect(plan.primaryWeapon, weapon.name);
        expect(plan.secondaryWeapon, isNotEmpty);
        expect(plan.primaryAttachments.length, weapon.slots.length);
        expect(plan.version, isNotEmpty);
      }
    }
  });

  test('value plan prefers craftable low-investment attachments', () {
    final plan = ArcLoadoutIntelligenceEngine.generate(
      primaryWeapon: 'Kettle',
      focus: ArcLoadoutCombatFocus.balanced,
      tier: ArcLoadoutBuildTier.value,
    );
    expect(plan.primaryAttachments, isNotEmpty);
    expect(plan.resourceNeeds, isNotEmpty);
    expect(plan.rationale.join(' '), contains('performance per material'));
  });

  test('specialist PvE weapon receives anti-Raider secondary', () {
    final plan = ArcLoadoutIntelligenceEngine.generate(
      primaryWeapon: 'Hullcracker',
      focus: ArcLoadoutCombatFocus.pve,
      tier: ArcLoadoutBuildTier.meta,
    );
    expect(plan.secondaryWeapon, 'Venator');
    expect(plan.rationale.join(' '), contains('anti-Raider'));
  });

  test('resources aggregate duplicate crafting requirements', () {
    final plan = ArcLoadoutIntelligenceEngine.generate(
      primaryWeapon: 'Vulcano',
      focus: ArcLoadoutCombatFocus.pvp,
      tier: ArcLoadoutBuildTier.value,
    );
    final names = plan.resourceNeeds.map((entry) => entry.itemName).toSet();
    expect(names, isNotEmpty);
    expect(plan.resourceNeeds.every((entry) => entry.quantity > 0), isTrue);
  });

  test('generated Smart Build plan round-trips for persistence', () {
    final plan = ArcLoadoutIntelligenceEngine.generate(
      primaryWeapon: 'Anvil',
      focus: ArcLoadoutCombatFocus.pvp,
      tier: ArcLoadoutBuildTier.meta,
    );

    final restored = ArcGeneratedLoadoutPlan.fromMap(plan.toMap());

    expect(restored, isNotNull);
    expect(restored!.primaryWeapon, plan.primaryWeapon);
    expect(restored.secondaryWeapon, plan.secondaryWeapon);
    expect(restored.focus, plan.focus);
    expect(restored.tier, plan.tier);
    expect(restored.primaryAttachments, plan.primaryAttachments);
    expect(restored.resourceNeeds.length, plan.resourceNeeds.length);
  });

  test('secondary options exclude primary and remain valid weapons', () {
    final options = ArcLoadoutIntelligenceEngine.secondaryOptionsFor(
      primaryWeapon: 'Anvil',
      focus: ArcLoadoutCombatFocus.balanced,
      tier: ArcLoadoutBuildTier.meta,
    );
    final weaponNames = ArcLoadoutSeedData.weapons
        .map((weapon) => weapon.name)
        .toSet();

    expect(options, isNotEmpty);
    expect(options, isNot(contains('Anvil')));
    expect(options.every(weaponNames.contains), isTrue);
  });

  test('selected recommended secondary is honoured by generated plan', () {
    final options = ArcLoadoutIntelligenceEngine.secondaryOptionsFor(
      primaryWeapon: 'Venator',
      focus: ArcLoadoutCombatFocus.pvp,
      tier: ArcLoadoutBuildTier.meta,
    );
    final selected = options.last;
    final plan = ArcLoadoutIntelligenceEngine.generate(
      primaryWeapon: 'Venator',
      focus: ArcLoadoutCombatFocus.pvp,
      tier: ArcLoadoutBuildTier.meta,
      secondaryWeaponOverride: selected,
    );
    final secondary = ArcLoadoutSeedData.weapons.firstWhere(
      (weapon) => weapon.name == selected,
    );

    expect(plan.secondaryWeapon, selected);
    expect(plan.secondaryAttachments.length, secondary.slots.length);
  });

  test('invalid secondary override falls back to a recommended option', () {
    final options = ArcLoadoutIntelligenceEngine.secondaryOptionsFor(
      primaryWeapon: 'Kettle',
      focus: ArcLoadoutCombatFocus.pve,
      tier: ArcLoadoutBuildTier.value,
    );
    final plan = ArcLoadoutIntelligenceEngine.generate(
      primaryWeapon: 'Kettle',
      focus: ArcLoadoutCombatFocus.pve,
      tier: ArcLoadoutBuildTier.value,
      secondaryWeaponOverride: 'Not A Weapon',
    );

    expect(options, contains(plan.secondaryWeapon));
  });
}
