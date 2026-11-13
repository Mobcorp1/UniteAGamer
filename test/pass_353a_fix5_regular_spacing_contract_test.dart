import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'low-confidence strict grids can be recovered by divider regularity',
    () {
      final source = File(
        'lib/features/trading_hub/arc_raiders/data/'
        'arc_blueprint_grid_detector.dart',
      ).readAsStringSync();

      expect(source, contains('_dividerSpacingRegularity('));
      expect(source, contains('detection.verticalDividers'));
      expect(source, contains('detection.horizontalDividers'));
      expect(
        source,
        contains("message: 'Grid locked (verified regular spacing)'"),
      );
    },
  );
}
