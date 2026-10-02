import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('second photo reuses first photo perimeter', () {
    final scanner = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_live_scanner_screen.dart',
    ).readAsStringSync();

    expect(scanner, contains('_lockedFirstCaptureCalibration'));
    expect(scanner, contains('enabled: !_captureSession.hasTop'));
    expect(scanner, contains('outputRows: 5'));
    expect(scanner, isNot(contains('_removeBottomCaptureOverlapRow')));
    expect(
      scanner,
      isNot(contains('_alignmentController.prepareForBottomCapture()')),
    );
  });

  test('locked frame exposes only the four paired-edge controls', () {
    final overlay = File(
      'lib/features/trading_hub/arc_raiders/widgets/'
      'arc_blueprint_edge_crop_overlay.dart',
    ).readAsStringSync();

    expect(overlay, contains("Key('blueprint-crop-edge-left')"));
    expect(overlay, contains("Key('blueprint-crop-edge-right')"));
    expect(overlay, contains("Key('blueprint-crop-edge-top')"));
    expect(overlay, contains("Key('blueprint-crop-edge-bottom')"));
    expect(overlay, isNot(contains('for (var column = 1; column < 10;')));
    expect(overlay, isNot(contains('for (var row = 1; row < 5;')));
  });

  test('obsolete auto framing status is hidden in still capture mode', () {
    final scanner = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_live_scanner_screen.dart',
    ).readAsStringSync();

    expect(scanner, contains('if (!isPortrait && !_stillCaptureMode)'));
  });
}
