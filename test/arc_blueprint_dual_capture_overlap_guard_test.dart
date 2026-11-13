import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_dual_capture_merge_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';

ArcBlueprintPhotoOccupancySample sample(
  String capture,
  int row,
  int column,
  double score,
) {
  return ArcBlueprintPhotoOccupancySample(
    captureId: capture,
    rowIndex: row,
    columnIndex: column,
    occupancyScore: score,
  );
}

void main() {
  const engine = ArcBlueprintDualCaptureMergeEngine();

  test('normal distinct boundary rows still merge to 83', () {
    final top = <ArcBlueprintPhotoOccupancySample>[
      for (var row = 0; row < 5; row++)
        for (var column = 0; column < 10; column++)
          sample('top', row, column, row == 4 && column.isEven ? 0.95 : 0.10),
    ];

    final bottom = <ArcBlueprintPhotoOccupancySample>[
      for (var row = 0; row < 3; row++)
        for (var column = 0; column < 10; column++)
          sample('bottom', row, column, row == 0 && column.isOdd ? 0.95 : 0.10),
      for (var column = 0; column < 3; column++)
        sample('bottom', 3, column, 0.95),
    ];

    final result = engine.merge(topSamples: top, bottomSamples: bottom);
    expect(result.succeeded, isTrue);
    expect(result.samples.length, 83);
  });

  test('uniform boundary rows are not treated as repeated camera rows', () {
    final top = <ArcBlueprintPhotoOccupancySample>[
      for (var row = 0; row < 5; row++)
        for (var column = 0; column < 10; column++)
          sample('top', row, column, 0.80),
    ];

    final bottom = <ArcBlueprintPhotoOccupancySample>[
      for (var row = 0; row < 3; row++)
        for (var column = 0; column < 10; column++)
          sample('bottom', row, column, 0.80),
      for (var column = 0; column < 3; column++)
        sample('bottom', 3, column, 0.80),
    ];

    final result = engine.merge(topSamples: top, bottomSamples: bottom);

    expect(result.succeeded, isTrue);
    expect(result.samples, hasLength(83));
  });

  test('near-identical repeated boundary row is rejected', () {
    final top = <ArcBlueprintPhotoOccupancySample>[
      for (var row = 0; row < 5; row++)
        for (var column = 0; column < 10; column++)
          sample('top', row, column, row == 4 && column < 5 ? 0.96 : 0.10),
    ];

    final bottom = <ArcBlueprintPhotoOccupancySample>[
      for (var row = 0; row < 3; row++)
        for (var column = 0; column < 10; column++)
          sample(
            'bottom',
            row,
            column,
            row == 0 ? (column < 5 ? 0.95 : 0.11) : 0.10,
          ),
      for (var column = 0; column < 3; column++)
        sample('bottom', 3, column, 0.10),
    ];

    final result = engine.merge(topSamples: top, bottomSamples: bottom);
    expect(result.succeeded, isFalse);
    expect(result.error, contains('appears to repeat'));
  });
  test('structural final-row errors take priority over overlap diagnosis', () {
    final top = <ArcBlueprintPhotoOccupancySample>[
      for (var row = 0; row < 5; row++)
        for (var column = 0; column < 10; column++)
          sample('top', row, column, row == 4 && column < 5 ? 0.96 : 0.10),
    ];

    final bottom = <ArcBlueprintPhotoOccupancySample>[
      for (var row = 0; row < 3; row++)
        for (var column = 0; column < 10; column++)
          sample(
            'bottom',
            row,
            column,
            row == 0 ? (column < 5 ? 0.95 : 0.11) : 0.10,
          ),
      sample('bottom', 3, 0, 0.10),
      sample('bottom', 3, 1, 0.10),
      sample('bottom', 3, 9, 0.10),
    ];

    final result = engine.merge(topSamples: top, bottomSamples: bottom);

    expect(result.succeeded, isFalse);
    expect(result.error, contains('non-existent Blueprint slot'));
  });
}
