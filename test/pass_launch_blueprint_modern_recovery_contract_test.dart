import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Blueprint import keeps modern UI and clean text', () {
    final capture = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_photo_capture_screen.dart',
    ).readAsStringSync();
    final review = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_photo_delta_review_screen.dart',
    ).readAsStringSync();

    expect(capture, contains('ArcUiTokens.'));
    expect(review, contains('ArcUiTokens.'));
    expect(capture, isNot(contains('VT323')));
    expect(review, isNot(contains('VT323')));
    expect(capture, isNot(contains('Ã¢')));
    expect(review, isNot(contains('Ã¢')));
  });

  test('camera images always enter the photo recognition pipeline', () {
    final capture = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_photo_capture_screen.dart',
    ).readAsStringSync();

    expect(capture, contains('await _repository.saveDualCapture('));
    expect(capture, contains('_busy = false;'));
    expect(capture, contains('await _scanAndImport();'));
  });

  test('result screen is one-action not checkbox checkout', () {
    final review = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_photo_delta_review_screen.dart',
    ).readAsStringSync();

    expect(review, contains("'blueprint-delta-apply'"));
    expect(review, contains("'Update Blueprint Grid'"));
    expect(review, isNot(contains('CheckboxListTile')));
    expect(review, isNot(contains('_selectedIds')));
  });

  test('Blueprint Tracker exposes clear-grid-only control', () {
    final grid = File(
      'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart',
    ).readAsStringSync();

    expect(grid, contains("'Clear Blueprint Grid'"));
    expect(grid, contains('_confirmClearBlueprintGridOnly'));
    expect(grid, contains('resetAllBlueprintStates('));
  });

  test('high confidence alone no longer bypasses ownership verification', () {
    final marker = File(
      'lib/features/trading_hub/arc_raiders/data/'
      'arc_blueprint_ownership_marker_verification_engine.dart',
    ).readAsStringSync();

    expect(marker, contains('final highConfidenceWithTemplate'));
    expect(marker, contains('final independentlyVerified'));
    expect(
      marker,
      contains('if (evidence >= ownedThreshold && !independentlyVerified)'),
    );
    expect(marker, contains('verticalShifts'));
  });

  test('linked-edge locked-grid camera remains active', () {
    final scanner = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_live_scanner_screen.dart',
    ).readAsStringSync();

    expect(scanner, contains('bool _stillCaptureMode = true;'));
    expect(scanner, contains('ArcBlueprintEdgeCropOverlay('));
  });
}
