import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'PASS 340 runtime order is state -> calibration -> template -> classify',
    () {
      final source = File(
        'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_photo_capture_screen.dart',
      ).readAsStringSync();

      final stateLoad = source.indexOf('loadMyBlueprintStates()');
      final calibration = source.indexOf('personalCalibration.calibrate(');
      final verification = source.indexOf('templateVerifier.verify(');
      final classify = source.indexOf('engine.classify(');

      expect(stateLoad, greaterThanOrEqualTo(0));
      expect(calibration, greaterThan(stateLoad));
      expect(verification, greaterThan(calibration));
      expect(classify, greaterThan(verification));

      expect(source, contains('samples: merged.samples'));
      expect(source, contains('existing: existing'));
      expect(source, contains('samples: calibrated.samples'));
      expect(source, contains('samples: templateVerification.samples'));
      expect(source, contains('ARC TEMPLATE VERIFY:'));
      expect(source, contains(r'expected=${diagnostic.blueprintName}'));
      expect(source, contains(r'index=${diagnostic.canonicalIndex}'));
      expect(source, contains('templateSuppressed='));
    },
  );

  test('PASS 340 keeps one tracker state load before classification', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_photo_capture_screen.dart',
    ).readAsStringSync();

    expect('loadMyBlueprintStates()'.allMatches(source), hasLength(1));
    expect(
      source.indexOf('loadMyBlueprintStates()'),
      lessThan(source.indexOf('engine.classify(')),
    );
  });

  test('PASS 340 leaves camera and merge implementation untouched', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_photo_capture_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('CameraController(')));
    expect(source, isNot(contains('startImageStream(')));
    expect(source, contains('ArcBlueprintDualCaptureMergeEngine'));
    expect(source, contains('ArcBlueprintPersonalCalibrationEngine'));
    expect(source, contains('ArcBlueprintTemplateVerificationEngine'));
  });

  test('PASS 340 remains additive through Safe Delta Review', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_photo_capture_screen.dart',
    ).readAsStringSync();

    expect(source, contains('existing[decision.blueprintId]?.owned != true'));
    expect(source, contains('ArcBlueprintPhotoDeltaReviewScreen'));
    expect(source, isNot(contains('saveBlueprintState(')));
    expect(source, isNot(contains('deleteBlueprintState(')));
  });
}
