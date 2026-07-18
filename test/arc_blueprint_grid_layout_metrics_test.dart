import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_layout_metrics.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_view_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';

void main() {
  group('ArcBlueprintGridLayoutMetrics', () {
    test('calculates first five row frame bounds', () {
      const metrics = ArcBlueprintGridLayoutMetrics(
        itemCount: 83,
        columns: 10,
        tileWidth: 96,
        childAspectRatio: 0.98,
        spacing: 6,
      );

      final frame = metrics.frameForTopRows();

      expect(metrics.rowCount, 9);
      expect(frame.top, -3);
      expect(frame.left, -3);
      expect(frame.width, metrics.naturalWidth + 6);
      expect(frame.height, greaterThan(metrics.tileHeight * 5));
      expect(frame.height, lessThan(metrics.naturalHeight));
    });

    test('framed layout maximises five rows inside available space', () {
      final layout = ArcBlueprintGridLayoutMetrics.framedLayout(
        itemCount: 83,
        columns: 10,
        childAspectRatio: 0.98,
        spacing: 6,
        availableWidth: 1120,
        availableHeight: 590,
      );

      expect(layout.visibleRows, 5);
      expect(layout.viewportWidth, lessThanOrEqualTo(1120));
      expect(layout.viewportHeight, lessThanOrEqualTo(590));
      expect(layout.gridHeight, greaterThan(layout.viewportHeight));
      expect(layout.tileWidth, greaterThan(90));
    });

    test('framed layout remains centred and compact on portrait width', () {
      final layout = ArcBlueprintGridLayoutMetrics.framedLayout(
        itemCount: 83,
        columns: 10,
        childAspectRatio: 0.98,
        spacing: 6,
        availableWidth: 340,
        availableHeight: 520,
      );

      expect(layout.visibleRows, 5);
      expect(layout.viewportWidth, lessThanOrEqualTo(340));
      expect(layout.viewportHeight, lessThan(250));
      expect(layout.gridWidth, layout.viewportWidth);
    });

    test('jump target moves by five rows with orientation overlap', () {
      final target = ArcBlueprintGridLayoutMetrics.jumpTranslationY(
        currentTranslationY: 0,
        scale: 1,
        viewportHeight: 500,
        fittedGridHeight: 900,
        rowCount: 9,
        down: true,
      );

      // The requested five-row jump exceeds the remaining scrollable range,
      // so it must clamp exactly to the bottom of the grid.
      expect(target, -400);

      final upper = ArcBlueprintGridLayoutMetrics.jumpTranslationY(
        currentTranslationY: target,
        scale: 1,
        viewportHeight: 500,
        fittedGridHeight: 900,
        rowCount: 9,
        down: false,
      );

      expect(upper, 0);
    });

    test('jump state disables safely when the full grid is visible', () {
      final state = ArcBlueprintGridLayoutMetrics.jumpState(
        currentTranslationY: 0,
        scale: 1,
        viewportHeight: 450,
        fittedGridHeight: 450,
        rowCount: 9,
      );

      expect(state.canJumpUp, isFalse);
      expect(state.canJumpDown, isFalse);
    });

    test('view mode storage is stable and defaults to framed view', () {
      expect(
        ArcBlueprintGridViewMode.fromStorage('full_overview'),
        ArcBlueprintGridViewMode.fullOverview,
      );
      expect(
        ArcBlueprintGridViewMode.fromStorage('unknown'),
        ArcBlueprintGridViewMode.inGameFramed,
      );
      expect(
        ArcBlueprintGridViewMode.inGameFramed.storageValue,
        'in_game_framed',
      );
    });

    test('canonical blueprint order remains sortOrder driven', () {
      final ordered = [...ArcBlueprintSeedData.blueprints]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      expect(ordered.take(5).map((blueprint) => blueprint.name), [
        'Extended Shotgun Mag III',
        'Angled Grip III',
        'Pulse Mine',
        'Silencer II',
        'Red Light Stick',
      ]);
      expect(ArcBlueprintSeedData.columns, 10);
      expect(ArcBlueprintSeedData.rows, 9);
    });
  });
}
