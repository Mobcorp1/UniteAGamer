import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PASS 345 dual-gate thresholds and diagnostics are present', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/data/'
      'arc_blueprint_ownership_marker_verification_engine.dart',
    ).readAsStringSync();

    expect(source, contains('highConfidenceProposalFloor = 0.98'));
    expect(source, contains('minimumCorroboratedMarkerEvidence = 0.70'));
    expect(source, contains('final highConfidenceCandidate'));
    expect(source, contains('final corroboratedMarkers'));
    expect(source, contains('final reliableBookOnly'));
    expect(source, contains('final dualGateRejects'));
    expect(source, contains('proposalFloor='));
    expect(source, contains('markerFloor='));
  });

  test('PASS 345 remains suppression-only', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/data/'
      'arc_blueprint_ownership_marker_verification_engine.dart',
    ).readAsStringSync();

    expect(source, contains('maximumSuppressedScore'));
    expect(source, contains('math.min(finalScore, maximumSuppressedScore)'));
    expect(source, isNot(contains('math.max(finalScore')));
  });
}
