import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'endpoint reconciliation resolves current selection against latest snapshot',
    () {
      final source = File(
        'lib/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart',
      ).readAsStringSync();

      expect(source, contains('final currentSpawn = _spawn;'));
      expect(source, contains('final currentExit = _extraction;'));
      expect(source, contains('latest.resolveSpawn(currentSpawn)'));
      expect(
        source,
        contains('latest.resolveExtraction(currentExit, hatch: _usesHatch)'),
      );

      expect(source, isNot(contains('_spawn != oldSpawn')));
      expect(source, isNot(contains('_extraction != oldExit')));
    },
  );
}
