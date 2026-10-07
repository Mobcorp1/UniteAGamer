import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_trade_value_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_value.dart';

void main() {
  group('UAG Blueprint market value', () {
    test('keeps the barter ladder exact', () {
      expect(ArcUagValueTier.sPlus.points, 16);
      expect(ArcUagValueTier.s.points, 8);
      expect(ArcUagValueTier.a.points, 4);
      expect(ArcUagValueTier.b.points, 2);
      expect(ArcUagValueTier.c.points, 1);
    });

    test('known top-value blueprints retain explicit market tiers', () {
      final survivor = ArcBlueprintSeedData.blueprints.firstWhere(
        (item) => item.id == 'looting-mk-3-survivor',
      );
      final bobcat = ArcBlueprintSeedData.blueprints.firstWhere(
        (item) => item.id == 'bobcat',
      );
      expect(
        ArcBlueprintTradeValueCatalog.tradeTierFor(survivor),
        ArcUagValueTier.sPlus,
      );
      expect(
        ArcBlueprintTradeValueCatalog.tradeTierFor(bobcat),
        ArcUagValueTier.s,
      );
    });
  });

  group('Raid Intelligence live route state', () {
    test(
      'persists an explicit time budget and active condition on the route',
      () {
        const spawn = ArcRaidRouteStop(
          id: 'spawn',
          label: 'Spawn',
          point: ArcNormalizedPoint(x: 0.1, y: 0.1),
          order: 0,
        );
        const extraction = ArcRaidRouteStop(
          id: 'extract',
          label: 'Extraction',
          point: ArcNormalizedPoint(x: 0.9, y: 0.9),
          order: 1,
        );
        final route = ArcRaidRoutePlan(
          id: 'route',
          mapId: 'blue_gate',
          mapName: 'Blue Gate',
          squadMode: ArcRaidSquadMode.solo,
          routeStyle: ArcRaidRouteStyle.balanced,
          raidStage: 'Mid',
          objectivePriority: ArcRaidObjectivePriority.myNeedsFirst,
          spawn: spawn,
          extraction: extraction,
          stops: const <ArcRaidRouteStop>[],
          timeBudgetMinutes: 17,
          conditionLabel: 'Night Raid',
        );

        expect(route.timeBudgetMinutes, 17);
        expect(route.conditionLabel, 'Night Raid');
        expect(route.routeReady, isTrue);
      },
    );

    test('route style still trims stop count for late raids', () {
      expect(ArcRaidRouteStyle.balanced.stopLimitForStage('Full'), 4);
      expect(ArcRaidRouteStyle.balanced.stopLimitForStage('Mid'), 2);
      expect(ArcRaidRouteStyle.balanced.stopLimitForStage('Late'), 1);
    });
  });
}
