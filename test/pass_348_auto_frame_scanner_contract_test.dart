import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const path =
      'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_live_scanner_screen.dart';

  test('PASS 348 scanner uses linked-edge grid framing', () {
    final source = File(path).readAsStringSync();

    expect(source, contains('ArcBlueprintEdgeCropOverlay('));
    expect(source, contains('_alignmentController.calibration'));
    expect(source, contains('enabled: !_captureSession.hasTop'));

    expect(source, isNot(contains('_BlueprintScannerOverlay')));
    expect(source, isNot(contains('_BlueprintGuidePainter2')));
    expect(source, isNot(contains('_DragTarget')));
    expect(source, isNot(contains('_BlueprintAutoFrameOverlay')));
  });

  test('launch scanner keeps framing and exposes still capture recovery', () {
    final source = File(path).readAsStringSync();

    expect(source, contains("'blueprint-live-scanner-capture'"));
    expect(source, contains('Future<void> _capture()'));
    expect(source, contains('_stillCaptureMode'));
    expect(source, contains('_captureSession.hasTop'));
    expect(source, contains('AUTO FRAMING BLUEPRINT GRID'));
    expect(source, contains('AUTO SCANNING'));
    expect(source, contains('_completeStableLiveSection'));
  });

  test('still camera captures feed the conservative photo pipeline', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_photo_capture_screen.dart',
    ).readAsStringSync();

    expect(source, contains('await _repository.saveDualCapture('));
    expect(source, contains("topFileName: 'blueprint_grid_top.jpg'"));
    expect(source, contains("bottomFileName: 'blueprint_grid_bottom.jpg'"));
    expect(source, contains('await _scanAndImport();'));
  });

  test(
    'PASS 348 top scan pauses for the user to scroll to the overlap row',
    () {
      final source = File(path).readAsStringSync();

      expect(source, contains('awaitingBottomScroll'));
      expect(source, contains('blueprint-live-scanner-begin-bottom'));
      expect(source, contains('SCAN NEXT SECTION'));
      expect(source, contains('_beginBottomLiveScan'));
    },
  );

  test('PASS 348 does not paint a synthetic cell grid', () {
    final source = File(path).readAsStringSync();

    expect(source, isNot(contains('for (var column = 1; column < 10')));
    expect(source, isNot(contains('synthetic 10x5 grid')));
  });
}
