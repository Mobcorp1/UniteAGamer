import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pass 17 major visual convergence contracts are present', () {
    final raid = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart',
    ).readAsStringSync();
    final hunt = File(
      'lib/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_hunt_targets_screen.dart',
    ).readAsStringSync();
    final rat = File(
      'lib/features/trust/screens/arc_raider_contracts_screen.dart',
    ).readAsStringSync();
    final hub = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_raiders_hub_screen.dart',
    ).readAsStringSync();

    expect(raid, contains('RAID SETUP'));
    expect(raid, contains('INTEL FILTERS'));
    expect(raid, contains('COMMUNITY INTEL'));
    expect(raid, contains('_raidAccordion'));
    expect(hunt, contains('EXPEDITION RESET FOCUS'));
    expect(hunt, contains('NOMADIC RAIDER PATH'));
    expect(hunt, contains('_HuntGuidanceAccordion'));
    expect(hunt, contains('HUNT CONTROL'));
    expect(rat, contains('class _ReportRatHero extends StatelessWidget'));
    expect(rat, contains("Text('REPORT A RAT'"));
    expect(
      rat,
      contains(
        'Private report. Moderator reviewed. No public accusation is created.',
      ),
    );
    expect(hub, contains("'DISCOVER UAG'"));
  });
}
