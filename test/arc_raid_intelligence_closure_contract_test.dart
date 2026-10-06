import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Raid Intelligence consumes closure inputs and live recommendation', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart',
    ).readAsStringSync();

    expect(source, contains('ArcLiveRaidRecommendationEngine'));
    expect(source, contains('watchUserState()'));
    expect(source, contains('watchTargets()'));
    expect(source, contains('watchEntitlement()'));
    expect(source, contains('_timeBudgetMinutes'));
    expect(source, contains('activeConditionLabel: activeConditionLabel'));
    expect(source, contains('timeBudgetMinutes: _timeBudgetMinutes'));
    expect(source, contains('BEST RAID NOW'));
    expect(source, contains('USE THIS RAID'));
  });

  test('route plan persists budget and condition context', () {
    final model = File(
      'lib/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart',
    ).readAsStringSync();
    final repository = File(
      'lib/features/trading_hub/arc_raiders/repositories/arc_raid_intelligence_repository.dart',
    ).readAsStringSync();

    expect(model, contains('final int? timeBudgetMinutes;'));
    expect(model, contains('final String? conditionLabel;'));
    expect(
      repository,
      contains("'timeBudgetMinutes': route.timeBudgetMinutes"),
    );
    expect(repository, contains("'conditionLabel': route.conditionLabel"));
  });

  test('route selection is budgeted and condition-aware', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart',
    ).readAsStringSync();

    expect(source, contains('_selectClustersForBudget'));
    expect(source, contains('_matchesActiveCondition'));
    expect(source, contains('valuePerMinute'));
    expect(source, contains('timeBudgetMinutes?.clamp(5, 60)'));
  });
}
