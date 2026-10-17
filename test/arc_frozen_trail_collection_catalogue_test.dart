import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_collection_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_collection_models.dart';

void main() {
  group('Frozen Trail collection grids', () {
    test('uses exact launch-day grid geometry', () {
      expect(
        ArcFrozenTrailCollectionCatalogue.blueprintGrid.rowColumnCounts,
        const [17, 17, 17, 17, 17, 6],
      );
      expect(
        ArcFrozenTrailCollectionCatalogue.stencilGrid.rowColumnCounts,
        const [9, 5],
      );
      expect(
        ArcFrozenTrailCollectionCatalogue.designGrid.rowColumnCounts,
        const [17, 17, 17, 17, 17, 15],
      );

      expect(ArcFrozenTrailCollectionCatalogue.blueprintGrid.totalSlots, 91);
      expect(ArcFrozenTrailCollectionCatalogue.stencilGrid.totalSlots, 14);
      expect(ArcFrozenTrailCollectionCatalogue.designGrid.totalSlots, 100);
    });

    test('Advanced Camera is row 3 position 12 / slot 46', () {
      final spec = ArcFrozenTrailCollectionCatalogue.blueprintGrid;

      expect(spec.absoluteSlotFor(row: 3, column: 12), 46);
      expect(spec.positionForSlot(46), (row: 3, column: 12));

      final entry = ArcFrozenTrailCollectionCatalogue.entryAtSlot(
        ArcCollectionType.blueprints,
        46,
      );
      expect(entry?.name, 'Advanced Camera');
      expect(entry?.confidence, ArcCollectionSlotConfidence.verifiedInGame);
    });

    test('Tether Launcher occupies confirmed row 4 column 5 slot 56', () {
      final grid = ArcFrozenTrailCollectionCatalogue.blueprintGrid;
      expect(grid.absoluteSlotFor(row: 4, column: 5), 56);
      final tether = ArcFrozenTrailCollectionCatalogue.entryAtSlot(
        ArcCollectionType.blueprints,
        56,
      );
      expect(tether?.id, 'tether-launcher');
      expect(tether?.confidence, ArcCollectionSlotConfidence.verifiedInGame);
    });
    test('Vita Shot is verified at row 3 card 4 / slot 38', () {
      final spec = ArcFrozenTrailCollectionCatalogue.blueprintGrid;
      expect(spec.absoluteSlotFor(row: 3, column: 4), 38);
      final entry = ArcFrozenTrailCollectionCatalogue.entryAtSlot(
        ArcCollectionType.blueprints,
        38,
      );
      expect(entry?.id, 'vita-shot');
      expect(entry?.name, 'Vita Shot');
      expect(entry?.confidence, ArcCollectionSlotConfidence.verifiedInGame);
      expect(
        ArcFrozenTrailCollectionCatalogue.blueprintEntries
            .where((entry) => entry.id == 'vita-shot')
            .length,
        1,
      );
      expect(
        ArcFrozenTrailCollectionCatalogue.blueprintEntries
            .where((entry) => entry.slot == 38)
            .length,
        1,
      );
    });
    test('verified stencil slots match the in-game capture', () {
      expect(
        ArcFrozenTrailCollectionCatalogue.entryAtSlot(
          ArcCollectionType.stencils,
          5,
        )?.name,
        'Milky Terracotta',
      );
      expect(
        ArcFrozenTrailCollectionCatalogue.entryAtSlot(
          ArcCollectionType.stencils,
          9,
        )?.name,
        "Dragon's Breath",
      );
    });

    test('does not invent slots for unverified Frozen Trail blueprints', () {
      final pending = ArcFrozenTrailCollectionCatalogue
          .frozenTrailBlueprintAdditions
          .where((entry) => entry.slot == null);

      expect(pending, isEmpty);
      expect(pending.every((entry) => entry.slot == null), isTrue);
    });

    test('confirmed new Blueprint slots retain canonical IDs', () {
      const expected = <int, String>{
        60: 'extended-light-mag-iii', 62: 'bantam', 89: 'burletta',
      };
      for (final record in expected.entries) {
        expect(
          ArcFrozenTrailCollectionCatalogue.entryAtSlot(
            ArcCollectionType.blueprints, record.key,
          )?.id,
          record.value,
        );
      }
    });

    test('stencil economy behaviour remains conservative', () {
      for (final entry in ArcFrozenTrailCollectionCatalogue.stencilEntries) {
        expect(entry.duplicateStatus, ArcCollectionEconomyStatus.unknown);
        expect(entry.tradeStatus, ArcCollectionEconomyStatus.unknown);
      }
    });
  });
}
