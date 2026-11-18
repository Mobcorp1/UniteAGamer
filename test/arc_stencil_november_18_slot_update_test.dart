import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_collection_slot_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_native_collection_screenshot_recognizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_stencil_catalogue.dart';

void main() {
  test('November 2026 Stencil expansion is wired as 18 positions', () {
    expect(ArcStencilCatalogue.slotCount, 18);
    expect(ArcStencilCatalogue.columns, 9);
    expect(ArcStencilCatalogue.names.length, 18);
    expect(ArcStencilCatalogue.fileNames.length, 18);

    expect(ArcStencilCatalogue.nameAt(14), 'Ochre');
    expect(ArcStencilCatalogue.nameAt(15), 'Sundog');
    expect(ArcStencilCatalogue.nameAt(16), 'Malocchio');
    expect(ArcStencilCatalogue.nameAt(17), 'Taurus');
    expect(ArcStencilCatalogue.nameAt(18), 'Unknown Stencil');

    expect(
      ArcStencilCatalogue.assetAt(15),
      'assets/arc_raiders/blueprints/sundog.webp',
    );
    expect(
      ArcStencilCatalogue.assetAt(16),
      'assets/arc_raiders/blueprints/malocchio.webp',
    );
    expect(
      ArcStencilCatalogue.assetAt(17),
      'assets/arc_raiders/blueprints/taurus.webp',
    );
    expect(
      ArcStencilCatalogue.assetAt(18),
      'assets/arc_raiders/blueprints/unknown-stencil.webp',
    );

    expect(ArcNativeCollectionKind.stencils.slots, 18);
    expect(ArcNativeCollectionKind.stencils.columns, 9);
  });

  test('Stencil persistence accepts new slot 18 and rejects 19', () {
    final state = ArcAdditionalCollectionState.merge(
      const ArcAdditionalCollectionState(),
      ArcNativeCollectionKind.stencils,
      const <int>{18},
      const <int, int>{},
    );
    expect(state.ownedSlots, contains(18));

    expect(
      () => ArcAdditionalCollectionState.merge(
        const ArcAdditionalCollectionState(),
        ArcNativeCollectionKind.stencils,
        const <int>{19},
        const <int, int>{},
      ),
      throwsRangeError,
    );
  });
}
