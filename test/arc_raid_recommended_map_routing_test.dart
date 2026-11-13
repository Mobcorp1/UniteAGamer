import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_raid_launch_map_policy.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';

void main() {
  group('recommended Raid Intelligence map routing', () {
    test('Command Centre carries the stable recommended map id', () {
      final state = ArcCommandCentreEngine.build(
        blueprintStates: const {},
        savedLoadouts: const [],
      );

      expect(
        state.raidIntelligenceSummary.action.routeName,
        ArcRaidIntelligenceScreen.routeName,
      );
      expect(state.raidIntelligenceSummary.action.routeArguments, 'blue_gate');
    });

    test('canonical aliases become supported stable ids', () {
      expect(
        ArcRaidLaunchMapPolicy.canonicalExplicitMapId('Blue Gate'),
        'blue_gate',
      );
      expect(
        ArcRaidLaunchMapPolicy.canonicalExplicitMapId('Stella Montis'),
        'stella_montis',
      );
      expect(
        ArcRaidLaunchMapPolicy.canonicalExplicitMapId('blue_gate'),
        'blue_gate',
      );
      expect(
        ArcRaidLaunchMapPolicy.canonicalExplicitMapId('not-a-real-map'),
        isNull,
      );
    });

    test('explicit recommended map rejects a stale route on another map', () {
      expect(
        ArcRaidLaunchMapPolicy.routeCanApply(
          explicitMapId: 'blue_gate',
          routeMapId: 'stella_montis',
        ),
        isFalse,
      );
      expect(
        ArcRaidLaunchMapPolicy.routeCanApply(
          explicitMapId: 'blue_gate',
          routeMapId: 'Blue Gate',
        ),
        isTrue,
      );
    });

    test('manual entry keeps remembered-map restore behaviour', () {
      expect(
        ArcRaidLaunchMapPolicy.shouldRestoreLastMap(explicitMapId: null),
        isTrue,
      );
      expect(
        ArcRaidLaunchMapPolicy.shouldRestoreLastMap(explicitMapId: 'blue_gate'),
        isFalse,
      );
    });

    test('route plumbing forwards action arguments into the screen', () {
      final commandSource = File(
        'lib/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart',
      ).readAsStringSync();
      final mainSource = File('lib/main.dart').readAsStringSync();
      final raidSource = File(
        'lib/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart',
      ).readAsStringSync();

      expect(commandSource, contains('arguments: action.routeArguments'));
      expect(mainSource, contains('initialMapId: requestedMapId'));
      expect(
        raidSource,
        contains('ArcRaidLaunchMapPolicy.canonicalExplicitMapId'),
      );
      expect(raidSource, contains('widget.initialMapId'));
      expect(raidSource, contains('final String? initialMapId;'));
      expect(
        raidSource,
        contains('ArcRaidLaunchMapPolicy.shouldRestoreLastMap('),
      );
    });
  });
}
