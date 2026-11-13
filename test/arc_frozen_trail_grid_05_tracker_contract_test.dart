import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_collection_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_collection_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_frozen_trail_blueprint_grid_migration.dart';

void main() {
  test('91-slot tracker retains canonical anchors and unresolved slots', () {
    expect(ArcFrozenTrailCollectionCatalogue.blueprintGrid.totalSlots, 91);
    expect(ArcFrozenTrailCollectionCatalogue.blueprintGrid.rowColumnCounts,
        [17, 17, 17, 17, 17, 6]);
    for (final entry in {
      40: 'banjo', 46: 'advanced-camera', 68: 'emperor-gateway-conduit',
      86: 'muzzle-brake-ii', 91: 'snap-hook',
    }.entries) {
      expect(ArcFrozenTrailCollectionCatalogue.entryAtSlot(
          ArcCollectionType.blueprints, entry.key)?.id, entry.value);
    }
    expect(ArcFrozenTrailBlueprintGridMigration.scannerAutoApplyReady, isFalse);
  });
  test('interactive tracker keeps unknown slots non-interactive', () {
    final source = File('lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart').readAsStringSync();
    expect(source, contains('_gridColumns = 17'));
    expect(source, contains('_unknownGridCell(blueprint.sortOrder)'));
    expect(source, contains('_frozenTrailBlueprints()'));
    expect(source, contains('_fullGridWithUnknownCells(filteredByState)'));
    expect(source, contains('!_isUnknownGridCell(item)'));
  });
}
