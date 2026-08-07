import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';

@immutable
class ArcBlueprintDualCaptureMergeResult {
  const ArcBlueprintDualCaptureMergeResult({
    required this.samples,
    required this.overlapConfidence,
    required this.overlapMatched,
    required this.error,
  });

  final List<ArcBlueprintPhotoOccupancySample> samples;

  // Retained for compatibility with the existing quality-gate interface.
  // PASS 328 deliberately has no duplicated overlap row.
  final double overlapConfidence;
  final bool overlapMatched;
  final String error;

  bool get succeeded => error.isEmpty;
}

class ArcBlueprintDualCaptureMergeEngine {
  const ArcBlueprintDualCaptureMergeEngine({
    this.columns = 10,
    this.topRows = 5,
    this.bottomRows = 4,
    this.finalRowCount = 3,
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
    final expectedBottom = columns * bottomRows;

    if (topSamples.length != expectedTop) {
      return ArcBlueprintDualCaptureMergeResult(
        samples: const <ArcBlueprintPhotoOccupancySample>[],
        overlapConfidence: 1,
        overlapMatched: true,
        error: 'The top capture must contain exactly $expectedTop positions.',
      );
    }

    if (bottomSamples.length != expectedBottom) {
      return ArcBlueprintDualCaptureMergeResult(
        samples: const <ArcBlueprintPhotoOccupancySample>[],
        overlapConfidence: 1,
        overlapMatched: true,
        error:
            'The bottom capture must contain three complete rows plus the inferred final row.',
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
      final isFinalPartialRow = sample.rowIndex == bottomRows - 1;

      if (isFinalPartialRow && sample.columnIndex >= finalRowCount) {
        continue;
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
        overlapConfidence: 1,
        overlapMatched: true,
        error:
            'The automatic two-photo merge produced ${merged.length} of 83 positions.',
      );
    }

    return ArcBlueprintDualCaptureMergeResult(
      samples: List<ArcBlueprintPhotoOccupancySample>.unmodifiable(merged),
      overlapConfidence: 1,
      overlapMatched: true,
      error: '',
    );
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
