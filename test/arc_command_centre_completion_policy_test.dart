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
  });
}
