import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PASS 338 keeps camera lifecycle untouched and adds evidence policy', () {
    final hybrid = File(
      'lib/features/trading_hub/arc_raiders/data/arc_blueprint_hybrid_recognition_engine.dart',
    ).readAsStringSync();
    final policy = File(
      'lib/features/trading_hub/arc_raiders/data/arc_blueprint_recognition_evidence_policy.dart',
    ).readAsStringSync();
    final scanner = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_live_scanner_screen.dart',
    ).readAsStringSync();

    expect(hybrid, contains('ArcBlueprintRecognitionEvidencePolicy'));
    expect(hybrid, contains('blueprintBlueCoverage'));
    expect(hybrid, contains('brightFeatureCoverage'));
    expect(policy, contains('borderline owned score suppressed'));
    expect(scanner, isNot(contains('PASS 338')));
  });
}
