import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_collection_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_collection_models.dart';

void main() {
  test('Yank Grenade is Row 6 Card 3 while Burletta remains unplaced', () {
    final yank = ArcFrozenTrailCollectionCatalogue.entryAtSlot(
      ArcCollectionType.blueprints,
      88,
    );
    expect(yank?.id, 'yank-grenade');
    expect(ArcFrozenTrailCollectionCatalogue.blueprintGrid.rowColumnCounts, [
      17,
      17,
      17,
      17,
      17,
      6,
    ]);
    expect(
      ArcFrozenTrailCollectionCatalogue.blueprintEntries
          .where((e) => e.id == 'burletta')
          .single
          .slot,
      89,
    );
  });
  test(
    'Camera normalizes oriented still and requires an explicit safe update',
    () {
      final source = File(
        'lib/features/trading_hub/arc_raiders/screens/arc_frozen_trail_single_grid_capture_screen.dart',
      ).readAsStringSync();
      expect(source, contains('normalizeLocatedGrid(located)'));
      expect(source, contains('image_codec.bakeOrientation(decoded)'));
      expect(source, contains('Update Blueprint Collection'));
      expect(source, contains('automaticUpdateBlockReason('));
      expect(source, isNot(contains('manuallyConfirmed: true')));
      expect(source, isNot(contains('confidence: 1,')));
    },
  );
}
