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
}
