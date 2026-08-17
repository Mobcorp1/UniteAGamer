import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const path =
      'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_live_scanner_screen.dart';

  test('PASS 348 scanner uses edge-only automatic framing', () {
    final source = File(path).readAsStringSync();

    expect(source, contains('_BlueprintAutoFrameOverlay'));
    expect(source, contains('_BlueprintAutoFramePainter'));
    expect(source, contains('detection.topLeft'));
    expect(source, contains('detection.bottomRight'));

    expect(source, isNot(contains('_BlueprintScannerOverlay')));
    expect(source, isNot(contains('_BlueprintGuidePainter2')));
    expect(source, isNot(contains('_DragTarget')));
  });

  test('PASS 348 normal live UX has no photo capture control', () {
    final source = File(path).readAsStringSync();

    expect(source, isNot(contains("'blueprint-live-scanner-capture'")));
    expect(source, contains('AUTO FRAMING BLUEPRINT GRID'));
    expect(source, contains('AUTO SCANNING'));
    expect(source, contains('_completeStableLiveSection'));
  });

  test('PASS 348 top scan pauses for the user to scroll to row 6', () {
    final source = File(path).readAsStringSync();

    expect(source, contains('awaitingBottomScroll'));
    expect(source, contains('blueprint-live-scanner-begin-bottom'));
    expect(source, contains('SCAN ROWS 6-9'));
    expect(source, contains('_beginBottomLiveScan'));
  });

  test('PASS 348 does not paint a synthetic cell grid', () {
    final source = File(path).readAsStringSync();

    expect(source, isNot(contains('for (var column = 1; column < 10')));
    expect(source, isNot(contains('synthetic 10x5 grid')));
  });
}
