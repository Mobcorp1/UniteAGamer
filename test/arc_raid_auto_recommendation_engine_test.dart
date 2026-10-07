import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_auto_recommendation_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_availability.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_nomadic_trader_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trader_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';

void main() {
  const engine = ArcRaidAutoRecommendationEngine();
  final now = DateTime.utc(2026, 10, 5, 19, 15);

  ArcAvailability allEveningAvailability() => ArcAvailability(
        scheduleType: 'weekly',
        useEveryWeek: true,
        weeks: <ArcAvailabilityWeek>[
          ArcAvailabilityWeek(
            label: 'Week 1',
            slots: <ArcAvailabilitySlot>[
              const ArcAvailabilitySlot(
                dayKey: 'mon',
                enabled: true,
                fromTime: '18:00',
                toTime: '23:00',
              ),
              for (final day in const ['tue', 'wed', 'thu', 'fri', 'sat', 'sun'])
                ArcAvailabilitySlot.empty(day),
            ],
          ),
        ],
      );

  ArcRegionalMapConditionsSnapshot snapshot({
    required DateTime start,
    required DateTime end,
  }) => ArcRegionalMapConditionsSnapshot(
        entries: <ArcRegionalMapConditionEntry>[
          ArcRegionalMapConditionEntry(
            conditionName: 'Harvester',
            mapDisplayName: 'Blue Gate',
            duration: end.difference(start),
            regionWindows: <ArcServerRegion, ArcRegionalConditionWindow>{
              ArcServerRegion.europe: ArcRegionalConditionWindow(
                startUtc: start,
                endUtc: end,
              ),
            },
          ),
        ],
        serverNowUtc: now,
        loadedAtUtc: now,
        source: ArcMapConditionsSource.officialLive,
      );

  ArcNomadicTraderTrackerSnapshot queenTarget() =>
      const ArcNomadicTraderTrackerSnapshot(
        savedStateKnown: true,
        goalName: 'Stash Expansion',
        highTier: true,
        targetValue: 200000,
        resources: <ArcNomadicTraderResourceSnapshot>[],
        purchases: <ArcNomadicTraderPurchaseSnapshot>[
          ArcNomadicTraderPurchaseSnapshot(
            id: 'purchase-1',
            name: 'Tracked trader purchase',
            requiredQty: 1,
            ownedQty: 0,
            isGalleryProject: false,
            isCustom: false,
            requirements: <ArcNomadicTraderPurchaseRequirementSnapshot>[
              ArcNomadicTraderPurchaseRequirementSnapshot(
                id: 'queen-reactor',
                name: 'Queen Reactor',
                requiredQty: 1,
                ownedQty: 0,
                isCustom: false,
              ),
            ],
          ),
        ],
      );

  test('Nomadic Trader requirement selects relevant event map in play window', () {
    final result = engine.recommend(
      snapshot: snapshot(
        start: DateTime.utc(2026, 10, 5, 19),
        end: DateTime.utc(2026, 10, 5, 20),
      ),
      availability: allEveningAvailability(),
      profile: ArcTraderProfile.empty('u1'),
      nomadicTraderTracker: queenTarget(),
      blueprintStates: const {},
      nowUtc: now,
    );

    expect(result, isNotNull);
    expect(result!.mapId, 'blue_gate');
    expect(result.conditionName, 'Harvester');
    expect(result.fromNomadicTrader, isTrue);
    expect(result.live, isTrue);
  });

  test('upcoming condition outside saved play window is not promoted', () {
    final result = engine.recommend(
      snapshot: snapshot(
        start: DateTime.utc(2026, 10, 6, 2),
        end: DateTime.utc(2026, 10, 6, 3),
      ),
      availability: allEveningAvailability(),
      profile: ArcTraderProfile.empty('u1'),
      nomadicTraderTracker: queenTarget(),
      blueprintStates: const {},
      nowUtc: now,
    );

    expect(result, isNull);
  });

  test('tracked progression objective can select a verified condition map', () {
    final closeScrutinySnapshot = ArcRegionalMapConditionsSnapshot(
      entries: <ArcRegionalMapConditionEntry>[
        ArcRegionalMapConditionEntry(
          conditionName: 'Close Scrutiny',
          mapDisplayName: 'Blue Gate',
          duration: const Duration(hours: 1),
          regionWindows: <ArcServerRegion, ArcRegionalConditionWindow>{
            ArcServerRegion.europe: ArcRegionalConditionWindow(
              startUtc: DateTime.utc(2026, 10, 5, 19),
              endUtc: DateTime.utc(2026, 10, 5, 20),
            ),
          },
        ),
      ],
      serverNowUtc: now,
      loadedAtUtc: now,
      source: ArcMapConditionsSource.officialLive,
    );

    final result = engine.recommend(
      snapshot: closeScrutinySnapshot,
      availability: allEveningAvailability(),
      profile: ArcTraderProfile.empty('u1'),
      nomadicTraderTracker: ArcNomadicTraderTrackerSnapshot.empty,
      blueprintStates: const {},
      trackedObjectives: const <ArcRaidObjective>[
        ArcRaidObjective(
          id: 'quest-assessor',
          label: 'Quest: Assessor Matrix',
          reason: 'Tracked quest needs an Assessor Matrix.',
          category: ArcRaidMapMarkerCategory.questObjective,
          system: 'Quest',
          itemName: 'Assessor Matrix',
          missingCount: 1,
        ),
      ],
      nowUtc: now,
    );

    expect(result, isNotNull);
    expect(result!.conditionName, 'Close Scrutiny');
    expect(result.mapId, 'blue_gate');
  });


  test('live event outside saved play time is not promoted', () {
    final morningOnly = ArcAvailability(
      scheduleType: 'weekly',
      useEveryWeek: true,
      weeks: <ArcAvailabilityWeek>[
        ArcAvailabilityWeek(
          label: 'Week 1',
          slots: <ArcAvailabilitySlot>[
            const ArcAvailabilitySlot(
              dayKey: 'mon',
              enabled: true,
              fromTime: '06:00',
              toTime: '08:00',
            ),
            for (final day in const ['tue', 'wed', 'thu', 'fri', 'sat', 'sun'])
              ArcAvailabilitySlot.empty(day),
          ],
        ),
      ],
    );

    final result = engine.recommend(
      snapshot: snapshot(
        start: DateTime.utc(2026, 10, 5, 19),
        end: DateTime.utc(2026, 10, 5, 20),
      ),
      availability: morningOnly,
      profile: ArcTraderProfile.empty('u1'),
      nomadicTraderTracker: queenTarget(),
      blueprintStates: const {},
      nowUtc: now,
    );

    expect(result, isNull);
  });

  test('captured fallback never auto-selects a raid map', () {
    final live = snapshot(
      start: DateTime.utc(2026, 10, 5, 19),
      end: DateTime.utc(2026, 10, 5, 20),
    );
    final stale = ArcRegionalMapConditionsSnapshot(
      entries: live.entries,
      serverNowUtc: live.serverNowUtc,
      loadedAtUtc: live.loadedAtUtc,
      source: ArcMapConditionsSource.officialCapturedFallback,
    );

    final result = engine.recommend(
      snapshot: stale,
      availability: allEveningAvailability(),
      profile: ArcTraderProfile.empty('u1'),
      nomadicTraderTracker: queenTarget(),
      blueprintStates: const {},
      nowUtc: now,
    );

    expect(result, isNull);
  });

}
