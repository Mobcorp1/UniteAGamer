import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_collection_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_collection_models.dart';

void main() {
  test('all 91 cells exist in a 17-column layout', () {
    final grid = ArcFrozenTrailCollectionCatalogue.blueprintGrid;
    expect(grid.totalSlots, 91);
    expect(grid.rowColumnCounts, [17, 17, 17, 17, 17, 6]);
    expect(grid.absoluteSlotFor(row: 6, column: 6), 91);
  });
  test('verified additions retain canonical positions and artwork paths', () {
    const names = {
      40: 'Banjo',
      46: 'Advanced Camera',
      68: 'Emperor Gateway Conduit',
    };
    for (final position in names.entries) {
      final item = ArcFrozenTrailCollectionCatalogue.entryAtSlot(
        ArcCollectionType.blueprints,
        position.key,
      );
      expect(item?.name, position.value);
      expect(
        ArcFrozenTrailCollectionCatalogue.frozenTrailArtworkPaths[item!.id],
        startsWith('assets/arc_raiders/blueprints/'),
      );
    }
  });
  test('provisional legacy positions remain visibly unverified', () {
    for (final slot in [28, 59, 90]) {
      expect(
        ArcFrozenTrailCollectionCatalogue.entryAtSlot(
          ArcCollectionType.blueprints,
          slot,
        ),
        isNotNull,
      );
      expect(
        ArcFrozenTrailCollectionCatalogue.entryAtSlot(
          ArcCollectionType.blueprints, slot,
        )?.confidence,
        ArcCollectionSlotConfidence.unverified,
      );
    }
  });
}
