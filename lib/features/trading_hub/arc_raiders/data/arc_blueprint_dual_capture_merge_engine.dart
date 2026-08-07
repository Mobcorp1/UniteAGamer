import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_canonical_grid.dart';

@immutable
class ArcBlueprintDualCaptureMergeResult {
  const ArcBlueprintDualCaptureMergeResult({
    required this.samples,
    required this.error,
  });

  final List<ArcBlueprintPhotoOccupancySample> samples;
  final String error;

  bool get succeeded => error.isEmpty;
}

class ArcBlueprintDualCaptureMergeEngine {
  const ArcBlueprintDualCaptureMergeEngine({
    this.columns = ArcBlueprintCanonicalGrid.columns,
    this.topRows = ArcBlueprintCanonicalGrid.topRows,
    this.bottomRows = ArcBlueprintCanonicalGrid.bottomRows,
    this.finalRowCount = ArcBlueprintCanonicalGrid.finalRowColumns,
  });

  final int columns;
  final int topRows;
  final int bottomRows;
  final int finalRowCount;

  ArcBlueprintDualCaptureMergeResult merge({
    required List<ArcBlueprintPhotoOccupancySample> topSamples,
    required List<ArcBlueprintPhotoOccupancySample> bottomSamples,
  }) {
    final expectedTop = columns * topRows;
    final expectedBottom = (columns * (bottomRows - 1)) + finalRowCount;

    if (topSamples.length != expectedTop) {
      return ArcBlueprintDualCaptureMergeResult(
        samples: const <ArcBlueprintPhotoOccupancySample>[],
        error: 'The top capture must contain exactly $expectedTop positions.',
      );
    }

    if (bottomSamples.length != expectedBottom) {
      return ArcBlueprintDualCaptureMergeResult(
        samples: const <ArcBlueprintPhotoOccupancySample>[],
        error:
            'The bottom capture must contain exactly $expectedBottom real positions.',
      );
    }

    final orderedTop = List<ArcBlueprintPhotoOccupancySample>.from(topSamples)
      ..sort(_compare);
    final orderedBottom = List<ArcBlueprintPhotoOccupancySample>.from(
      bottomSamples,
    )..sort(_compare);

    final merged = <ArcBlueprintPhotoOccupancySample>[
      for (final sample in orderedTop)
        ArcBlueprintPhotoOccupancySample(
          captureId: sample.captureId,
          rowIndex: sample.rowIndex,
          columnIndex: sample.columnIndex,
          occupancyScore: sample.occupancyScore,
        ),
    ];

    for (final sample in orderedBottom) {
      final allowedColumns = _bottomColumnsForRow(sample.rowIndex);
      if (allowedColumns <= 0 || sample.columnIndex >= allowedColumns) {
        return ArcBlueprintDualCaptureMergeResult(
          samples: const <ArcBlueprintPhotoOccupancySample>[],
          error:
              'The bottom capture produced a non-existent Blueprint slot at row ${sample.rowIndex + 1}, column ${sample.columnIndex + 1}.',
        );
      }

      merged.add(
        ArcBlueprintPhotoOccupancySample(
          captureId: sample.captureId,
          rowIndex: topRows + sample.rowIndex,
          columnIndex: sample.columnIndex,
          occupancyScore: sample.occupancyScore,
        ),
      );
    }

    merged.sort(_compare);

    if (merged.length != 83) {
      return ArcBlueprintDualCaptureMergeResult(
        samples: const <ArcBlueprintPhotoOccupancySample>[],
        error:
            'The automatic two-photo merge produced ${merged.length} of 83 positions.',
      );
    }

    return ArcBlueprintDualCaptureMergeResult(
      samples: List<ArcBlueprintPhotoOccupancySample>.unmodifiable(merged),
      error: '',
    );
  }

  int _bottomColumnsForRow(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= bottomRows) return 0;
    return rowIndex == bottomRows - 1 ? finalRowCount : columns;
  }

  int _compare(
    ArcBlueprintPhotoOccupancySample a,
    ArcBlueprintPhotoOccupancySample b,
  ) {
    final rowComparison = a.rowIndex.compareTo(b.rowIndex);
    if (rowComparison != 0) return rowComparison;
    return a.columnIndex.compareTo(b.columnIndex);
  }
}
