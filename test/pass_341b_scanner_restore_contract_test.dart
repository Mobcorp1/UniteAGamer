import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scanner restores persistent adjustable frame and capture contract', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_live_scanner_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('final ManualAlignmentController _alignmentController'),
    );
    expect(source, contains('.autoAlignFromDetection('));
    expect(source, contains('_DragTarget.topLeft'));
    expect(source, contains('_DragTarget.topRight'));
    expect(source, contains('_DragTarget.bottomLeft'));
    expect(source, contains('_DragTarget.bottomRight'));
    expect(source, contains('ArcBlueprintPerspectiveCropper().rectify('));

    expect(
      source,
      contains(
        "key: const Key(\n                                  "
        "'blueprint-live-scanner-capture'",
      ),
    );
    expect(source, contains('canStartCapture('));
    expect(source, contains('? _capture'));
    expect(source, contains('await controller.takePicture()'));

    expect(source, isNot(contains('ArcBlueprintLiveTargetingOverlay(')));
    expect(
      source,
      isNot(contains('for (var column = 1; column < 10; column++)')),
    );
    expect(
      source,
      contains('Do not\n    // paint a synthetic 10x5 grid over it'),
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
