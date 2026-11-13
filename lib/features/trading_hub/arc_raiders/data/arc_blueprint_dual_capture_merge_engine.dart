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

    // Validate every physical bottom-capture slot before attempting any
    // similarity-based overlap diagnosis. Structural errors must retain their
    // precise legacy messages and cannot be masked by the overlap guard.
    for (final sample in orderedBottom) {
      final allowedColumns = _bottomColumnsForRow(sample.rowIndex);
      if (allowedColumns <= 0 || sample.columnIndex >= allowedColumns) {
        return ArcBlueprintDualCaptureMergeResult(
          samples: const <ArcBlueprintPhotoOccupancySample>[],
          error:
              'The bottom capture produced a non-existent Blueprint slot at row ${sample.rowIndex + 1}, column ${sample.columnIndex + 1}.',
        );
      }
    }

    final overlapError = _detectRepeatedBoundaryRow(
      orderedTop: orderedTop,
      orderedBottom: orderedBottom,
    );
    if (overlapError != null) {
      return ArcBlueprintDualCaptureMergeResult(
        samples: const <ArcBlueprintPhotoOccupancySample>[],
        error: overlapError,
      );
    }

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

  String? _detectRepeatedBoundaryRow({
    required List<ArcBlueprintPhotoOccupancySample> orderedTop,
    required List<ArcBlueprintPhotoOccupancySample> orderedBottom,
  }) {
    final topBoundary = orderedTop
        .where((sample) => sample.rowIndex == topRows - 1)
        .toList(growable: false);
    final bottomBoundary = orderedBottom
        .where((sample) => sample.rowIndex == 0)
        .toList(growable: false);

    if (topBoundary.length != columns || bottomBoundary.length != columns) {
      return null;
    }

    var absoluteDifference = 0.0;
    var matchingBands = 0;

    var topMinimum = 1.0;
    var topMaximum = 0.0;
    var bottomMinimum = 1.0;
    var bottomMaximum = 0.0;

    for (var index = 0; index < columns; index++) {
      final topScore = topBoundary[index].occupancyScore;
      final bottomScore = bottomBoundary[index].occupancyScore;
      absoluteDifference += (topScore - bottomScore).abs();

      if (topScore < topMinimum) topMinimum = topScore;
      if (topScore > topMaximum) topMaximum = topScore;
      if (bottomScore < bottomMinimum) bottomMinimum = bottomScore;
      if (bottomScore > bottomMaximum) bottomMaximum = bottomScore;

      final topBand = _occupancyBand(topScore);
      final bottomBand = _occupancyBand(bottomScore);
      if (topBand == bottomBand) matchingBands++;
    }

    final meanDifference = absoluteDifference / columns;
    final topRange = topMaximum - topMinimum;
    final bottomRange = bottomMaximum - bottomMinimum;

    // A repeated physical row should contain a distinctive occupancy pattern.
    // Uniform synthetic rows (for example every sample = 0.8) contain no
    // discriminating information and must never trip this guard. Requiring
    // meaningful score spread also prevents two naturally similar adjacent
    // rows from being rejected just because most cells share one band.
    final hasDistinctivePattern = topRange >= 0.30 && bottomRange >= 0.30;

    // Deliberately conservative. This only trips when:
    //  - both rows contain a distinctive high/low pattern,
    //  - at least 9 of 10 cells occupy the same classification band, and
    //  - continuous scores are extremely close.
    if (hasDistinctivePattern &&
        meanDifference <= 0.022 &&
        matchingBands >= 9) {
      return 'The second capture appears to repeat the final row from the '
          'first capture. Scroll until the next Blueprint row is fully at the '
          'top, then retake the second image.';
    }

    return null;
  }

  int _occupancyBand(double score) {
    if (score >= 0.84) return 2;
    if (score <= 0.22) return 0;
    return 1;
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
