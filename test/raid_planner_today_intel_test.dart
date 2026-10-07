import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_availability_window_resolver.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_progression_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_availability.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raider_goal_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_live_raid_recommendation_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_raider_goal_bridge.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_opportunity_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/models/raid_planner_models.dart';

ArcAvailability availability({
  String from = '19:00',
  String to = '23:00',
  String day = 'tue',
}) => ArcAvailability(
  scheduleType: 'weekly',
  useEveryWeek: true,
  weeks: [
    ArcAvailabilityWeek(
      label: 'Week 1',
      slots: [
        ArcAvailabilitySlot(
          dayKey: day,
          enabled: true,
          fromTime: from,
          toTime: to,
        ),
      ],
    ),
  ],
);

void main() {
  tzdata.initializeTimeZones();
  final london = tz.getLocation('Europe/London');
  final resolver = ArcAvailabilityWindowResolver(location: london);
  DateTime local(int day, int hour, [int minute = 0]) =>
      tz.TZDateTime(london, 2026, 10, day, hour, minute).toUtc();
  final now = local(6, 18);
  const engine = ArcLiveRaidRecommendationEngine();
  const jupiter = RaidBlueprintTarget(
    blueprintId: 'jupiter',
    tier: RaidTargetTier.activeHunt,
    rank: 0,
  );

  ArcRegionalMapConditionEntry event(
    int day,
    int hour, {
    String condition = 'Harvester',
    String map = 'Dam Battlegrounds',
    int? endHour,
    ArcServerRegion region = ArcServerRegion.europe,
  }) => ArcRegionalMapConditionEntry(
    conditionName: condition,
    mapDisplayName: map,
    duration: const Duration(hours: 1),
    regionWindows: {
      region: ArcRegionalConditionWindow(
        startUtc: local(day, hour),
        endUtc: local(day, endHour ?? hour + 1),
      ),
    },
  );
  ArcRegionalMapConditionsSnapshot snapshot(
    List<ArcRegionalMapConditionEntry> entries,
  ) => ArcRegionalMapConditionsSnapshot(
    entries: entries,
    serverNowUtc: now,
    loadedAtUtc: now,
    source: ArcMapConditionsSource.officialLive,
  );
  ArcTodayRaidIntel build(
    List<ArcRegionalMapConditionEntry> entries, {
    ArcAvailability? playtime,
    DateTime? at,
    List<RaidBlueprintTarget> targets = const [],
    List<String> items = const ['queen-reactor'],
    List<TradingListing> listings = const [],
    ArcQuestProgressionSnapshot quest = ArcQuestProgressionSnapshot.empty,
    Map<String, ArcQuestRouteHint> questHints = const {},
  }) => engine.buildTodayRecommendations(
    effectiveTargets: targets,
    availability: playtime ?? availability(),
    regionalSnapshot: snapshot(entries),
    itemTargetIds: items,
    nowUtc: at ?? now,
    resolver: resolver,
    myListings: listings,
    currentUid: 'me',
    questSnapshot: quest,
    questRouteHints: questHints,
  );

  test('today -> playtime -> Queen goal: only 20:00 Harvester survives', () {
    final result = build([
      event(6, 10),
      event(6, 19, condition: 'Matriarch'),
      event(6, 20),
      event(7, 1),
    ]);
    expect(result.recommendations, hasLength(1));
    expect(
      result.recommendations.single.recommendation.candidate.startUtc,
      local(6, 20),
    );
  });

  test(
    'same event aggregates Jupiter and Queen and deduplicates repeats/regions',
    () {
      final result = build(
        [
          event(6, 20),
          event(6, 20),
          event(6, 20, region: ArcServerRegion.northAmerica),
        ],
        targets: [jupiter],
      );
      final item = result.recommendations.single;
      expect(
        item.recommendation.matchedGoals.map((g) => g.id),
        unorderedEquals(['blueprint:jupiter', 'item:queen-reactor']),
      );
      expect(item.homeRegion, isTrue);
    },
  );

  test('no padding and at most three recommendations from engine', () {
    expect(build([event(6, 20)]).recommendations, hasLength(1));
    expect(
      build([
        for (var hour = 19; hour < 23; hour++) event(6, hour),
      ]).recommendations,
      hasLength(3),
    );
  });

  test('empty states never substitute irrelevant or future schedules', () {
    final entries = [event(6, 20, condition: 'Matriarch'), event(7, 20)];
    expect(build(entries).status, ArcTodayRaidIntelStatus.noMatches);
    expect(build(entries).recommendations, isEmpty);
    expect(
      build(entries, playtime: ArcAvailability.initial()).status,
      ArcTodayRaidIntelStatus.noAvailability,
    );
    expect(build(entries, items: []).status, ArcTodayRaidIntelStatus.noGoals);
    expect(
      build(entries, playtime: availability(day: 'wed')).status,
      ArcTodayRaidIntelStatus.noPlaytime,
    );
    expect(
      build(entries, playtime: availability(from: '99:10')).status,
      ArcTodayRaidIntelStatus.noAvailability,
    );
  });

  test('only Active Hunt; Next Up and Later do not enter goal set', () {
    final result = build(
      [event(6, 20)],
      items: [],
      targets: [
        jupiter.copyWith(tier: RaidTargetTier.nextUp),
        const RaidBlueprintTarget(
          blueprintId: 'equalizer',
          tier: RaidTargetTier.later,
          rank: 0,
        ),
      ],
    );
    expect(result.status, ArcTodayRaidIntelStatus.noGoals);
    expect(result.recommendations, isEmpty);
  });

  test('Tuesday overnight includes Wednesday continuation, not afternoon', () {
    final result = build([
      event(7, 1),
      event(7, 14),
      event(8, 1),
    ], playtime: availability(from: '22:00', to: '06:00'));
    expect(
      result.recommendations.single.recommendation.candidate.startUtc,
      local(7, 1),
    );
    expect(result.playtime.single.endUtc, local(7, 6));
  });

  test('after midnight retains the session that began yesterday', () {
    final result = build(
      [event(7, 1), event(7, 3), event(7, 14)],
      at: local(7, 1, 15),
      playtime: availability(from: '22:00', to: '06:00'),
    );
    expect(result.recommendations, hasLength(2));
    expect(
      result.recommendations.first.recommendation.candidate.isLive,
      isTrue,
    );
    expect(result.recommendations.first.session.startUtc, local(6, 22));
    expect(
      build(
        [event(7, 14)],
        at: local(7, 6),
        playtime: availability(from: '22:00', to: '06:00'),
      ).recommendations,
      isEmpty,
    );
  });

  test('elapsed overlaps and touching endpoints are excluded', () {
    final result = build([
      event(6, 18),
      event(6, 20),
      event(6, 23),
    ], at: local(6, 21));
    expect(result.recommendations, isEmpty);
  });

  test(
    'live means playable now, and remaining time is clipped to availability',
    () {
      final result = build([event(6, 18, endHour: 20)], at: local(6, 18, 30));
      expect(
        result.recommendations.single.recommendation.candidate.isLive,
        isFalse,
      );
      expect(result.recommendations.single.playableStartUtc, local(6, 19));
      final ending = build([event(6, 22, endHour: 24)], at: local(6, 22, 30));
      expect(ending.recommendations.single.playableEndUtc, local(6, 23));
    },
  );

  test('live active goal beats upcoming multi-goal opportunity', () {
    final result = build(
      [event(6, 19, condition: 'Matriarch'), event(6, 20)],
      targets: [jupiter],
      items: ['queen-reactor', 'matriarch-reactor'],
      at: local(6, 19, 30),
    );
    expect(
      result.recommendations.first.recommendation.candidate.conditionName,
      'Matriarch',
    );
  });

  test('region switching is offered only for a relevant playable window', () {
    final result = build([
      event(6, 10),
      event(6, 20, region: ArcServerRegion.northAmerica),
      event(6, 20, region: ArcServerRegion.eastAsia, condition: 'Matriarch'),
    ]);
    expect(result.recommendations.single.region, ArcServerRegion.northAmerica);
  });

  test(
    'two-week rotation resolves actual date, including before anchor and DST',
    () {
      final rotation = ArcAvailability(
        scheduleType: 'rotation',
        useEveryWeek: false,
        weeks: [
          availability(from: '06:00', to: '14:00').weeks.single,
          availability(from: '14:00', to: '22:00').weeks.single,
        ],
      );
      expect(
        resolver.weekIndexForDate(rotation, tz.TZDateTime(london, 2026, 10, 6)),
        1,
      );
      expect(
        resolver.weekIndexForDate(
          rotation,
          tz.TZDateTime(london, 2026, 10, 13),
        ),
        0,
      );
      expect(
        resolver.weekIndexForDate(rotation, tz.TZDateTime(london, 2026, 3, 30)),
        0,
      );
      expect(
        resolver.weekIndexForDate(rotation, tz.TZDateTime(london, 2026, 1, 4)),
        1,
      );
      expect(
        resolver.todayWindows(rotation, now: local(6, 12)).single.startUtc,
        local(6, 14),
      );
      expect(
        build(
          [event(6, 8), event(6, 20)],
          playtime: rotation,
          at: local(6, 5),
        ).recommendations.single.recommendation.candidate.startUtc,
        local(6, 20),
      );
    },
  );

  test('overnight wall-clock endpoints survive both DST transitions', () {
    final playtime = availability(from: '22:00', to: '06:00', day: 'sat');
    final spring = resolver
        .todayWindows(playtime, now: tz.TZDateTime(london, 2026, 3, 28, 20))
        .single;
    final autumn = resolver
        .todayWindows(playtime, now: tz.TZDateTime(london, 2026, 10, 24, 20))
        .single;
    expect(spring.endUtc.difference(spring.startUtc).inHours, 7);
    expect(autumn.endUtc.difference(autumn.startUtc).inHours, 9);
    expect(resolver.localTime(autumn.endUtc).hour, 6);
  });

  test('positive and negative UTC offsets use the local day', () {
    for (final zone in ['Asia/Tokyo', 'America/Los_Angeles']) {
      final location = tz.getLocation(zone);
      DateTime at(int day, int hour) =>
          tz.TZDateTime(location, 2026, 10, day, hour).toUtc();
      final data = ArcRegionalMapConditionsSnapshot(
        entries: [
          ArcRegionalMapConditionEntry(
            conditionName: 'Harvester',
            mapDisplayName: 'Spaceport',
            duration: const Duration(hours: 1),
            regionWindows: {
              ArcServerRegion.europe: ArcRegionalConditionWindow(
                startUtc: at(6, 20),
                endUtc: at(6, 21),
              ),
            },
          ),
        ],
        serverNowUtc: at(6, 18),
        loadedAtUtc: at(6, 18),
        source: ArcMapConditionsSource.officialLive,
      );
      final result = engine.buildTodayRecommendations(
        effectiveTargets: [],
        availability: availability(),
        regionalSnapshot: data,
        itemTargetIds: ['queen-reactor'],
        nowUtc: at(6, 18),
        resolver: ArcAvailabilityWindowResolver(location: location),
      );
      expect(
        result.recommendations.single.recommendation.candidate.startUtc,
        at(6, 20),
      );
    }
  });

  test('regional and main feed share today/playtime hard filter', () {
    final entries = [event(6, 10), event(6, 20), event(7, 1)];
    final regional = ArcRegionalOpportunityEngine.recommendationsForTargets(
      snapshot: snapshot(entries),
      targets: ArcRegionalOpportunityEngine.itemRules
          .where((r) => r.id == 'queen-reactor')
          .toList(),
      availability: availability(),
      homeRegion: ArcServerRegion.europe,
      nowUtc: now,
      resolver: resolver,
    );
    expect(
      regional.single.window.startUtc,
      build(entries).recommendations.single.recommendation.candidate.startUtc,
    );
    expect(regional.single.insideSavedPlaytime, isTrue);
  });

  test('regional blueprint defaults exclude every missing blueprint', () {
    expect(
      ArcRegionalOpportunityEngine.blueprintRecommendations(
        snapshot: snapshot([event(6, 20)]),
        states: {'jupiter': ArcBlueprintState.empty('jupiter')},
        availability: availability(),
        homeRegion: ArcServerRegion.europe,
        nowUtc: now,
      ),
      isEmpty,
    );
  });

  test('only own structured active wanted items become acquisition goals', () {
    final listing = TradingListing.empty().copyWith(
      ownerUid: 'me',
      active: true,
      wantedTradeItemIds: ['queen-reactor'],
      expiresAt: local(7, 12),
    );
    final result = build([event(6, 20)], items: [], listings: [listing]);
    expect(
      result.recommendations.single.recommendation.matchedGoals.single.source,
      ArcRaiderGoalSource.trade,
    );
    for (final unrelated in [
      listing.copyWith(ownerUid: 'other'),
      listing.copyWith(active: false),
      listing.copyWith(expiresAt: now),
      listing.copyWith(wantsNothing: true),
      listing.copyWith(listingType: TradingListingType.openToOffers),
      listing.copyWith(
        wantedTradeItemIds: [],
        offeredTradeItemIds: ['queen-reactor'],
      ),
      listing.copyWith(
        wantedTradeItemIds: [],
        wantedText: 'Queen Reactor',
        notes: 'Queen Reactor',
      ),
    ]) {
      expect(
        build([event(6, 20)], items: [], listings: [unrelated]).recommendations,
        isEmpty,
      );
    }
    expect(
      build(
        [event(6, 20)],
        listings: [listing],
      ).recommendations.single.recommendation.goalCount,
      1,
    );
    expect(
      build(
        [event(6, 20, condition: 'Matriarch')],
        items: [],
        listings: [
          listing.copyWith(
            wantedTradeItemIds: [],
            wantedAssetNames: ['Matriarch Parts'],
          ),
        ],
      ).recommendations,
      hasLength(1),
    );
  });

  test('fresh account quest catalogue is not explicit intent', () {
    final quest = const ArcProgressionEngine()
        .build(scrappyStates: const {}, records: ArcProgressionRecords.empty)
        .quest;
    expect(
      build([event(6, 20)], items: [], quest: quest).status,
      ArcTodayRaidIntelStatus.noGoals,
    );
  });

  test('tracked quests need a verified special-condition link', () {
    const definition = ArcQuestProgressionDefinition(
      questId: 'q',
      trader: 'Shani',
      questName: 'Quest',
      order: 1,
      prerequisiteQuestIds: [],
      objectives: [
        ArcProgressionObjective(
          id: 'a',
          label: 'Interact',
          requiredCount: 1,
          currentCount: 0,
        ),
      ],
    );
    final quest = ArcQuestProgressionSnapshot(
      seasonId: 'test',
      entries: [
        ArcQuestProgressionEntry(
          definition: definition,
          status: ArcProgressionStatus.active,
          objectives: definition.objectives,
        ),
      ],
      completedQuestIds: {},
      archivedQuestIds: {},
      trackingKnown: true,
      trackedQuestIds: {'q'},
    );
    const standard = ArcQuestRouteHint(
      questId: 'q',
      mapNames: ['Dam Battlegrounds'],
    );
    expect(
      build(
        [event(6, 20)],
        items: [],
        quest: quest,
        questHints: {'q': standard},
      ).recommendations,
      isEmpty,
    );
    const eventHint = ArcQuestRouteHint(
      questId: 'q',
      mapNames: ['Dam Battlegrounds'],
      conditionNames: ['Harvester'],
      conditionFit: ArcRaiderGoalConditionFit.required,
    );
    expect(
      build(
        [event(6, 20)],
        items: [],
        quest: quest,
        questHints: {'q': eventHint},
      ).recommendations,
      hasLength(1),
    );
  });
}
