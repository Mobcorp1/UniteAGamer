import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_design_reference_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_collection_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';

void main() {
  test('101 furniture designs and player-confirmed position 25', () {
    expect(ArcDesignReferenceCatalogue.names.length, 101);
    expect(ArcDesignReferenceCatalogue.inGameOrder.length, 101);
    expect(ArcDesignReferenceCatalogue.nameAt(1), 'Printed Lab Sofa');
    expect(ArcDesignReferenceCatalogue.nameAt(24), 'Polished Faculty Table');
    expect(ArcDesignReferenceCatalogue.nameAt(25), 'Offering Display Table');
    expect(ArcDesignReferenceCatalogue.nameAt(26), 'Ornate Stash');
    expect(ArcDesignReferenceCatalogue.nameAt(38), 'Study Armchair');
    expect(ArcDesignReferenceCatalogue.nameAt(88), 'Study Armchair');
    expect(ArcDesignReferenceCatalogue.nameAt(101), 'Sturdy Den Shelf');
    expect(ArcDesignReferenceCatalogue.nameAt(102), isNull);
    expect(ArcDesignReferenceCatalogue.inGameOrder.toSet().length, 100);
  });

  test('101 slot geometry is 17 columns with 16 cards in last row', () {
    expect(ArcNativeCollectionKind.designs.slots, 101);
    final grid = ArcFrozenTrailCollectionCatalogue.designGrid;
    expect(grid.totalSlots, 101);
    expect(grid.rowColumnCounts, [17, 17, 17, 17, 17, 16]);
    expect(grid.absoluteSlotFor(row: 2, column: 8), 25);
    expect(grid.absoluteSlotFor(row: 6, column: 16), 101);
    expect(grid.absoluteSlotFor(row: 6, column: 17), isNull);
    expect(grid.positionForSlot(101), (row: 6, column: 16));
  });

  test('verified manual assignments retain their independent slot keys', () {
    expect(ArcDesignReferenceCatalogue.inGameNameForSlot(101, const {}), isNull);
    expect(
      ArcDesignReferenceCatalogue.inGameNameForSlot(
        101, const {101: 'Sturdy Den Shelf'}),
      'Sturdy Den Shelf',
    );
    expect(ArcDesignReferenceCatalogue.inGameNameForSlot(102, const {}), isNull);
  });
}
