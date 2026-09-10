import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scanner keeps persistent frame with live automatic scan contract', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_live_scanner_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('final ManualAlignmentController _alignmentController'),
    );
    expect(source, contains('ArcBlueprintPerspectiveCropper().rectify('));

    expect(source, isNot(contains("'blueprint-live-scanner-capture'")));
    expect(source, contains("'blueprint-live-scanner-begin-bottom'"));
    expect(source, contains('No photo capture is required.'));
    expect(source, contains('AUTO FRAMING BLUEPRINT GRID'));
    // Still capture remains available only as a recovery fallback.
    expect(source, contains('await controller.takePicture()'));

    expect(source, isNot(contains('ArcBlueprintLiveTargetingOverlay(')));
    expect(
      source,
      isNot(contains('for (var column = 1; column < 10; column++)')),
    );
    expect(source, contains('_BlueprintAutoFrameOverlay('));
    expect(source, contains('detection: _latestDetection'));
  });

  test('both captures share the same manual alignment frame', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_live_scanner_screen.dart',
    ).readAsStringSync();

    expect(
      RegExp(
        r'ManualAlignmentController _alignmentController',
      ).allMatches(source).length,
      1,
    );
    expect(source, isNot(contains('_topAlignmentController')));
    expect(source, isNot(contains('_bottomAlignmentController')));
    expect(
      source,
      contains('One persistent manual frame is shared by both captures'),
    );
  });
}
