import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';

void main() {
  const action = ArcCommandAction(label: 'Open');

  group('ArcCommandCentreCompletionPolicy', () {
    test('removes objectives that report one hundred percent completion', () {
      const objective = ArcCommandObjective(
        title: 'Upgrade Gunsmith',
        reason: 'Gunsmith level 1 resources are complete.',
        statusLabel: 'Ready',
        progressText: '4/4 resources - 100%',
        status: ArcCommandStatus.ready,
        action: action,
      );

      expect(
        ArcCommandCentreCompletionPolicy.objectiveIsActionable(objective),
        isFalse,
      );
    });

    test('keeps incomplete objectives actionable', () {
      const objective = ArcCommandObjective(
        title: 'Upgrade Gunsmith',
        reason: 'Two resources are still missing.',
        statusLabel: 'Active',
        progressText: '2/4 resources - 50%',
        status: ArcCommandStatus.active,
        action: action,
      );

      expect(
        ArcCommandCentreCompletionPolicy.objectiveIsActionable(objective),
        isTrue,
      );
    });

    test('removes checklist items already completed by live state', () {
      const item = ArcCommandChecklistItem(
        id: 'upgrade-scrappy',
        label: 'Upgrade Scrappy',
        reason: 'All tracked Scrappy upgrades are complete.',
        action: action,
        doneByDefault: true,
      );

      expect(
        ArcCommandCentreCompletionPolicy.checklistItemIsActionable(item),
        isFalse,
      );
    });

    test('removes claimed and stale previous expedition objectives', () {
      const claimed = ArcCommandObjective(
        title: 'Claim Closed Beta Reward',
        reason: 'Reward claimed for this expedition.',
        statusLabel: 'Claimed',
        progressText: 'Claimed',
        status: ArcCommandStatus.ready,
        action: action,
      );
      const stale = ArcCommandObjective(
        title: 'Complete Hunt Target',
        reason: 'Completed for previous expedition.',
        statusLabel: 'Stale',
        progressText: 'Previous expedition',
        status: ArcCommandStatus.active,
        action: action,
      );

      expect(
        ArcCommandCentreCompletionPolicy.objectiveIsActionable(claimed),
        isFalse,
      );
      expect(
        ArcCommandCentreCompletionPolicy.objectiveIsActionable(stale),
        isFalse,
      );
    });

    test('keeps newly eligible expedition objectives actionable', () {
      const objective = ArcCommandObjective(
        title: 'Claim Operation Rewards',
        reason: 'One operation reward is ready in the current expedition.',
        statusLabel: 'Ready',
        progressText: '1 ready to claim',
        status: ArcCommandStatus.ready,
        action: action,
      );

      expect(
        ArcCommandCentreCompletionPolicy.objectiveIsActionable(objective),
        isTrue,
      );
    });

    test('removes quiet success alerts from blockers', () {
      const alert = ArcCommandAlert(
        title: 'Command centre quiet',
        body: 'No live blockers are waiting.',
        statusLabel: 'Clear',
        status: ArcCommandStatus.success,
        action: action,
      );

      expect(
        ArcCommandCentreCompletionPolicy.alertIsActionable(alert),
        isFalse,
      );
    });
  });
}
