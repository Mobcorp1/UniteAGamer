import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_stencil_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_collection_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_collection_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart';

void main() {
  const incoming = <int, (String, String)>{
    15: ('Sundog', 'sundog.webp'),
    16: ('Malocchio', 'malocchio.webp'),
    17: ('Taurus', 'taurus.webp'),
    18: ('Golden Olive', 'golden-olive.webp'),
  };

  test('18 Stencils: confirmed names, identity, grid positions and image paths', () {
    expect(ArcStencilCatalogue.names.length, 18);
    expect(ArcStencilCatalogue.fileNames.length, 18);
    expect(ArcNativeCollectionKind.stencils.slots, 18);
    expect(ArcFrozenTrailCollectionCatalogue.stencilGrid.totalSlots, 18);
    expect(ArcFrozenTrailCollectionCatalogue.stencilGrid.rowColumnCounts, [9, 9]);
    for (final entry in incoming.entries) {
      expect(ArcStencilCatalogue.nameAt(entry.key), entry.value.$1);
      expect(ArcStencilCatalogue.assetAt(entry.key),
          'assets/arc_raiders/blueprints/${entry.value.$2}');
      final registry = ArcFrozenTrailCollectionCatalogue.entryAtSlot(
          ArcCollectionType.stencils, entry.key);
      expect(registry?.name, entry.value.$1);
      expect(registry?.confidence, ArcCollectionSlotConfidence.verifiedInGame);
      if (entry.key >= 15 && entry.key <= 17) {
        expect(registry?.sourceLabel, 'In-game shop');
      }
    }
  });

  test('newly confirmed 18th stencil can be persisted without renumbering existing slots', () {
    final original = ArcAdditionalCollectionState.merge(
      const ArcAdditionalCollectionState(),
      ArcNativeCollectionKind.stencils,
      const <int>{2, 3, 5, 6, 7, 9},
      const <int, int>{2: 2},
    );
    final expanded = ArcAdditionalCollectionState.merge(
      original,
      ArcNativeCollectionKind.stencils,
      const <int>{15, 16, 17, 18},
      const <int, int>{18: 1},
    );
    expect(expanded.ownedSlots, <int>{2, 3, 5, 6, 7, 9, 15, 16, 17, 18});
    expect(expanded.duplicateCounts, <int, int>{2: 2, 18: 1});
    expect(ArcCollectionSlotRepository.decodeOwned(
      <dynamic>[18, 19, -1, 14, 1], ArcNativeCollectionKind.stencils,
    ), <int>{18, 14, 1});
  });

  test('bundled image lookup supports edited compressed filenames', () {
    expect(
      ArcStencilCatalogue.bundledAssetAt(15, const [
        'assets/arc_raiders/blueprints/Sundog.webp',
      ]),
      'assets/arc_raiders/blueprints/Sundog.webp',
    );
    expect(
      ArcStencilCatalogue.bundledAssetAt(16, const [
        'assets/arc_raiders/blueprints/Malcio.webp',
        'assets/arc_raiders/blueprints/malocchio.webp',
      ]),
      'assets/arc_raiders/blueprints/malocchio.webp',
    );
    expect(
      ArcStencilCatalogue.bundledAssetAt(17, const [
        'assets/arc_raiders/blueprints/taurus.png',
      ]),
      'assets/arc_raiders/blueprints/taurus.png',
    );
    expect(
      ArcStencilCatalogue.bundledAssetAt(18, const [
        'assets/arc_raiders/blueprints/unknown_stencil.webp',
        'assets/arc_raiders/blueprints/Golden Olive.webp',
      ]),
      'assets/arc_raiders/blueprints/Golden Olive.webp',
    );
    expect(
      ArcStencilCatalogue.bundledAssetAt(18, const [
        'assets/arc_raiders/blueprints/sundog.webp',
      ]),
      isNull,
    );
  });
}
