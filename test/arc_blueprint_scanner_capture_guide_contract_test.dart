import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scanner uses one persistent locked edge frame and no synthetic grid', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_live_scanner_screen.dart',
    ).readAsStringSync();
    final overlay = File(
      'lib/features/trading_hub/arc_raiders/widgets/arc_blueprint_edge_crop_overlay.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('final ManualAlignmentController _alignmentController'),
    );
    expect(source, contains('ArcBlueprintEdgeCropOverlay('));
    expect(source, contains('_lockedFirstCaptureCalibration'));
    expect(source, contains('enabled: !_captureSession.hasTop'));
    expect(source, isNot(contains('_bottomAlignmentController')));
    expect(source, isNot(contains('_topAlignmentController')));
    expect(source, isNot(contains('_BlueprintAutoFrameOverlay(')));
    expect(overlay, isNot(contains('for (var column = 1; column < 10;')));
    expect(overlay, isNot(contains('for (var row = 1; row < 5;')));
  });

  test('scanner initializes default geometry from the real viewport', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_live_scanner_screen.dart',
    ).readAsStringSync();

    expect(source, contains('_ensureDefaultAlignmentForViewport'));
    expect(source, contains('viewportSize.width / viewportSize.height'));
    expect(source, contains('resetToTopDefaultForViewport'));
  });
}
