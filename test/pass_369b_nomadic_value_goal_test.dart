import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_objective_intelligence_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_nomadic_trader_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';

void main() {
  const engine = ArcRaidObjectiveIntelligenceEngine();

  test('value-only Nomadic Trader goal contributes resource hunt signals', () {
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

    final traderObjectives = objectives
        .where((objective) => objective.system == 'Nomadic Trader')
        .toList(growable: false);

    expect(traderObjectives, isNotEmpty);
    expect(traderObjectives.length, lessThanOrEqualTo(4));
    expect(
      traderObjectives.every((objective) => objective.itemName.isNotEmpty),
      isTrue,
    );
    expect(
      traderObjectives.any(
        (objective) => objective.itemName == 'Duplicate Blueprint',
      ),
      isFalse,
    );
  });

  test(
    'specific Nomadic Trader purchase requirements remain authoritative',
    () {
      const tracker = ArcNomadicTraderTrackerSnapshot(
        savedStateKnown: true,
        goalName: 'Weapon',
        highTier: true,
        targetValue: 100000,
        resources: <ArcNomadicTraderResourceSnapshot>[],
        purchases: <ArcNomadicTraderPurchaseSnapshot>[
          ArcNomadicTraderPurchaseSnapshot(
            id: 'weapon-purchase',
            name: 'Weapon',
            requiredQty: 1,
            ownedQty: 0,
            isGalleryProject: false,
            isCustom: false,
            requirements: <ArcNomadicTraderPurchaseRequirementSnapshot>[
              ArcNomadicTraderPurchaseRequirementSnapshot(
                id: 'driver',
                name: 'Rocketeer Driver',
                requiredQty: 5,
                ownedQty: 2,
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

      final traderObjectives = objectives
          .where((objective) => objective.system == 'Nomadic Trader')
          .toList(growable: false);

      expect(traderObjectives, hasLength(1));
      expect(traderObjectives.single.itemName, 'Rocketeer Driver');
      expect(traderObjectives.single.missingCount, 3);
    },
  );
}
