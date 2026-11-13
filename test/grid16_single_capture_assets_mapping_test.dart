import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_collection_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_collection_models.dart';

void main() {
  test('New locations do not overwrite unrelated Blueprint IDs', () {
    final entries = ArcFrozenTrailCollectionCatalogue.blueprintEntries;
    expect(
      ArcFrozenTrailCollectionCatalogue.entryAtSlot(
        ArcCollectionType.blueprints,
        58,
      )?.id,
      'grappling-hook',
    );
    expect(
      ArcFrozenTrailCollectionCatalogue.entryAtSlot(
        ArcCollectionType.blueprints,
        88,
      )?.id,
      'yank-grenade',
    );
    expect(
      entries.where((e) => e.slot != null).map((e) => e.slot).toSet().length,
      entries.where((e) => e.slot != null).length,
    );
    expect(
      entries.where((e) => e.id == 'vita-shot' && e.slot == 38),
      hasLength(1),
    );
  });
  test('All four new artwork references have canonical WebP paths', () {
    final paths = ArcFrozenTrailCollectionCatalogue.frozenTrailArtworkPaths;
    for (final name in [
      'stiletto',
      'banjo',
      'advanced-camera',
      'emperor-gateway-conduit',
    ]) {
      expect(paths[name], 'assets/arc_raiders/blueprints/$name.webp');
    }
  });
  test(
    'The image preview is the recognition image, not the raw camera capture',
    () {
      final src = File(
        'lib/features/trading_hub/arc_raiders/screens/arc_frozen_trail_single_grid_capture_screen.dart',
      ).readAsStringSync();
      expect(
        RegExp(r'_image\s*=\s*registeredImage\s*;').hasMatch(src),
        isTrue,
      );
      expect(
        src,
        contains('viewportSize: Size(request.width, request.height)'),
      );
      expect(src, contains('Update Blueprint Collection'));
    },
  );
}
