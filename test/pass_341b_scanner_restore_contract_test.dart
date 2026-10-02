import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scanner keeps persistent linked-edge frame with capture recovery', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_live_scanner_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('final ManualAlignmentController _alignmentController'),
    );
    expect(source, contains('ArcBlueprintPerspectiveCropper().rectify('));
    expect(source, contains("'blueprint-live-scanner-capture'"));
    expect(source, contains("'blueprint-live-scanner-begin-bottom'"));
    expect(source, contains('ArcBlueprintEdgeCropOverlay('));
    expect(source, contains('AUTO FRAMING BLUEPRINT GRID'));
    expect(source, contains('await controller.takePicture()'));

    expect(source, isNot(contains('ArcBlueprintLiveTargetingOverlay(')));
    expect(
      source,
      isNot(contains('for (var column = 1; column < 10; column++)')),
    );
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
