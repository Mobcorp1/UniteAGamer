import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';

class ArcCommandSystemDetailMapper {
  const ArcCommandSystemDetailMapper._();

  static ArcCommandSummaryPanel panelFor({
    required ArcCommandCentreState state,
    required String title,
    required String value,
    required String detail,
    required ArcCommandStatus status,
    required ArcCommandAction action,
  }) {
    final key = _key(title);
    if (key.contains('blueprint')) return state.blueprintSummary;
    if (key.contains('raid') || key.contains('route')) {
      return state.raidIntelligenceSummary;
    }
    if (key.contains('bench')) return state.benchSummary;
    if (key.contains('resource') || key.contains('inventory')) {
      return state.resourceSummary;
    }
    if (key.contains('quest')) return state.questSummary;
    if (key.contains('operation') ||
        key.contains('reward') ||
        key.contains('vault')) {
      return state.operationsSummary;
    }
    if (key.contains('nomadic') || key.contains('trader')) {
      return state.weeklyTraderSummary;
    }
    if (key.contains('community') || key.contains('trade')) {
      return state.communitySummary;
    }
    if (key.contains('stat')) return state.statisticsSummary;
    if (key.contains('decision') || key.contains('mission')) {
      return state.decisionSummary;
    }
    return ArcCommandSummaryPanel(
      title: title,
      statusLabel: value,
      body: detail,
      details: [
        if (value.trim().isNotEmpty) value,
        if (detail.trim().isNotEmpty) detail,
      ],
      status: status,
      action: action,
    );
  }

  static List<ArcCommandSummaryPanel> overviewPanels(
    ArcCommandCentreState state,
    ArcCommandSummaryPanel selected,
  ) {
    final selectedKey = _key(selected.title);
    final panels = [
      state.blueprintSummary,
      state.benchSummary,
      state.resourceSummary,
      state.raidIntelligenceSummary,
      state.questSummary,
      state.operationsSummary,
      state.weeklyTraderSummary,
      state.communitySummary,
      state.statisticsSummary,
      state.decisionSummary,
    ];
    final seen = <String>{selectedKey};
    return [
      for (final panel in panels)
        if (seen.add(_key(panel.title))) panel,
    ].take(4).toList(growable: false);
  }

  static String _key(String value) => value.trim().toLowerCase();
}
