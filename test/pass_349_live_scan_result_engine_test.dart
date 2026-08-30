import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_occupancy_stabilizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_scan_result_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

void main() {
  ArcBlueprintLiveOccupancySnapshot segment(
    List<List<ArcBlueprintPhotoCellState>> rows,
  ) {
    final cells = <ArcBlueprintLiveCellEstimate>[];
    for (var row = 0; row < rows.length; row++) {
      for (var column = 0; column < rows[row].length; column++) {
        final state = rows[row][column];
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

  List<ArcBlueprintPhotoCellState> row(List<int> owned) {
    return List<ArcBlueprintPhotoCellState>.generate(
      10,
      (index) => owned.contains(index)
          ? ArcBlueprintPhotoCellState.owned
          : ArcBlueprintPhotoCellState.missing,
    );
  }

  test('PASS 353A reconciles a repeated row instead of duplicating it', () {
    const engine = ArcBlueprintLiveScanResultEngine();

    final r0 = row(<int>[0, 2, 3, 4, 9]);
    final r1 = row(<int>[0, 3, 4, 5]);
    final r2 = row(<int>[1, 3, 7]);
    final r3 = row(<int>[0, 1, 4, 5, 7, 8, 9]);
    final r4 = row(<int>[0, 1, 2, 8, 9]);
    final r5 = row(<int>[0, 1, 2, 6, 7]);
    final r6 = row(<int>[0, 1, 7, 8, 9]);
    final r7 = row(<int>[0, 1, 2, 3, 4, 6, 7, 8, 9]);
    final r8 = row(<int>[0]);

    final result = engine.build(
      top: segment(<List<ArcBlueprintPhotoCellState>>[r0, r1, r2, r3, r4]),
      bottom: segment(<List<ArcBlueprintPhotoCellState>>[r4, r5, r6, r7, r8]),
    );

    expect(result.succeeded, isTrue, reason: result.errors.join('\n'));
    expect(result.decisions, hasLength(ArcBlueprintSeedData.blueprints.length));
    expect(result.decisions.first.blueprintIndex, 0);
    expect(
      result.decisions.last.blueprintIndex,
      ArcBlueprintSeedData.blueprints.length - 1,
    );
  });

  test('PASS 353A refuses an incomplete second scan segment', () {
    const engine = ArcBlueprintLiveScanResultEngine();
    final full = <List<ArcBlueprintPhotoCellState>>[
      row(<int>[0]),
      row(<int>[1]),
      row(<int>[2]),
      row(<int>[3]),
      row(<int>[4]),
    ];
    final incomplete = segment(full);
    final trimmed = ArcBlueprintLiveOccupancySnapshot(
      cells: incomplete.cells.take(49).toList(growable: false),
      frameCount: 4,
    );

    final result = engine.build(top: segment(full), bottom: trimmed);

    expect(result.succeeded, isFalse);
    expect(result.decisions, isEmpty);
  });
}
