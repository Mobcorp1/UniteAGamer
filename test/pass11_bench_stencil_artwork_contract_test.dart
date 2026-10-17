import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_artwork.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_collection_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_stencil_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_collection_models.dart';

void main() {
  test('all workstation WebP assets exist and are unique', () {
    expect(ArcBenchArtwork.stationArtwork.length, 9);
    expect(ArcBenchArtwork.stationArtwork.values.toSet().length, 9);
    for (final imagePath in ArcBenchArtwork.stationArtwork.values) {
      expect(File(imagePath).existsSync(), isTrue, reason: imagePath);
    }
    expect(ArcBenchArtwork.forStation('Gunsmith'), endsWith('gunsmith.webp'));
    expect(
      ArcBenchArtwork.forStation('Research Station'),
      endsWith('research_station.webp'),
    );
    expect(ArcBenchArtwork.forStation('Outpost'), isNull);
  });

  test('new stencil art follows the existing 14-slot in-game catalogue', () {
    const expected = <int, String>{11: 'fortuna', 13: 'garnet', 14: 'ochre'};
    for (final entry in expected.entries) {
      final path = ArcStencilCatalogue.assetAt(entry.key);
      expect(path, 'assets/arc_raiders/blueprints/${entry.value}.webp');
      expect(File(path).existsSync(), isTrue, reason: path);
      final slot = ArcFrozenTrailCollectionCatalogue.entryAtSlot(
        ArcCollectionType.stencils,
        entry.key,
      );
      expect(slot?.id, entry.value);
      expect(
        ArcFrozenTrailCollectionCatalogue.frozenTrailArtworkPaths[entry.value],
        path,
      );
    }
    expect(ArcFrozenTrailCollectionCatalogue.stencilGrid.totalSlots, 14);
    expect(ArcFrozenTrailCollectionCatalogue.blueprintGrid.totalSlots, 91);
    expect(
      ArcFrozenTrailCollectionCatalogue.blueprintGrid.rowColumnCounts,
      <int>[17, 17, 17, 17, 17, 6],
    );
  });
}
