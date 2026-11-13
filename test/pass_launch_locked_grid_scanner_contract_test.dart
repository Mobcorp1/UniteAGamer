import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('launch scanner uses linked-edge locked grid as capture geometry', () {
    final scanner = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_live_scanner_screen.dart',
    ).readAsStringSync();

    expect(scanner, contains('bool _stillCaptureMode = true;'));
    expect(scanner, contains('ArcBlueprintEdgeCropOverlay('));
    expect(scanner, contains("'blueprint-live-scanner-reset-grid'"));
    expect(scanner, contains("'blueprint-live-scanner-capture'"));
    expect(
      scanner,
      contains('final corrected = ArcBlueprintPerspectiveCropper().rectify('),
    );
    expect(scanner, contains('outputRows: 5'));
    expect(
      scanner,
      isNot(contains('_alignmentController.prepareForBottomCapture()')),
    );
    expect(
      scanner,
      contains('final completed = _captureSession.captureBottom(corrected);'),
    );
  });

  test('locked grid has paired edges and no independent corner handles', () {
    final model = File(
      'lib/features/trading_hub/arc_raiders/models/'
      'arc_blueprint_edge_calibration.dart',
    ).readAsStringSync();
    final overlay = File(
      'lib/features/trading_hub/arc_raiders/widgets/'
      'arc_blueprint_edge_crop_overlay.dart',
    ).readAsStringSync();

    expect(model, contains('final centre = (top + bottom) / 2'));
    expect(model, contains('final centre = (left + right) / 2'));
    expect(overlay, contains("'blueprint-crop-edge-top'"));
    expect(overlay, contains("'blueprint-crop-edge-bottom'"));
    expect(overlay, contains("'blueprint-crop-edge-left'"));
    expect(overlay, contains("'blueprint-crop-edge-right'"));
    expect(overlay, isNot(contains('blueprint-crop-corner')));
  });
}
