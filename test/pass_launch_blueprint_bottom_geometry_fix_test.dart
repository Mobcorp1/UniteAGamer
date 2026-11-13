import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('live scanner keeps the overlap row until registration', () {
    final scanner = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_live_scanner_screen.dart',
    ).readAsStringSync();

    expect(scanner, isNot(contains('_removeBottomCaptureOverlapRow')));
    expect(scanner, contains('outputRows: 5'));
    expect(scanner, contains('_lockedFirstCaptureCalibration'));
    expect(scanner, contains('enabled: !_captureSession.hasTop'));
  });

  test('bottom photo registers five rows then removes one overlap row', () {
    final capture = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_photo_capture_screen.dart',
    ).readAsStringSync();

    final registerIndex = capture.indexOf('registeredBottomFiveRows');
    final removeIndex = capture.indexOf('removeRegisteredOverlap(');

    expect(registerIndex, greaterThanOrEqualTo(0));
    expect(removeIndex, greaterThan(registerIndex));
    expect(capture, contains('rows: 5'));
    expect(capture, isNot(contains('registeredBottom.')));
  });

  test('bottom preview shows all five physical captured rows', () {
    final capture = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_photo_capture_screen.dart',
    ).readAsStringSync();

    expect(capture, contains('aspectRatio: 10 / 5'));
    expect(capture, isNot(contains(': 10 / 4')));
  });

  test('default scanner frame is narrower and viewport-height aware', () {
    final controller = File(
      'lib/features/trading_hub/arc_raiders/data/'
      'manual_alignment_controller.dart',
    ).readAsStringSync();

    expect(controller, contains('defaultTopWidthFraction = 0.60'));
    expect(controller, contains('resetToTopDefaultForViewport'));
    expect(controller, contains('width * safeViewportAspect'));
  });
}
