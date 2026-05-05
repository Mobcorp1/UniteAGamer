import 'package:uag_traders_hub/features/trading_hub/arc_raiders/raid_planner/models/raid_planner_models.dart';

class RaidPlannerBlueprintRules {
  static const List<RaidPlannerBlueprintRule> rules = [
    RaidPlannerBlueprintRule(
      blueprintId: 'surge-coil',
      blueprintName: 'Surge Coil',
      eventName: 'Electromagnetic Storm',
      reason: 'Best tracked opportunity during Electromagnetic Storm windows.',
    ),
    RaidPlannerBlueprintRule(
      blueprintId: 'canto',
      blueprintName: 'Canto',
      eventName: 'Hurricane',
      reason: 'Best tracked opportunity during Hurricane windows.',
    ),
    RaidPlannerBlueprintRule(
      blueprintId: 'dolabra',
      blueprintName: 'Dolabra',
      eventName: 'Close Scrutiny',
      reason: 'Best tracked opportunity during Close Scrutiny windows.',
    ),
  ];

  static RaidPlannerBlueprintRule? byBlueprintId(String blueprintId) {
    for (final rule in rules) {
      if (rule.blueprintId == blueprintId) return rule;
    }
    return null;
  }
}
