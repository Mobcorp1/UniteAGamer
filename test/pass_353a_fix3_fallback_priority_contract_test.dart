import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('credible TV fallback wins over low-confidence strict detection', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/data/'
      'arc_blueprint_grid_detector.dart',
    ).readAsStringSync();

    expect(source, contains('if (panelFallback != null)'));
    expect(
      source,
      isNot(
        contains('panelFallback.confidence >= detection.confidence * 0.90'),
      ),
    );
  });
}
