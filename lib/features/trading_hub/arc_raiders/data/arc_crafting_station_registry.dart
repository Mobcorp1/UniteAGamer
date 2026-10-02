import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_progression_engine.dart';

/// Maps item-intelligence station IDs to canonical Bench Progression names.
class ArcCraftingStationRegistry {
  const ArcCraftingStationRegistry._();

  static const Map<String, String> _progressionStations = {
    'weapon_bench': 'Gunsmith',
    'explosives_bench': 'Explosives Station',
    'equipment_bench': 'Gear Bench',
    'med_station': 'Medical Lab',
    'utility_bench': 'Utility Station',
    'refiner': 'Refiner',
  };

  /// Returns null for workbench, in_raid and unknown station IDs.
  static String? progressionStationForId(String stationId) =>
      _progressionStations[stationId.trim().toLowerCase()];

  static String? progressionBenchIdForStationId(String stationId) {
    final station = progressionStationForId(stationId);
    return station == null ? null : ArcProgressionEngine.benchIdFor(station);
  }
}
