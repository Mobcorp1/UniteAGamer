import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_live_raid_recommendation_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/models/raid_planner_models.dart';

void main() {
  const engine = ArcLiveRaidRecommendationEngine();

  ArcRegionalMapConditionsSnapshot snapshot({
    required DateTime now,
    List<ArcRegionalMapConditionEntry> entries =
        const <ArcRegionalMapConditionEntry>[],
  }) {
    return ArcRegionalMapConditionsSnapshot(
      entries: entries,
      serverNowUtc: now,
      loadedAtUtc: now,
      source: ArcMapConditionsSource.officialLive,
    );
  }

  test(
    'priority Blueprint state can drive Best Raid Now without a saved hunt',
    () {
      final now = DateTime.utc(2026, 10, 5, 18);
      final result = engine.build(
        storedTargets: const <RaidBlueprintTarget>[],
        blueprintStates: <String, ArcBlueprintState>{
          'surge-coil': ArcBlueprintState(
            blueprintId: 'surge-coil',
            owned: false,
            dupesOwned: 0,
            priorityRank: 1,
            updatedAt: now,
          ),
        },
        entitlement: const RaidPlannerEntitlement(tier: RaidPlannerTier.free),
        progressionRecords: ArcProgressionRecords.empty,
        scrappyStates: const {},
        regionalSnapshot: snapshot(
          now: now,
          entries: <ArcRegionalMapConditionEntry>[
            ArcRegionalMapConditionEntry(
              conditionName: 'Electromagnetic Storm',
              mapDisplayName: 'The Blue Gate',
              duration: const Duration(hours: 1),
              regionWindows: <ArcServerRegion, ArcRegionalConditionWindow>{
                ArcServerRegion.europe: ArcRegionalConditionWindow(
                  startUtc: now.subtract(const Duration(minutes: 10)),
                  endUtc: now.add(const Duration(minutes: 50)),
                ),
              },
            ),
          ],
        ),
        nowUtc: now,
      );

      expect(result.bestNow, isNotNull);
      expect(result.bestNow!.candidate.conditionName, 'Electromagnetic Storm');
    },
  );

  test('active condition lookup is regional and map-specific', () {
    final now = DateTime.utc(2026, 10, 5, 18);
    final data = snapshot(
      now: now,
      entries: <ArcRegionalMapConditionEntry>[
        ArcRegionalMapConditionEntry(
          conditionName: 'Night Raid',
          mapDisplayName: 'Spaceport',
          duration: const Duration(hours: 1),
          regionWindows: <ArcServerRegion, ArcRegionalConditionWindow>{
            ArcServerRegion.europe: ArcRegionalConditionWindow(
              startUtc: now.subtract(const Duration(minutes: 5)),
              endUtc: now.add(const Duration(minutes: 55)),
            ),
          },
        ),
      ],
    );

    expect(
      engine.activeConditionLabelForMap(
        regionalSnapshot: data,
        region: ArcServerRegion.europe,
        mapDisplayName: 'Spaceport',
        nowUtc: now,
      ),
      'Night Raid',
    );
    expect(
      engine.activeConditionLabelForMap(
        regionalSnapshot: data,
        region: ArcServerRegion.northAmerica,
        mapDisplayName: 'Spaceport',
        nowUtc: now,
      ),
      'No event / standard raid',
    );
  });
}
