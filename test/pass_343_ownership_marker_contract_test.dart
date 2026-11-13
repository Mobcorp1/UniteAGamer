import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PASS 343 marker verifier is wired before final classification', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_blueprint_photo_capture_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('arc_blueprint_ownership_marker_verification_engine.dart'),
    );
    expect(source, contains('ArcBlueprintOwnershipMarkerVerificationEngine()'));
    expect(source, contains('final markerVerification ='));
    expect(source, contains('samples: templateVerification.samples'));
    expect(
      source,
      contains('templateDiagnostics: templateVerification.diagnostics'),
    );
    expect(source, contains('samples: markerVerification.samples'));
  });

  test('PASS 343 remains suppression-only', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/data/'
      'arc_blueprint_ownership_marker_verification_engine.dart',
    ).readAsStringSync();

    expect(source, contains('evidence >= ownedThreshold'));
    expect(source, contains('maximumSuppressedScore'));
    expect(source, isNot(contains('math.max(finalScore')));
  });
}
