import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('photo capture calibrates before occupancy classification', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_photo_capture_screen.dart',
    ).readAsStringSync();

    final stateLoad = source.indexOf('loadMyBlueprintStates()');
    final calibration = source.indexOf('ArcBlueprintPersonalCalibrationEngine');
    final classify = source.indexOf('engine.classify(');

    expect(stateLoad, greaterThanOrEqualTo(0));
    expect(calibration, greaterThan(stateLoad));
    expect(classify, greaterThan(calibration));
    expect(source, contains('samples: calibration.samples'));
    expect(source, contains('personalAnchors='));
    expect(source, contains('adaptiveFloor='));
  });

  test('PASS 339 does not alter camera or merge implementation', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_photo_capture_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('CameraController(')));
    expect(source, isNot(contains('startImageStream(')));
  });
}
