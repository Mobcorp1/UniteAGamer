import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'photo import uses safe delta review rather than all-or-nothing uncertainty',
    () {
      final source = File(
        'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_photo_capture_screen.dart',
      ).readAsStringSync();

      expect(
        source,
        contains(
          'maximumUncertainCells: ArcBlueprintCanonicalGrid.totalPositions',
        ),
      );
      expect(source, contains('proposedAdditions'));
      expect(source, contains('ArcBlueprintPhotoDeltaReviewScreen'));
      expect(source, contains('uncertainIgnoredCount'));
      expect(source, isNot(contains('No changes were applied.')));
    },
  );
}
