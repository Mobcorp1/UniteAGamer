import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('locked-grid capture enters the 12-Aug import pipeline', () {
    final capture = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_photo_capture_screen.dart',
    ).readAsStringSync();

    expect(capture, contains('await _repository.saveDualCapture('));
    expect(capture, contains('_busy = false;'));
    expect(capture, contains('await _scanAndImport();'));
    expect(
      capture,
      contains('ArcBlueprintPhotoPixelAnalyzer(columns: 10, rows: 5)'),
    );
    expect(capture, contains('ArcBlueprintPhotoDeltaReviewScreen('));
  });

  test('Update Blueprint Grid remains directly wired to apply', () {
    final review = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_photo_delta_review_screen.dart',
    ).readAsStringSync();

    expect(review, contains("key: const Key('blueprint-delta-apply')"));
    expect(review, contains('onPressed: _saving ? null : _apply'));
    expect(
      review,
      contains("await ArcBlueprintPhotoImportService().apply(additions)"),
    );
    expect(review, contains("Navigator.of(context).pop(true)"));
  });

  test('camera remains linked-edge locked-grid rather than four corners', () {
    final scanner = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_live_scanner_screen.dart',
    ).readAsStringSync();

    expect(scanner, contains('bool _stillCaptureMode = true;'));
    expect(scanner, contains('ArcBlueprintEdgeCropOverlay('));
    expect(scanner, contains("'blueprint-live-scanner-capture'"));
    expect(scanner, contains('ArcBlueprintPerspectiveCropper().rectify('));
  });
}
