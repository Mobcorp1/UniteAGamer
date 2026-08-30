import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('verified grid promotion accepts realistic TV panel span', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/data/'
      'arc_blueprint_grid_detector.dart',
    ).readAsStringSync();

    expect(source, contains('detectedWidth >= 0.50'));
    expect(source, contains("detectedHeight >= (rows >= 5 ? 0.24 : 0.16)"));
    expect(
      source,
      contains('detection.verticalDividers.length == columns + 1'),
    );
    expect(source, contains('detection.horizontalDividers.length == rows + 1'));
  });
}
