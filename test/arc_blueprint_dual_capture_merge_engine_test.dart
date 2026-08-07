import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_dual_capture_merge_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';

ArcBlueprintPhotoOccupancySample sample(String captureId, int row, int column) {
  return ArcBlueprintPhotoOccupancySample(
    captureId: captureId,
    rowIndex: row,
    columnIndex: column,
    occupancyScore: 0.8,
  );
}

void main() {
  test('merges 50 top and 33 real bottom positions into 83', () {
    final top = <ArcBlueprintPhotoOccupancySample>[
      for (var row = 0; row < 5; row++)
        for (var column = 0; column < 10; column++) sample('top', row, column),
    ];

    final bottom = <ArcBlueprintPhotoOccupancySample>[
      for (var row = 0; row < 4; row++)
        for (var column = 0; column < 10; column++)
          sample('bottom', row, column),
    ];

    final result = const ArcBlueprintDualCaptureMergeEngine().merge(
      topSamples: top,
      bottomSamples: bottom,
    );

    expect(result.succeeded, isTrue);
    expect(result.samples, hasLength(83));
    expect(result.samples.last.rowIndex, 8);
    expect(result.samples.last.columnIndex, 2);
  });
}
