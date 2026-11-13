import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Raid Planner consumes regional official Map Conditions intelligence', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart',
    ).readAsStringSync();

    expect(source, contains('Regional Blueprint Opportunities'));
    expect(source, contains('Condition Item Finder'));
    expect(source, contains('Regional Condition Finder'));
    expect(source, contains('Your ARC server region'));
    expect(source, contains('Switch ARC server to'));
    expect(source, contains('ArcRegionalMapConditionsService.load'));
    expect(source, contains('watchMyBlueprintStates'));
    expect(source, contains('watchAvailability'));
  });

  test('regional source is the official ARC Raiders tracker', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_map_conditions.dart',
    ).readAsStringSync();

    expect(source, contains('https://arcraiders.com/map-conditions'));
    expect(source, contains('regionTimestamps'));
    expect(source, contains('north-america'));
    expect(source, contains('brazil'));
    expect(source, contains('east-asia'));
    expect(source, contains('oceania'));
    expect(source, contains('officialCapturedFallback'));
  });

  test('verified Blueprint condition rules include the requested hunt set', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/raid_planner/data/arc_regional_opportunity_engine.dart',
    ).readAsStringSync();

    expect(source, contains("'dolabra'"));
    expect(source, contains("'surge-coil'"));
    expect(source, contains("'jupiter'"));
    expect(source, contains("'equalizer'"));
    expect(source, contains("'wolfpack'"));
    expect(source, contains("'vulcano'"));
    expect(source, contains("'bobcat'"));
    expect(source, contains("'tempest'"));
  });
}
