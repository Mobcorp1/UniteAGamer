import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_integration_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_intelligence_models.dart';

void main() {
  test('trade draft preserves exact meta requirements', () {
    final plan = ArcGeneratedLoadoutPlan(
      version: 'test',
      researchedAt: DateTime.utc(2026, 8, 3),
      primaryWeapon: 'Venator',
      primaryAttachments: const <String>[],
      secondaryWeapon: 'Stitcher',
      secondaryAttachments: const <String>[],
      focus: ArcLoadoutCombatFocus.pvp,
      tier: ArcLoadoutBuildTier.meta,
      blueprintPriorities: const <String>[],
      resourceNeeds: const <ArcLoadoutResourceNeed>[
        ArcLoadoutResourceNeed(itemName: 'Metal Parts', quantity: 4),
      ],
      rationale: const <String>[],
      confidence: 'test',
    );

    final snapshot = ArcLoadoutIntegrationEngine.evaluate(
      plan: plan,
      blueprintStates: const {},
    );

    expect(snapshot.tradeTemplate.allowEquivalentOffers, isFalse);
    expect(snapshot.missingResources.single.missingQuantity, 4);
    expect(snapshot.tradeTemplate.components, isNotEmpty);
  });

  test('value trade draft allows equivalent offers', () {
    final plan = ArcGeneratedLoadoutPlan(
      version: 'test',
      researchedAt: DateTime.utc(2026, 8, 3),
      primaryWeapon: 'Kettle',
      primaryAttachments: const <String>[],
      secondaryWeapon: 'Hairpin',
      secondaryAttachments: const <String>[],
      focus: ArcLoadoutCombatFocus.balanced,
      tier: ArcLoadoutBuildTier.value,
      blueprintPriorities: const <String>[],
      resourceNeeds: const <ArcLoadoutResourceNeed>[],
      rationale: const <String>[],
      confidence: 'test',
    );

    final snapshot = ArcLoadoutIntegrationEngine.evaluate(
      plan: plan,
      blueprintStates: const {},
    );

    expect(snapshot.tradeTemplate.allowEquivalentOffers, isTrue);
    expect(snapshot.tradeTemplate.terms.allowEquivalentSubstitutions, isTrue);
  });
}
