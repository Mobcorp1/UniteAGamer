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

  group('Raid Intelligence time budget', () {
    test('uses Full Mid Late budgets discussed for live raids', () {
      expect(ArcRaidTimeBudget.forStage('Full').totalMinutes, 28);
      expect(ArcRaidTimeBudget.forStage('Mid').totalMinutes, 17);
      expect(ArcRaidTimeBudget.forStage('Late').totalMinutes, 11);
    });

    test('reserves more time for a standard extraction than a hatch', () {
      final budget = ArcRaidTimeBudget.forStage('Late');
      expect(budget.routeMinutes(usesRaiderHatch: false), 8);
      expect(budget.routeMinutes(usesRaiderHatch: true), 9);
    });
  });
}
