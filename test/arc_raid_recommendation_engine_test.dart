import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_recommendation_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raider_goal_models.dart';

void main() {
  const engine = ArcRaidRecommendationEngine();

  group('ArcRaidRecommendationEngine', () {
    test('prefers the raid that progresses the most active quests', () {
      final result = engine.build(
        goals: const <ArcRaiderGoal>[
          ArcRaiderGoal(
            id: 'quest:a',
            label: 'Quest A',
            source: ArcRaiderGoalSource.quest,
            cooperation: ArcRaiderGoalCooperation.cooperative,
            priority: 4,
            mapNames: <String>['Spaceport'],
            routeConfidence: ArcRaiderGoalRouteConfidence.verified,
          ),
          ArcRaiderGoal(
            id: 'quest:b',
            label: 'Quest B',
            source: ArcRaiderGoalSource.quest,
            cooperation: ArcRaiderGoalCooperation.cooperative,
            priority: 4,
            mapNames: <String>['Spaceport'],
            routeConfidence: ArcRaiderGoalRouteConfidence.verified,
          ),
          ArcRaiderGoal(
            id: 'blueprint:c',
            label: 'Blueprint C',
            source: ArcRaiderGoalSource.blueprint,
            cooperation: ArcRaiderGoalCooperation.scarceSharedLoot,
            priority: 5,
            mapNames: <String>['The Blue Gate'],
            routeConfidence: ArcRaiderGoalRouteConfidence.verified,
          ),
        ],
        candidates: const <ArcRaidCandidate>[
          ArcRaidCandidate(
            mapName: 'Spaceport',
            conditionName: 'No event / standard raid',
            isLive: true,
          ),
          ArcRaidCandidate(
            mapName: 'The Blue Gate',
            conditionName: 'No event / standard raid',
            isLive: true,
          ),
        ],
      );

      expect(result.bestNow?.candidate.mapName, 'Spaceport');
      expect(result.bestNow?.questGoalCount, 2);
      expect(result.bestNow?.goalCount, 2);
    });

    test('preferred condition boosts an otherwise matching map', () {
      final now = DateTime.utc(2026, 9, 24, 12);
      final result = engine.build(
        nowUtc: now,
        goals: const <ArcRaiderGoal>[
          ArcRaiderGoal(
            id: 'blueprint:surge',
            label: 'Surge Coil',
            source: ArcRaiderGoalSource.blueprint,
            cooperation: ArcRaiderGoalCooperation.scarceSharedLoot,
            priority: 5,
            mapNames: <String>['All maps'],
            conditionNames: <String>['Electromagnetic Storm'],
            conditionFit: ArcRaiderGoalConditionFit.preferred,
            routeConfidence: ArcRaiderGoalRouteConfidence.strong,
          ),
        ],
        candidates: <ArcRaidCandidate>[
          const ArcRaidCandidate(
            mapName: 'The Blue Gate',
            conditionName: 'No event / standard raid',
            isLive: true,
          ),
          ArcRaidCandidate(
            mapName: 'The Blue Gate',
            conditionName: 'Electromagnetic Storm',
            isLive: true,
            startUtc: now.subtract(const Duration(minutes: 10)),
            endUtc: now.add(const Duration(minutes: 50)),
          ),
        ],
      );

      expect(result.bestNow?.candidate.conditionName, 'Electromagnetic Storm');
    });

    test('required condition does not score a mismatched window', () {
      final result = engine.build(
        goals: const <ArcRaiderGoal>[
          ArcRaiderGoal(
            id: 'blueprint:dolabra',
            label: 'Dolabra',
            source: ArcRaiderGoalSource.blueprint,
            cooperation: ArcRaiderGoalCooperation.scarceSharedLoot,
            priority: 5,
            mapNames: <String>['All maps'],
            conditionNames: <String>['Close Scrutiny'],
            conditionFit: ArcRaiderGoalConditionFit.required,
            routeConfidence: ArcRaiderGoalRouteConfidence.verified,
          ),
        ],
        candidates: const <ArcRaidCandidate>[
          ArcRaidCandidate(
            mapName: 'Spaceport',
            conditionName: 'Hurricane',
            isLive: true,
          ),
          ArcRaidCandidate(
            mapName: 'Spaceport',
            conditionName: 'Close Scrutiny',
            isLive: true,
          ),
        ],
      );

      expect(result.ranked, hasLength(1));
      expect(result.bestNow?.candidate.conditionName, 'Close Scrutiny');
    });

    test('unrouted quests never invent a map recommendation', () {
      final result = engine.build(
        goals: const <ArcRaiderGoal>[
          ArcRaiderGoal(
            id: 'quest:unknown-route',
            label: 'Future Quest',
            source: ArcRaiderGoalSource.quest,
            cooperation: ArcRaiderGoalCooperation.cooperative,
            priority: 5,
          ),
        ],
        candidates: const <ArcRaidCandidate>[
          ArcRaidCandidate(
            mapName: 'Spaceport',
            conditionName: 'No event / standard raid',
            isLive: true,
          ),
        ],
      );

      expect(result.ranked, isEmpty);
      expect(result.bestNow, isNull);
    });

    test('quest pickup alignment is cooperative, not scarce competition', () {
      const goal = ArcRaiderGoal(
        id: 'quest:pickup',
        label: 'Quest pickup',
        source: ArcRaiderGoalSource.quest,
        cooperation: ArcRaiderGoalCooperation.cooperative,
        priority: 4,
        mapNames: <String>['Buried City'],
        routeConfidence: ArcRaiderGoalRouteConfidence.verified,
      );

      expect(goal.cooperative, isTrue);
      expect(goal.scarceSharedLoot, isFalse);
    });
  });
}
