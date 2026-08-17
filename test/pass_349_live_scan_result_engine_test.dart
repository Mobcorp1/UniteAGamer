import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_occupancy_stabilizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_scan_result_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

void main() {
  ArcBlueprintLiveOccupancySnapshot section(
    int startRow,
    int rows,
    ArcBlueprintPhotoCellState state,
  ) {
    final cells = <ArcBlueprintLiveCellEstimate>[];
    for (var row = startRow; row < startRow + rows; row++) {
      final columns = row == 8 ? 3 : 10;
      for (var column = 0; column < columns; column++) {
        cells.add(
          ArcBlueprintLiveCellEstimate(
            rowIndex: row,
            columnIndex: column,
            state: state,
            occupancyScore: state == ArcBlueprintPhotoCellState.owned
                ? 0.93
                : 0.08,
            confidence: 0.94,
            observationCount: 4,
            stable: true,
          ),
        );
      }
    }
    return ArcBlueprintLiveOccupancySnapshot(cells: cells, frameCount: 4);
  }

  test('PASS 349 maps all 83 stable live cells to canonical decisions', () {
    const engine = ArcBlueprintLiveScanResultEngine();
    final result = engine.build(
      top: section(0, 5, ArcBlueprintPhotoCellState.owned),
      bottom: section(5, 4, ArcBlueprintPhotoCellState.missing),
    );
    expect(result.succeeded, isTrue);
    expect(result.decisions, hasLength(83));
    expect(result.decisions.first.blueprintIndex, 0);
    expect(result.decisions.last.blueprintIndex, 82);
    expect(result.decisions.last.rowIndex, 8);
    expect(result.decisions.last.columnIndex, 2);
  });

  test('PASS 349 refuses incomplete live sections', () {
    const engine = ArcBlueprintLiveScanResultEngine();
    final bottom = section(5, 4, ArcBlueprintPhotoCellState.missing);
    final incomplete = ArcBlueprintLiveOccupancySnapshot(
      cells: bottom.cells.take(32).toList(),
      frameCount: 4,
    );
    final result = engine.build(
      top: section(0, 5, ArcBlueprintPhotoCellState.owned),
      bottom: incomplete,
    );
    expect(result.succeeded, isFalse);
    expect(result.decisions, isEmpty);
  });
}
