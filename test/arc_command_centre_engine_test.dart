import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';

void main() {
  group('ArcCommandCentreEngine route wiring', () {
    test('weekly raid checklist opens the real Raid Planner route', () {
      final state = ArcCommandCentreEngine.build(
        blueprintStates: const {},
        savedLoadouts: const [],
      );

      final weeklyRaid = state.checklist.singleWhere(
        (item) => item.id == 'weekly-raid',
      );

      expect(weeklyRaid.action.label, 'Raid Planner');
      expect(weeklyRaid.action.intent, ArcCommandActionIntent.route);
      expect(weeklyRaid.action.routeName, RaidPlannerScreen.routeName);
      expect(weeklyRaid.action.placeholderMessage, isNull);
    });
  });
}
