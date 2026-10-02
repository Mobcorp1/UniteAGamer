import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_crafting_station_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_item_intelligence_catalog.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_progression_engine.dart';

void main() {
  const mappings = {
    'weapon_bench': 'Gunsmith',
    'explosives_bench': 'Explosives Station',
    'equipment_bench': 'Gear Bench',
    'med_station': 'Medical Lab',
    'utility_bench': 'Utility Station',
    'refiner': 'Refiner',
  };

  for (final entry in mappings.entries) {
    test('${entry.key} resolves to canonical ${entry.value}', () {
      final definitions = const ArcProgressionEngine().benchDefinitions;
      expect(
        definitions.map((definition) => definition.station),
        contains(entry.value),
      );

      for (final stationId in [entry.key, '  ${entry.key.toUpperCase()}\t']) {
        expect(
          ArcCraftingStationRegistry.progressionStationForId(stationId),
          entry.value,
        );
        expect(
          ArcCraftingStationRegistry.progressionBenchIdForStationId(stationId),
          ArcProgressionEngine.benchIdFor(entry.value),
        );
      }
    });
  }

  for (final stationId in [
    'workbench',
    'in_raid',
    'unknown_station',
    '',
    ' ',
  ]) {
    test('does not guess a progression bench for "$stationId"', () {
      for (final input in [stationId, ' ${stationId.toUpperCase()} ']) {
        expect(
          ArcCraftingStationRegistry.progressionStationForId(input),
          isNull,
        );
        expect(
          ArcCraftingStationRegistry.progressionBenchIdForStationId(input),
          isNull,
        );
      }
    });
  }

  for (final example in [
    (
      name: 'Looting Mk. 3 (Safekeeper)',
      stationId: 'equipment_bench',
      station: 'Gear Bench',
    ),
    (
      name: 'Wolfpack',
      stationId: 'explosives_bench',
      station: 'Explosives Station',
    ),
    (
      name: 'Advanced Electrical Components',
      stationId: 'refiner',
      station: 'Refiner',
    ),
  ]) {
    test('${example.name} resolves through the existing item catalogue', () {
      final item = ArcItemIntelligenceCatalog.items.singleWhere(
        (item) => item.name == example.name,
      );
      expect(item.stationIds, [example.stationId]);
      final stationId = item.stationIds.single;
      expect(
        ArcCraftingStationRegistry.progressionStationForId(stationId),
        example.station,
      );
      expect(
        ArcCraftingStationRegistry.progressionBenchIdForStationId(stationId),
        ArcProgressionEngine.benchIdFor(example.station),
      );
    });
  }
}
