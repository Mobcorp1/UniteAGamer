import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_objective_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_nomadic_trader_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';

void main() {
  const engine = ArcRaidObjectiveIntelligenceEngine();

  test('Nomadic Trader purchase requirements become private raid objectives', () {
    const tracker = ArcNomadicTraderTrackerSnapshot(
      savedStateKnown: true,
      goalName: 'Stash Expansion',
      highTier: true,
      targetValue: 200000,
      resources: <ArcNomadicTraderResourceSnapshot>[],
      purchases: <ArcNomadicTraderPurchaseSnapshot>[
        ArcNomadicTraderPurchaseSnapshot(
          id: 'purchase-1',
          name: 'Trader purchase',
          requiredQty: 1,
          ownedQty: 0,
          isGalleryProject: false,
          isCustom: false,
          requirements: <ArcNomadicTraderPurchaseRequirementSnapshot>[
            ArcNomadicTraderPurchaseRequirementSnapshot(
              id: 'rocketeer-driver',
              name: 'Rocketeer Driver',
              requiredQty: 3,
              ownedQty: 1,
              isCustom: false,
            ),
          ],
        ),
      ],
    );

    final objectives = engine.trackedObjectives(
      progression: ArcProgressionSnapshotBundle.empty,
      scrappyStates: const {},
      nomadicTraderTracker: tracker,
    );

    final trader = objectives.singleWhere(
      (objective) => objective.system == 'Nomadic Trader',
    );
    expect(trader.itemName, 'Rocketeer Driver');
    expect(trader.missingCount, 2);
    expect(trader.private, isTrue);
  });

  test('value-only trader goal contributes resource hunt signals', () {
    const tracker = ArcNomadicTraderTrackerSnapshot(
      savedStateKnown: true,
      goalName: 'Stash Expansion',
      highTier: true,
      targetValue: 200000,
      resources: <ArcNomadicTraderResourceSnapshot>[],
      purchases: <ArcNomadicTraderPurchaseSnapshot>[],
    );

    final objectives = engine.trackedObjectives(
      progression: ArcProgressionSnapshotBundle.empty,
      scrappyStates: const {},
      nomadicTraderTracker: tracker,
    );

    expect(
      objectives.where((objective) => objective.system == 'Nomadic Trader'),
      isNotEmpty,
    );
  });
}
