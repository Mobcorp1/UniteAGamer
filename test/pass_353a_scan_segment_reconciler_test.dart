import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_occupancy_stabilizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_scan_segment_reconciler.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

void main() {
  ArcBlueprintLiveOccupancySnapshot snapshot(List<List<bool>> rows) {
    final cells = <ArcBlueprintLiveCellEstimate>[];
    for (var row = 0; row < rows.length; row++) {
      for (var column = 0; column < rows[row].length; column++) {
        final owned = rows[row][column];
        cells.add(
          ArcBlueprintLiveCellEstimate(
            rowIndex: row,
            columnIndex: column,
            state: owned
                ? ArcBlueprintPhotoCellState.owned
                : ArcBlueprintPhotoCellState.missing,
            occupancyScore: owned ? 0.94 : 0.06,
            confidence: 0.95,
            observationCount: 4,
            stable: true,
          ),
        );
      }
    }
    return ArcBlueprintLiveOccupancySnapshot(cells: cells, frameCount: 4);
  }

  test('detects one repeated row between two five-row segments', () {
    final rows = <List<bool>>[
      <bool>[true, false, true, true, false, false, true, false, false, true],
      <bool>[false, true, true, false, true, false, false, true, false, true],
      <bool>[true, true, false, false, false, true, false, true, true, false],
      <bool>[false, false, true, true, true, false, true, false, true, false],
      <bool>[true, false, false, true, false, true, true, false, false, true],
      <bool>[false, true, false, true, true, false, false, true, true, false],
      <bool>[true, true, true, false, false, false, true, false, false, false],
      <bool>[false, true, true, true, false, true, false, false, true, true],
      <bool>[true, false, true, false, true, false, true, false, true, false],
    ];

    final result = const ArcBlueprintScanSegmentReconciler().reconcile(
      first: snapshot(rows.sublist(0, 5)),
      second: snapshot(rows.sublist(4, 9)),
    );

    expect(result.alignment.usedFallback, isFalse);
    expect(result.alignment.secondStartRow, 4);
    expect(result.alignment.overlapRows, 1);
    expect(result.alignment.agreement, greaterThan(0.99));
    expect(result.conflictCount, 0);
  });
}
