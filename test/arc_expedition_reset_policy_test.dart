import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_season_reset_models.dart';

void main() {
  group('Arc expedition reset policy', () {
    test(
      'blueprints are expedition-scoped while permanent identity persists',
      () {
        expect(
          ArcSeasonResetPolicy.resetSystems,
          contains('Current-expedition blueprint ownership and duplicates'),
        );
        expect(
          ArcSeasonResetPolicy.persistentSystems,
          contains('Profile identity'),
        );
        expect(ArcSeasonResetPolicy.persistentSystems, contains('Reputation'));
        expect(
          ArcSeasonResetPolicy.persistentSystems,
          contains('Favourite Raiders'),
        );
      },
    );

    test('preview exposes blueprint reset impact separately from trackers', () {
      final impacts = ArcSeasonResetPolicy.impacts(
        blueprintStateCount: 74,
        scrappyStateCount: 12,
        questStateCount: 8,
        benchStateCount: 6,
        operationProgressCount: 4,
        rewardCount: 9,
      );

      final blueprintImpact = impacts.singleWhere(
        (impact) => impact.id == 'blueprints',
      );
      expect(
        blueprintImpact.classification,
        ArcSeasonResetClassification.reset,
      );
      expect(blueprintImpact.itemCount, 74);

      final rewardImpact = impacts.singleWhere(
        (impact) => impact.id == 'rewards',
      );
      expect(
        rewardImpact.classification,
        ArcSeasonResetClassification.preserved,
      );
    });

    test('apply result records blueprint and tracker resets independently', () {
      final result = ArcSeasonResetApplyResult(
        resetId: 'reset-1',
        archivedSeasonId: 'season-1',
        currentSeasonId: 'season-2',
        resetVersion: 2,
        completedAt: DateTime.utc(2026, 7, 21),
        resetBlueprintIds: const <String>['bp-1', 'bp-2'],
        resetStateIds: const <String>['scrappy-1', 'bench-1'],
      );

      expect(result.toMap()['resetBlueprintIds'], <String>['bp-1', 'bp-2']);
      expect(result.toMap()['resetStateIds'], <String>['scrappy-1', 'bench-1']);
    });
  });
}
