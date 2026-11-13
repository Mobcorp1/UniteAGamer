import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_event_relevance.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/models/raid_planner_models.dart';

const slots = [
  RaidPlannerEventSlot(
    mapName: 'Dam Battlegrounds',
    eventName: 'Hurricane',
    lane: 'Major',
    startHourGmt: 1,
    endHourGmt: 2,
  ),
  RaidPlannerEventSlot(
    mapName: 'Spaceport',
    eventName: 'Electromagnetic Storm',
    lane: 'Major',
    startHourGmt: 5,
    endHourGmt: 6,
  ),
  RaidPlannerEventSlot(
    mapName: 'Blue Gate',
    eventName: 'Harvester',
    lane: 'Minor',
    startHourGmt: 9,
    endHourGmt: 10,
  ),
];

ArcUserPersonalisationProfile profile(ArcPersonalisationGoal goal) =>
    ArcUserPersonalisationProfile(completed: true, goals: {goal});

void main() {
  final now = DateTime.utc(2026, 9, 21);
  test(
    'no personalisation remains chronological with honest unknown relevance',
    () {
      final events = const ArcEventRelevance().rank(nowUtc: now, slots: slots);
      expect(events.first.slot.eventName, 'Hurricane');
      expect(events.every((event) => event.score == 0), isTrue);
      expect(events.first.reason, 'No confirmed link to your goals');
    },
  );

  test(
    'Blueprint priority promotes its existing condition rule; ownership removes it',
    () {
      final state = ArcBlueprintState.empty(
        'surge-coil',
      ).copyWith(priorityRank: 1);
      final relevance = ArcEventRelevance(
        profile: profile(ArcPersonalisationGoal.completeBlueprints),
        blueprints: {'surge-coil': state},
      );
      final events = relevance.rank(nowUtc: now, slots: slots);
      expect(events.first.slot.eventName, 'Electromagnetic Storm');
      expect(events.first.reason, contains('Priority Blueprint: Surge Coil'));
      final owned = ArcEventRelevance(
        profile: relevance.profile,
        blueprints: {'surge-coil': state.copyWith(owned: true)},
      );
      expect(
        owned
            .reasonsFor('Electromagnetic Storm', 'Spaceport')
            .keys
            .any((reason) => reason.contains('Surge Coil')),
        isFalse,
      );
    },
  );

  test(
    'unknown Blueprint source does not imply all Blueprints are missing',
    () {
      final relevance = ArcEventRelevance(
        profile: profile(ArcPersonalisationGoal.completeBlueprints),
      );
      expect(
        relevance
            .rank(nowUtc: now, slots: slots)
            .every((event) => event.score == 0),
        isTrue,
      );
    },
  );

  test(
    'known active quest map context rises without claiming event rewards',
    () {
      const objective = ArcProgressionObjective(
        id: 'test-objective',
        label: 'Quest material',
        requiredCount: 2,
        currentCount: 0,
        sourceHint: 'Search Spaceport containers.',
      );
      const quest = ArcQuestProgressionEntry(
        definition: ArcQuestProgressionDefinition(
          questId: 'test',
          trader: 'Shani',
          questName: 'Test quest',
          order: 1,
          prerequisiteQuestIds: [],
          objectives: [objective],
        ),
        status: ArcProgressionStatus.active,
        objectives: [objective],
      );
      const bundle = ArcProgressionSnapshotBundle(
        quest: ArcQuestProgressionSnapshot(
          seasonId: 'test',
          entries: [quest],
          completedQuestIds: {},
          archivedQuestIds: {},
          trackingKnown: true,
        ),
        scrappy: ArcScrappyProgressionSnapshot.empty,
        bench: ArcBenchProgressionSnapshot.empty,
      );
      final relevance = ArcEventRelevance(
        profile: profile(ArcPersonalisationGoal.progressQuests),
        progression: bundle,
      );
      final events = relevance.rank(nowUtc: now, slots: slots);
      expect(events.first.slot.mapName, 'Spaceport');
      expect(events.first.reason, contains('map context only'));
      expect(events.first.reason, isNot(contains('reward')));
    },
  );

  test('quest onboarding alone does not invent a condition link', () {
    final relevance = ArcEventRelevance(
      profile: profile(
        ArcPersonalisationGoal.progressQuests,
      ).copyWith(questProgress: ArcQuestProgressState.startingOrReset),
    );
    expect(
      relevance
          .rank(nowUtc: now, slots: slots)
          .every((event) => event.score == 0),
      isTrue,
    );
  });

  test(
    'raid goal promotes schedule context; trading does not invent relevance',
    () {
      final raid = ArcEventRelevance(
        profile: profile(ArcPersonalisationGoal.planRaids),
      );
      expect(
        raid.rank(nowUtc: now, slots: slots).every((event) => event.score > 0),
        isTrue,
      );
      final trade = ArcEventRelevance(
        profile: profile(ArcPersonalisationGoal.tradeBlueprints),
        blueprints: {},
      );
      expect(
        trade
            .rank(nowUtc: now, slots: slots)
            .every((event) => event.score == 0),
        isTrue,
      );
    },
  );

  test('Show all and Explore Everything preserve all events in time order', () {
    final relevance = ArcEventRelevance(
      profile: profile(ArcPersonalisationGoal.completeBlueprints),
      blueprints: {
        'surge-coil': ArcBlueprintState.empty(
          'surge-coil',
        ).copyWith(priorityRank: 1),
      },
    );
    expect(
      relevance
          .rank(nowUtc: now, slots: slots, showAll: true)
          .first
          .slot
          .eventName,
      'Hurricane',
    );
    final everything = ArcEventRelevance(
      profile: relevance.profile.copyWith(
        goals: {ArcPersonalisationGoal.exploreEverything},
      ),
      blueprints: relevance.blueprints,
    );
    final events = everything.rank(nowUtc: now, slots: slots);
    expect(events.length, slots.length);
    expect(events.first.slot.eventName, 'Hurricane');
  });

  test(
    'active first, end boundary advances to next day, empty stays empty',
    () {
      final relevance = ArcEventRelevance(
        profile: profile(ArcPersonalisationGoal.completeBlueprints),
        blueprints: {},
      );
      expect(
        relevance
            .rank(nowUtc: now.add(const Duration(hours: 1)), slots: slots)
            .first
            .isActive(now.add(const Duration(hours: 1))),
        isTrue,
      );
      final atEnd = relevance.rank(
        nowUtc: now.add(const Duration(hours: 2)),
        slots: [slots.first],
      );
      expect(atEnd.single.startUtc.day, 22);
      expect(relevance.rank(nowUtc: now, slots: []), isEmpty);
    },
  );
}
