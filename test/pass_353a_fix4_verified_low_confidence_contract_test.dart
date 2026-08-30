import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('low-confidence strict grid needs independent evidence before lock', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/data/'
      'arc_blueprint_grid_detector.dart',
    ).readAsStringSync();

    expect(source, contains('final verifiedEvidence = _internalGridEvidence('));
    expect(source, contains('if (verifiedEvidence.isCredible)'));
    expect(
      source,
      contains("message: 'Grid locked (verified internal evidence)'"),
    );
    expect(source, contains('detection.confidence < minimumConfidence'));
  });
}
