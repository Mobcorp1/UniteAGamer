import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_progress_policy.dart';

void main() {
  group('ArcCommandCentreProgressPolicy', () {
    test('uses explicit percentage evidence', () {
      expect(
        ArcCommandCentreProgressPolicy.measuredPercent(
          status: ArcCommandStatus.active,
          label: 'Progress',
          detail: 'Collection is 67% complete',
        ),
        67,
      );
    });

    test('derives progress from explicit fractions', () {
      expect(
        ArcCommandCentreProgressPolicy.measuredPercent(
          status: ArcCommandStatus.warning,
          label: 'Blueprints',
          detail: '7/10 owned',
        ),
        70,
      );
    });

    test('never invents progress from status labels', () {
      for (final status in <ArcCommandStatus>[
        ArcCommandStatus.ready,
        ArcCommandStatus.active,
        ArcCommandStatus.warning,
        ArcCommandStatus.critical,
        ArcCommandStatus.neutral,
      ]) {
        expect(
          ArcCommandCentreProgressPolicy.measuredPercent(
            status: status,
            label: status.name,
            detail: 'Open the relevant system',
          ),
          isNull,
          reason: status.name,
        );
      }
    });

    test('completed status remains complete without text evidence', () {
      expect(
        ArcCommandCentreProgressPolicy.measuredPercent(
          status: ArcCommandStatus.success,
          label: 'Done',
          detail: 'Complete',
        ),
        100,
      );
    });
  });
}
