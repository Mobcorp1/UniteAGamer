import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raider_goal_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_raider_goal_bridge.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/raid_planner_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/models/raid_planner_models.dart';

void main() {
  group('Raid Planner shared goal bridge', () {
    test('active quest route can outweigh an unrelated Blueprint hunt', () {
      const questDefinition = ArcQuestProgressionDefinition(
        questId: 'quest-spaceport',
        trader: 'Shani',
        questName: 'Spaceport Objective',
        order: 1,
        prerequisiteQuestIds: <String>[],
        objectives: <ArcProgressionObjective>[
          ArcProgressionObjective(
            id: 'objective-a',
            label: 'Use the terminal',
            requiredCount: 1,
            currentCount: 0,
          ),
        ],
      );
      final snapshot = ArcQuestProgressionSnapshot(
        seasonId: 'season-test',
        entries: <ArcQuestProgressionEntry>[
          ArcQuestProgressionEntry(
            definition: questDefinition,
            status: ArcProgressionStatus.active,
            objectives: questDefinition.objectives,
          ),
        ],
        completedQuestIds: <String>{},
        archivedQuestIds: <String>{},
        trackingKnown: true,
      );

      final result = RaidPlannerEngine.buildGoalRecommendations(
        effectiveTargets: const <RaidBlueprintTarget>[],
        questSnapshot: snapshot,
        questRouteHints: const <String, ArcQuestRouteHint>{
          'quest-spaceport': ArcQuestRouteHint(
            questId: 'quest-spaceport',
            mapNames: <String>['Spaceport'],
            confidence: ArcRaiderGoalRouteConfidence.verified,
          ),
        },
        nowUtc: DateTime.utc(2026, 9, 24, 12),
      );

      expect(result.ranked, isNotEmpty);
      expect(result.ranked.first.candidate.mapName, 'Spaceport');
      expect(result.ranked.first.questGoalCount, 1);
    });

    test('quest goals remain cooperative in the planner bridge', () {
      const definition = ArcQuestProgressionDefinition(
        questId: 'quest-shared-pickup',
        trader: 'Celeste',
        questName: 'Shared Route',
        order: 1,
        prerequisiteQuestIds: <String>[],
        objectives: <ArcProgressionObjective>[
          ArcProgressionObjective(
            id: 'quest-item',
            label: 'Collect quest item',
            requiredCount: 1,
            currentCount: 0,
          ),
        ],
      );
      final snapshot = ArcQuestProgressionSnapshot(
        seasonId: 'season-test',
        entries: <ArcQuestProgressionEntry>[
          ArcQuestProgressionEntry(
            definition: definition,
            status: ArcProgressionStatus.active,
            objectives: definition.objectives,
          ),
        ],
        completedQuestIds: <String>{},
        archivedQuestIds: <String>{},
        trackingKnown: true,
      );

      final goals = ArcRaiderGoalBridge.questGoals(
        snapshot,
        routeHints: const <String, ArcQuestRouteHint>{
          'quest-shared-pickup': ArcQuestRouteHint(
            questId: 'quest-shared-pickup',
            mapNames: <String>['Buried City'],
          ),
        },
      );

      expect(goals.single.cooperation, ArcRaiderGoalCooperation.cooperative);
    });
  });
}
