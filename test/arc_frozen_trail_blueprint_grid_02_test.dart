import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_blueprint_grid_migration.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_collection_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_collection_models.dart';

void main() {
  group('Frozen Trail Blueprint Grid 02', () {
    test('keeps exact 91-slot launch geometry', () {
      expect(
        ArcFrozenTrailCollectionCatalogue.blueprintGrid.rowColumnCounts,
        const <int>[17, 17, 17, 17, 17, 6],
      );
      expect(ArcFrozenTrailCollectionCatalogue.blueprintGrid.totalSlots, 91);
      expect(ArcFrozenTrailBlueprintGridMigration.columns, 17);
    });

    test('first 17 preserve the confirmed pre-update sequence', () {
      const expected = <String>[
        'Extended Shotgun Mag III',
        'Angled Grip III',
        'Pulse Mine',
        'Silencer II',
        'Red Light Stick',
        'Tactical Mk. 3 (Revival)',
        'Compensator II',
        'Muzzle Brake III',
        'Tactical Mk. 3 (Defensive)',
        'Vita Spray',
        'Medium Gun Parts',
        'Tagging Grenade',
        'Crash Mat',
        'Bobcat',
        'Defibrillator',
        'Jupiter',
        'Extended Medium Mag II',
      ];

      for (var slot = 1; slot <= expected.length; slot++) {
        expect(
          ArcFrozenTrailCollectionCatalogue.entryAtSlot(
            ArcCollectionType.blueprints,
            slot,
          )?.name,
          expected[slot - 1],
          reason: 'slot $slot',
        );
      }
    });

    test('new verified launch positions are locked', () {
      expect(
        ArcFrozenTrailCollectionCatalogue.entryAtSlot(
          ArcCollectionType.blueprints,
          40,
        )?.name,
        'Banjo',
      );
      expect(
        ArcFrozenTrailCollectionCatalogue.entryAtSlot(
          ArcCollectionType.blueprints,
          46,
        )?.name,
        'Advanced Camera',
      );
      expect(
        ArcFrozenTrailCollectionCatalogue.entryAtSlot(
          ArcCollectionType.blueprints,
          68,
        )?.name,
        'Emperor Gateway Conduit',
      );
    });

    test('final-row anchors are locked without treating provisional slots as verified', () {
      expect(
        ArcFrozenTrailCollectionCatalogue.entryAtSlot(
          ArcCollectionType.blueprints,
          86,
        )?.name,
        'Muzzle Brake II',
      );
      expect(
        ArcFrozenTrailCollectionCatalogue.entryAtSlot(
          ArcCollectionType.blueprints,
          91,
        )?.name,
        'Snap Hook',
      );

      for (final entry in const <int, String>{
        60: 'Extended Light Mag III',
        62: 'Bantam',
        89: 'Burletta',
      }.entries) {
        expect(
          ArcFrozenTrailCollectionCatalogue.entryAtSlot(
            ArcCollectionType.blueprints, entry.key,
          )?.name,
          entry.value,
          reason: 'Confirmed slot ${entry.key}',
        );
      }
      for (final slot in <int>[28, 59, 90]) {
        expect(
          ArcFrozenTrailCollectionCatalogue.entryAtSlot(
            ArcCollectionType.blueprints,
            slot,
          ),
          isNotNull,
          reason: 'slot $slot retains a provisional legacy record',
        );
        expect(
          ArcFrozenTrailCollectionCatalogue.entryAtSlot(
            ArcCollectionType.blueprints, slot,
          )?.confidence,
          ArcCollectionSlotConfidence.unverified,
          reason: 'slot $slot must not be auto-scanned as verified',
        );
      }
    });

    test('unlocated new Blueprints stay unresolved', () {
      final pending = ArcFrozenTrailCollectionCatalogue
          .frozenTrailBlueprintAdditions
          .where((entry) => entry.slot == null)
          .map((entry) => entry.name)
          .toList(growable: false);

      expect(pending, isEmpty);
    });

    test('scanner import requires verified positions, not just populated slots', () {
      final entries = ArcFrozenTrailCollectionCatalogue.blueprintEntries;
      expect(entries.where((entry) => entry.slot != null), hasLength(91));
      expect(ArcFrozenTrailBlueprintGridMigration.verifiedSlotCount, lessThan(91));
      expect(ArcFrozenTrailBlueprintGridMigration.unresolvedSlotCount, greaterThan(0));
      expect(
        ArcFrozenTrailBlueprintGridMigration.verifiedSlotCount +
            ArcFrozenTrailBlueprintGridMigration.unresolvedSlotCount,
        91,
      );
      expect(ArcFrozenTrailBlueprintGridMigration.scannerAutoApplyReady, isFalse);
    });
  });
}
