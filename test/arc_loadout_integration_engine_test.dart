import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_integration_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_loadout_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_bundle_models.dart';

void main() {
  test('smart build emits ranked Blueprint and Trading requirements', () {
    final plan = ArcLoadoutIntelligenceEngine.generate(
      primaryWeapon: 'Anvil',
      focus: ArcLoadoutCombatFocus.balanced,
      tier: ArcLoadoutBuildTier.value,
    );

    final snapshot = ArcLoadoutIntegrationEngine.evaluate(
      plan: plan,
      blueprintStates: const <String, ArcBlueprintState>{},
    );

    expect(snapshot.blueprints, isNotEmpty);
    expect(snapshot.blueprints.first.priorityRank, greaterThanOrEqualTo(90));
    expect(snapshot.missingBlueprints, isNotEmpty);
    expect(snapshot.tradeTemplate.isValid, isTrue);
    expect(
      snapshot.tradeTemplate.components.any(
        (item) => item.type == ArcTradeBundleComponentType.blueprint,
      ),
      isTrue,
    );
    expect(snapshot.nextMove, contains('Find or trade'));
  });

  test('owned Blueprints and resources improve completion and trade gap', () {
    final plan = ArcLoadoutIntelligenceEngine.generate(
      primaryWeapon: 'Anvil',
      focus: ArcLoadoutCombatFocus.pvp,
      tier: ArcLoadoutBuildTier.meta,
    );
    final initial = ArcLoadoutIntegrationEngine.evaluate(
      plan: plan,
      blueprintStates: const <String, ArcBlueprintState>{},
    );
    final ownedStates = <String, ArcBlueprintState>{
      for (final need in initial.blueprints)
        need.blueprintId: ArcBlueprintState.empty(
          need.blueprintId,
        ).copyWith(owned: true),
    };
    final ownedResources = <String, int>{
      for (final need in plan.resourceNeeds) need.itemName: need.quantity,
    };

    final complete = ArcLoadoutIntegrationEngine.evaluate(
      plan: plan,
      blueprintStates: ownedStates,
      ownedResources: ownedResources,
    );

    expect(complete.completionPercent, 100);
    expect(complete.missingBlueprints, isEmpty);
    expect(complete.missingResources, isEmpty);
    expect(complete.tradeTemplate.components, isEmpty);
    expect(complete.nextMove, contains('ready to craft'));
  });
}
