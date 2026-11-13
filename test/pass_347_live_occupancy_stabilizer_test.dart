import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_occupancy_stabilizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

void main() {
  ArcBlueprintPhotoOccupancySample sample(
    double score, {
    int row = 0,
    int column = 0,
  }) {
    return ArcBlueprintPhotoOccupancySample(
      captureId: 'frame',
      rowIndex: row,
      columnIndex: column,
      occupancyScore: score,
    );
  }

  test('requires repeated agreement before a live cell becomes stable', () {
    final stabilizer = ArcBlueprintLiveOccupancyStabilizer();

    var snapshot = stabilizer.addFrame(<ArcBlueprintPhotoOccupancySample>[
      sample(0.94),
    ]);
    expect(snapshot.cells.single.stable, isFalse);

    snapshot = stabilizer.addFrame(<ArcBlueprintPhotoOccupancySample>[
      sample(0.92),
    ]);
    expect(snapshot.cells.single.stable, isFalse);

    snapshot = stabilizer.addFrame(<ArcBlueprintPhotoOccupancySample>[
      sample(0.95),
    ]);

    expect(snapshot.cells.single.stable, isTrue);
    expect(snapshot.cells.single.state, ArcBlueprintPhotoCellState.owned);
    expect(snapshot.ownedStableCount, 1);
  });

  test('conflicting live frames do not produce a stable ownership result', () {
    final stabilizer = ArcBlueprintLiveOccupancyStabilizer();

    for (final score in <double>[0.95, 0.05, 0.92, 0.08, 0.94]) {
      stabilizer.addFrame(<ArcBlueprintPhotoOccupancySample>[sample(score)]);
    }

    final snapshot = stabilizer.addFrame(<ArcBlueprintPhotoOccupancySample>[
      sample(0.10),
    ]);

    expect(snapshot.cells.single.stable, isFalse);
  });

  test('reset removes prior section observations', () {
    final stabilizer = ArcBlueprintLiveOccupancyStabilizer();

    for (var index = 0; index < 3; index++) {
      stabilizer.addFrame(<ArcBlueprintPhotoOccupancySample>[
        sample(0.04, row: 2, column: 7),
      ]);
    }

    expect(
      stabilizer.addFrame(<ArcBlueprintPhotoOccupancySample>[
        sample(0.03, row: 2, column: 7),
      ]).stableCellCount,
      1,
    );

    stabilizer.reset();

    final afterReset = stabilizer.addFrame(<ArcBlueprintPhotoOccupancySample>[
      sample(0.04, row: 5, column: 0),
    ]);
    expect(afterReset.frameCount, 1);
    expect(afterReset.cells.single.rowIndex, 5);
    expect(afterReset.cells.single.stable, isFalse);
  });
}
