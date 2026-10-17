import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_collection_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_collection_models.dart';

void main() {
  test('Grid 12 canonical 91 cells and identity uniqueness', () {
    final entries = ArcFrozenTrailCollectionCatalogue.blueprintEntries;
    final mapped = entries.where((e) => e.slot != null).toList();
    expect(mapped.length, 91);
    expect(entries.map((e) => e.id).toSet().length, entries.length);
    expect(mapped.map((e) => e.slot).toSet().length, mapped.length);
    expect(
      ArcFrozenTrailCollectionCatalogue.blueprintGrid.rowColumnCounts,
      <int>[17, 17, 17, 17, 17, 6],
    );
    for (final slot in <int>[28, 59, 90]) {
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
    for (final pair in <int, String>{
      10: 'vita-spray',
      23: 'extended-light-mag-ii',
      26: 'stiletto',
      27: 'angled-grip-ii',
      28: 'stable-stock-iii',
      45: 'extended-shotgun-mag-ii',
      57: 'combat-mk-3-aggressive',
      59: 'light-gun-parts',
      79: 'trigger-nade',
      81: 'silencer-i',
      84: 'vertical-grip-ii',
      86: 'muzzle-brake-ii',
      90: 'equalizer',
      91: 'snap-hook',
    }.entries) {
      expect(
        ArcFrozenTrailCollectionCatalogue.entryAtSlot(
          ArcCollectionType.blueprints,
          pair.key,
        )?.id,
        pair.value,
        reason: 'slot ${pair.key} must retain its legacy identity',
      );
    }
    expect(entries.singleWhere((e) => e.id == 'stiletto').slot, 26);
    expect(entries.any((e) => e.id == 'vita-shot' && e.slot == 38), isTrue);
  });
}
