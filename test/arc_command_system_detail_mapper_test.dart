import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_system_detail_mapper.dart';

void main() {
  group('ArcCommandSystemDetailMapper', () {
    test('maps selected carousel systems to their live summary panels', () {
      final state = _commandState();

      final selected = ArcCommandSystemDetailMapper.panelFor(
        state: state,
        title: 'Blueprint Tracker',
        value: 'Stable',
        detail: 'Open tracker',
        status: ArcCommandStatus.active,
        action: _action,
      );

      expect(selected.title, 'Blueprint Summary');
      expect(selected.details, contains('9/10 owned'));
    });

    test('builds a useful fallback detail panel for non-summary systems', () {
      final state = _commandState();

      final selected = ArcCommandSystemDetailMapper.panelFor(
        state: state,
        title: 'Favourite Loadout',
        value: 'Ready',
        detail: 'Anvil / Stitcher / Survivor',
        status: ArcCommandStatus.success,
        action: _action,
      );

      expect(selected.title, 'Favourite Loadout');
      expect(selected.statusLabel, 'Ready');
      expect(selected.details, contains('Anvil / Stitcher / Survivor'));
    });

    test('omits the selected panel from supporting system overview', () {
      final state = _commandState();
      final selected = state.resourceSummary;

      final overview = ArcCommandSystemDetailMapper.overviewPanels(
        state,
        selected,
      );

      expect(
        overview.map((panel) => panel.title),
        isNot(contains('Resources')),
      );
      expect(overview, isNotEmpty);
    });
  });
}

const _action = ArcCommandAction(label: 'Open');

ArcCommandCentreState _commandState() {
  final blueprint = _panel(
    title: 'Blueprint Summary',
    statusLabel: 'Active',
    details: const ['9/10 owned', '1 missing'],
  );
  final resources = _panel(
    title: 'Resources',
    statusLabel: 'Stable',
    details: const ['No missing resources'],
  );
  return ArcCommandCentreState(
    priority: const ArcCommandPriority(
      title: 'Today',
      explanation: 'Ready',
      progressLabel: 'Stable',
      statusTag: 'Stable',
      detail: 'No urgent action',
      status: ArcCommandStatus.success,
      primaryAction: _action,
    ),
    snapshots: const [],
    objectives: const [],
    alerts: const [],
    recommendations: const [],
    checklist: const [],
    resources: const [],
    tradeSummary: const ArcCommandTradeSummary(
      lookingFor: [],
      offering: [],
      actions: [],
    ),
    blueprintSummary: blueprint,
    questSummary: _panel(title: 'Quest Summary'),
    benchSummary: _panel(title: 'Bench Summary'),
    operationsSummary: _panel(title: 'Operations Summary'),
    weeklyTraderSummary: _panel(title: 'Nomadic Trader Summary'),
    resourceSummary: resources,
    decisionSummary: _panel(title: 'Decision Summary'),
    communitySummary: _panel(title: 'Community Summary'),
    statisticsSummary: _panel(title: 'Statistics Summary'),
  );
}

ArcCommandSummaryPanel _panel({
  required String title,
  String statusLabel = 'Stable',
  List<String> details = const ['No blockers'],
}) {
  return ArcCommandSummaryPanel(
    title: title,
    statusLabel: statusLabel,
    body: details.first,
    details: details,
    status: ArcCommandStatus.success,
    action: _action,
  );
}
