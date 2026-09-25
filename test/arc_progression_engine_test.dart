import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_progression_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';

void main() {
  const engine = ArcProgressionEngine();

  group('ArcProgressionEngine quest graph', () {
    test('starts at the root and advances after manual in-game completion', () {
      final firstQuest = engine.questDefinitions.first;
      final initial = engine.buildQuestSnapshot(scrappyStates: const {});

      expect(firstQuest.questId, 'quest-chain-shani-picking-up-the-pieces');
      expect(initial.activeQuest?.questId, firstQuest.questId);
      expect(initial.activeQuest?.locked, isFalse);

      final record = engine.completeQuestRecord(
        snapshot: initial,
        questId: firstQuest.questId,
      );
      final advanced = engine.buildQuestSnapshot(
        scrappyStates: const {},
        records: {firstQuest.questId: record},
      );

      expect(advanced.completedCount, 1);
      expect(advanced.activeQuest?.questId, isNot(firstQuest.questId));
      expect(advanced.activeQuest?.locked, isFalse);
    });
  });

  group('ArcProgressionEngine Scrappy progression', () {
    test('confirms the next Scrappy level once resources are ready', () {
      final nextUpgrade = engine.scrappyDefinitions.first;
      final completedStates = {
        for (final objective in nextUpgrade.objectives)
          objective.id: ArcScrappyState(
            itemId: objective.id,
            collectedCount: objective.requiredCount,
          ),
      };
      final ready = engine.buildScrappySnapshot(scrappyStates: completedStates);

      expect(ready.readyToUpgrade, isTrue);
      expect(ready.nextLevel, nextUpgrade.level);

      final confirmed = engine.confirmScrappyLevel(
        snapshot: ready,
        level: nextUpgrade.level,
      );

      expect(confirmed.currentLevel, nextUpgrade.level);
      expect(confirmed.maximumLevelReachedThisSeason, nextUpgrade.level);
      expect(confirmed.historicalMaximumLevel, nextUpgrade.level);
      expect(
        confirmed.completedLevelIds,
        contains('scrappy-lv-${nextUpgrade.level}'),
      );
    });
  });

  group('ArcProgressionEngine bench progression', () {
    test('confirms one station level without advancing other benches', () {
      final gunsmithLevelOne = engine.benchDefinitions.firstWhere(
        (definition) =>
            definition.station == 'Gunsmith' && definition.level == 1,
      );
      final completedStates = {
        for (final objective in gunsmithLevelOne.objectives)
          objective.id: ArcScrappyState(
            itemId: objective.id,
            collectedCount: objective.requiredCount,
          ),
      };
      final ready = engine.buildBenchSnapshot(scrappyStates: completedStates);

      expect(ready.readyToUpgrade, isTrue);
      expect(ready.nextUpgrade?.station, 'Gunsmith');
      expect(ready.nextUpgrade?.level, 1);

      final record = engine.confirmBenchLevel(
        snapshot: ready,
        scrappyStates: completedStates,
        station: 'Gunsmith',
        level: 1,
      );

      expect(record.currentLevel, 1);
      expect(record.completedLevelIds, contains('bench-gunsmith-lv-1'));

      final advanced = engine.buildBenchSnapshot(
        scrappyStates: completedStates,
        records: {record.benchId: record},
      );

      expect(advanced.recordsByBenchId[record.benchId]?.currentLevel, 1);
      expect(advanced.nextUpgrade?.station, 'Gunsmith');
      expect(advanced.nextUpgrade?.level, 2);
    });
  });

  group('Command Centre progression integration', () {
    test(
      'uses completed quest records when choosing the active quest summary',
      () {
        final firstQuest = engine.questDefinitions.first;
        final completedStates = {
          for (final objective in firstQuest.objectives)
            objective.id: ArcScrappyState(
              itemId: objective.id,
              collectedCount: objective.requiredCount,
            ),
        };
        final ready = engine.buildQuestSnapshot(scrappyStates: completedStates);
        final record = engine.completeQuestRecord(
          snapshot: ready,
          questId: firstQuest.questId,
        );

        final state = ArcCommandCentreEngine.build(
          blueprintStates: const {},
          savedLoadouts: const [],
          scrappyStates: completedStates,
          progressionRecords: ArcProgressionRecords(
            seasonId: ready.seasonId,
            questRecords: {firstQuest.questId: record},
            scrappyState: ArcScrappyProgressionState.empty,
            benchRecords: const {},
          ),
        );

        expect(state.questSummary.details.first, contains('1/'));
        expect(
          state.questSummary.details.where(
            (detail) => detail.contains(firstQuest.questLabel),
          ),
          isEmpty,
        );
      },
    );
  });
}
