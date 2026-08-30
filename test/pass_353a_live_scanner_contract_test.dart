import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final scanner = File(
    'lib/features/trading_hub/arc_raiders/screens/'
    'arc_blueprint_live_scanner_screen.dart',
  ).readAsStringSync();

  final occupancy = File(
    'lib/features/trading_hub/arc_raiders/data/'
    'arc_blueprint_live_occupancy_engine.dart',
  ).readAsStringSync();

  final result = File(
    'lib/features/trading_hub/arc_raiders/data/'
    'arc_blueprint_live_scan_result_engine.dart',
  ).readAsStringSync();

  test('PASS 353A raises live camera and detector detail', () {
    expect(scanner, contains('ResolutionPreset.high'));
    expect(scanner, contains('const maxPreviewWidth = 720'));
    expect(scanner, contains('analysisWidth: 640'));
    expect(scanner, contains('final detectionRows = 5'));
  });

  test('PASS 353A exposes detector failure telemetry', () {
    expect(scanner, contains('Grid detector: no lock'));
    expect(scanner, contains('Grid detector: confidence='));
  });

  test('PASS 353A perspective-corrects before occupancy recognition', () {
    expect(occupancy, contains('ArcBlueprintPerspectiveCropper'));
    expect(occupancy, contains('rectifyDetection'));
  });

  test('PASS 353A does not hard-code 83 result positions', () {
    expect(result, contains('ArcBlueprintSeedData.blueprints.length'));
    expect(result, isNot(contains('ArcBlueprintCanonicalGrid.totalPositions')));
  });

  test('PASS 353A keeps overlap optional in user guidance', () {
    expect(scanner, contains('A little overlap is ideal'));
    expect(scanner, isNot(contains('until Row 6 is at the top')));
  });
}
