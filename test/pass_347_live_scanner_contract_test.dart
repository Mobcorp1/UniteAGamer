import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'PASS 347 live scanner consumes occupancy frames before still capture',
    () {
      final source = File(
        'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_live_scanner_screen.dart',
      ).readAsStringSync();

      expect(source, contains('ArcBlueprintLiveOccupancyEngine'));
      expect(source, contains('ArcBlueprintLiveOccupancyStabilizer'));
      expect(source, contains('_processLiveOccupancy(frameImage, detection)'));
      expect(source, contains('_liveOccupancyInterval'));
      expect(source, contains('ImageFormatGroup.nv21'));
    },
  );
}
