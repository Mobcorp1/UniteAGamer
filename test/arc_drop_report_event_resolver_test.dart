import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_drop_report_event_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';

void main() {
  test(
    'standard raid is always first and active regional event is suggested',
    () {
      final start = DateTime.utc(2026, 10, 1, 12);
      final end = start.add(const Duration(hours: 1));
      final snapshot = ArcRegionalMapConditionsSnapshot(
        entries: [
          ArcRegionalMapConditionEntry(
            conditionName: 'Night Raid',
            mapDisplayName: 'The Blue Gate',
            duration: const Duration(hours: 1),
            regionWindows: {
              ArcServerRegion.europe: ArcRegionalConditionWindow(
                startUtc: start,
                endUtc: end,
              ),
              ArcServerRegion.northAmerica: ArcRegionalConditionWindow(
                startUtc: start.add(const Duration(hours: 7)),
                endUtc: end.add(const Duration(hours: 7)),
              ),
            },
          ),
        ],
        serverNowUtc: start,
        loadedAtUtc: start,
        source: ArcMapConditionsSource.officialLive,
      );

      final options = ArcDropReportEventResolver.optionsFor(
        mapName: 'The Blue Gate',
        region: ArcServerRegion.europe,
        capturedAtUtc: start.add(const Duration(minutes: 20)),
        snapshot: snapshot,
      );

      expect(options.first, ArcMapConditions.noSpecialCondition);
      expect(options.map((item) => item.id), contains('night_raid'));
      expect(
        ArcDropReportEventResolver.suggestedFor(
          mapName: 'The Blue Gate',
          region: ArcServerRegion.europe,
          capturedAtUtc: start.add(const Duration(minutes: 20)),
          snapshot: snapshot,
        ).id,
        'night_raid',
      );
    },
  );

  test('region window changes the suggestion without changing the map', () {
    final start = DateTime.utc(2026, 10, 1, 12);
    final snapshot = ArcRegionalMapConditionsSnapshot(
      entries: [
        ArcRegionalMapConditionEntry(
          conditionName: 'Matriarch',
          mapDisplayName: 'The Blue Gate',
          duration: const Duration(hours: 1),
          regionWindows: {
            ArcServerRegion.europe: ArcRegionalConditionWindow(
              startUtc: start,
              endUtc: start.add(const Duration(hours: 1)),
            ),
            ArcServerRegion.northAmerica: ArcRegionalConditionWindow(
              startUtc: start.add(const Duration(hours: 5)),
              endUtc: start.add(const Duration(hours: 6)),
            ),
          },
        ),
      ],
      serverNowUtc: start,
      loadedAtUtc: start,
      source: ArcMapConditionsSource.officialLive,
    );

    final european = ArcDropReportEventResolver.suggestedFor(
      mapName: 'The Blue Gate',
      region: ArcServerRegion.europe,
      capturedAtUtc: start.add(const Duration(minutes: 10)),
      snapshot: snapshot,
    );
    final northAmerican = ArcDropReportEventResolver.suggestedFor(
      mapName: 'The Blue Gate',
      region: ArcServerRegion.northAmerica,
      capturedAtUtc: start.add(const Duration(minutes: 10)),
      snapshot: snapshot,
    );

    expect(european.id, 'matriarch');
    expect(northAmerican, ArcMapConditions.noSpecialCondition);
  });
}
