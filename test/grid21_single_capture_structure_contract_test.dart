import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'single grid measures background beside artwork without changing six gates',
    () {
      final source = File(
        'lib/features/trading_hub/arc_raiders/data/arc_blueprint_owned_cell_structure_verifier.dart',
      ).readAsStringSync();
      expect(source.contains('_measureSingleGridCell('), isTrue);
      expect(source.contains('final primaryStructure = singleGrid'), isTrue);
      expect(
        source.contains('final bluePanel = (leftBlue + rightBlue) / 2;'),
        isTrue,
      );
      expect(source.contains('primaryGate.allPassed'), isTrue);
      expect(
        source.contains(
          "'book': structure.bookShapeEvidence >= minimumMarkerShapeEvidence",
        ),
        isTrue,
      );
      expect(
        source.contains(
          "'tick': structure.tickShapeEvidence >= minimumMarkerShapeEvidence",
        ),
        isTrue,
      );
      expect(
        source.contains(
          "'artwork': artworkSimilarity >= minimumArtworkSimilarity",
        ),
        isTrue,
      );
    },
  );
}
