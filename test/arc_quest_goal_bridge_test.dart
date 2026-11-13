import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_progression_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/data/arc_raider_goal_bridge.dart';

void main() {
  const progression = ArcProgressionEngine();

  test('quest definitions come from the complete catalogue', () {
    final definitions = progression.questDefinitions;
    expect(definitions, hasLength(100));
    expect(definitions.first.questId, ArcQuestCatalogue.rootQuestId);
  });

  test('only current selected quests feed cooperative raid goals', () {
    final target = ArcQuestCatalogue.findByName('A First Foothold')!;
    final snapshot = progression.buildQuestSnapshot(
      scrappyStates: const {},
      trackedQuestIds: <String>{target.id},
    );

    final goals = ArcRaiderGoalBridge.questGoals(snapshot);

    expect(goals, hasLength(1));
    expect(goals.single.id, 'quest:${target.id}');
    expect(goals.single.cooperative, isTrue);
    expect(goals.single.mapNames, contains('The Blue Gate'));
  });

  test('unrouted current quest never invents a map', () {
    final root = ArcQuestCatalogue.byId[ArcQuestCatalogue.rootQuestId]!;
    final snapshot = progression.buildQuestSnapshot(
      scrappyStates: const {},
      trackedQuestIds: <String>{root.id},
    );

    final goals = ArcRaiderGoalBridge.questGoals(snapshot);

    expect(goals, hasLength(1));
    expect(goals.single.mapNames, isEmpty);
    expect(goals.single.routable, isFalse);
  });

  test('legacy requirement rows remain attached where the quest matches', () {
    final clearSkies = progression.questDefinitions.firstWhere(
      (definition) => definition.questName == 'Clearer Skies',
    );
    expect(clearSkies.objectives, isNotEmpty);
  });
}
