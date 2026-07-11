import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/raid_planner_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/models/raid_planner_models.dart';

void main() {
  group('RaidPlannerEngine target mapping', () {
    test(
      'filters owned blueprints and promotes next-up targets into active slots',
      () {
        final effective = RaidPlannerEngine.effectiveTargets(
          storedTargets: const <RaidBlueprintTarget>[
            RaidBlueprintTarget(
              blueprintId: 'surge-coil',
              tier: RaidTargetTier.activeHunt,
              rank: 0,
            ),
            RaidBlueprintTarget(
              blueprintId: 'canto',
              tier: RaidTargetTier.nextUp,
              rank: 1,
            ),
            RaidBlueprintTarget(
              blueprintId: 'dolabra',
              tier: RaidTargetTier.nextUp,
              rank: 2,
            ),
          ],
          states: const <String, ArcBlueprintState>{
            'surge-coil': ArcBlueprintState(
              blueprintId: 'surge-coil',
              owned: true,
              dupesOwned: 0,
              priorityRank: 0,
              updatedAt: null,
            ),
          },
          entitlement: const RaidPlannerEntitlement(
            tier: RaidPlannerTier.essential,
          ),
        );

        expect(effective, hasLength(2));
        expect(effective.first.blueprintId, 'canto');
        expect(effective.first.tier, RaidTargetTier.activeHunt);
        expect(effective.last.blueprintId, 'dolabra');
        expect(effective.last.tier, RaidTargetTier.activeHunt);
      },
    );
  });
}
