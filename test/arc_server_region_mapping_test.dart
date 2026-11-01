import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_drop_report_region_store.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';

void main() {
  test('profile preferences map to all five official schedule keys', () {
    const cases = <String, ArcServerRegion>{
      'Europe': ArcServerRegion.europe,
      'North America': ArcServerRegion.northAmerica,
      'South America': ArcServerRegion.brazil,
      'Asia': ArcServerRegion.eastAsia,
      'Oceania': ArcServerRegion.oceania,
    };
    for (final entry in cases.entries) {
      expect(
        ArcDropReportRegionStore.fromProfilePreference(entry.key),
        entry.value,
      );
      expect(
        ArcDropReportRegionStore.fromProfilePreference(
          ArcDropReportRegionStore.toProfilePreference(entry.value),
        ),
        entry.value,
      );
    }
    expect(ArcDropReportRegionStore.fromProfilePreference('Automatic'), isNull);
  });

  test(
    'new event names and regional windows are parsed without a catalogue',
    () {
      final entry = ArcRegionalMapConditionEntry.fromOfficialMap({
        'conditionName': 'Brand New Embark Event',
        'mapDisplayName': 'Riven Tides',
        'startTimestamp': 1793534400000,
        'endTimestamp': 1793538000000,
        'regionTimestamps': {
          'north-america': [1793559600000, 1793563200000],
          'brazil': [1793556000000, 1793559600000],
          'east-asia': [1793516400000, 1793520000000],
          'oceania': [1793502000000, 1793505600000],
        },
      });
      expect(entry.conditionName, 'Brand New Embark Event');
      for (final region in ArcServerRegion.values) {
        expect(entry.windowFor(region), isNotNull);
      }
      expect(
        entry.windowFor(ArcServerRegion.europe)!.startUtc,
        isNot(entry.windowFor(ArcServerRegion.northAmerica)!.startUtc),
      );
    },
  );
}
