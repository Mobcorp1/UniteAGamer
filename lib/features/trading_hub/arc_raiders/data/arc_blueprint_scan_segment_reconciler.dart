import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_occupancy_stabilizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

@immutable
class ArcBlueprintScanSegmentAlignment {
  const ArcBlueprintScanSegmentAlignment({
    required this.secondStartRow,
    required this.overlapRows,
    required this.agreement,
    required this.usedFallback,
  });

  final int secondStartRow;
  final int overlapRows;
  final double agreement;
  final bool usedFallback;
}

@immutable
class ArcBlueprintReconciledScan {
  const ArcBlueprintReconciledScan({
    required this.cells,
    required this.alignment,
    required this.conflictCount,
  });

  final List<ArcBlueprintLiveCellEstimate> cells;
  final ArcBlueprintScanSegmentAlignment alignment;
  final int conflictCount;
}

/// Aligns two scanner segments by their repeated ownership pattern.
///
/// ARC currently repeats the final visible row of the first Blueprint screen at
/// the top of the second screen. PASS 353A deliberately does not hard-code that
/// row number: it searches all plausible overlaps and falls back to contiguous
/// segments when no overlap is reliable.
class ArcBlueprintScanSegmentReconciler {
  const ArcBlueprintScanSegmentReconciler({
    this.columns = 10,
    this.minimumComparedCells = 6,
    this.minimumAgreement = 0.72,
  });

  final int columns;
  final int minimumComparedCells;
  final double minimumAgreement;

  ArcBlueprintReconciledScan reconcile({
    required ArcBlueprintLiveOccupancySnapshot first,
    required ArcBlueprintLiveOccupancySnapshot second,
  }) {
    final firstRows = _rowCount(first.cells);
    final secondRows = _rowCount(second.cells);

    final best = _findAlignment(
      first: first.cells,
      second: second.cells,
      firstRows: firstRows,
      secondRows: secondRows,
    );

    final alignment =
        best ??
        ArcBlueprintScanSegmentAlignment(
          secondStartRow: firstRows,
          overlapRows: 0,
          agreement: 0,
          usedFallback: true,
        );

    final byIndex = <int, ArcBlueprintLiveCellEstimate>{};
    var conflicts = 0;

    void add(ArcBlueprintLiveCellEstimate cell, {required int rowOffset}) {
      final mappedRow = cell.rowIndex + rowOffset;
      if (mappedRow < 0 ||
          cell.columnIndex < 0 ||
          cell.columnIndex >= columns) {
        return;
      }

      final mapped = ArcBlueprintLiveCellEstimate(
        rowIndex: mappedRow,
        columnIndex: cell.columnIndex,
        state: cell.state,
        occupancyScore: cell.occupancyScore,
        confidence: cell.confidence,
        observationCount: cell.observationCount,
        stable: cell.stable,
      );
      final key = (mappedRow * columns) + cell.columnIndex;
      final previous = byIndex[key];
      if (previous == null) {
        byIndex[key] = mapped;
        return;
      }

      if (previous.state == mapped.state) {
        final totalWeight = math.max(
          0.001,
          previous.confidence + mapped.confidence,
        );
        byIndex[key] = ArcBlueprintLiveCellEstimate(
          rowIndex: mappedRow,
          columnIndex: mapped.columnIndex,
          state: mapped.state,
          occupancyScore:
              ((previous.occupancyScore * previous.confidence) +
                  (mapped.occupancyScore * mapped.confidence)) /
              totalWeight,
          confidence: math.max(previous.confidence, mapped.confidence),
          observationCount: previous.observationCount + mapped.observationCount,
          stable: previous.stable && mapped.stable,
        );
        return;
      }

      conflicts += 1;
      final confidenceGap = (previous.confidence - mapped.confidence).abs();
      if (confidenceGap >= 0.18) {
        byIndex[key] = previous.confidence >= mapped.confidence
            ? previous
            : mapped;
        return;
      }

      byIndex[key] = ArcBlueprintLiveCellEstimate(
        rowIndex: mappedRow,
        columnIndex: mapped.columnIndex,
        state: ArcBlueprintPhotoCellState.uncertain,
        occupancyScore: (previous.occupancyScore + mapped.occupancyScore) / 2,
        confidence: math.min(previous.confidence, mapped.confidence) * 0.65,
        observationCount: previous.observationCount + mapped.observationCount,
        stable: false,
      );
    }

    for (final cell in first.cells) {
      add(cell, rowOffset: 0);
    }
    for (final cell in second.cells) {
      add(cell, rowOffset: alignment.secondStartRow);
    }

    final cells = byIndex.values.toList()
      ..sort((a, b) {
        final row = a.rowIndex.compareTo(b.rowIndex);
        return row != 0 ? row : a.columnIndex.compareTo(b.columnIndex);
      });

    return ArcBlueprintReconciledScan(
      cells: List<ArcBlueprintLiveCellEstimate>.unmodifiable(cells),
      alignment: alignment,
      conflictCount: conflicts,
    );
  }

  ArcBlueprintScanSegmentAlignment? _findAlignment({
    required List<ArcBlueprintLiveCellEstimate> first,
    required List<ArcBlueprintLiveCellEstimate> second,
    required int firstRows,
    required int secondRows,
  }) {
    if (firstRows <= 0 || secondRows <= 0) return null;

    ArcBlueprintScanSegmentAlignment? best;

    // A second segment may overlap one or more rows, or have no overlap.
    for (var startRow = 1; startRow < firstRows; startRow++) {
      final overlapRows = math.min(firstRows - startRow, secondRows);
      if (overlapRows <= 0) continue;

      var compared = 0;
      var weightedMatches = 0.0;
      var totalWeight = 0.0;

      for (var localRow = 0; localRow < overlapRows; localRow++) {
        final globalRow = startRow + localRow;
        for (var column = 0; column < columns; column++) {
          final a = _cellAt(first, globalRow, column);
          final b = _cellAt(second, localRow, column);
          if (a == null ||
              b == null ||
              !a.stable ||
              !b.stable ||
              a.state == ArcBlueprintPhotoCellState.uncertain ||
              b.state == ArcBlueprintPhotoCellState.uncertain) {
            continue;
          }

          final weight = math.max(0.20, math.min(a.confidence, b.confidence));
          compared += 1;
          totalWeight += weight;
          if (a.state == b.state) {
            weightedMatches += weight;
          }
        }
      }

      if (compared < minimumComparedCells || totalWeight <= 0) continue;
      final agreement = weightedMatches / totalWeight;
      if (agreement < minimumAgreement) continue;

      final candidate = ArcBlueprintScanSegmentAlignment(
        secondStartRow: startRow,
        overlapRows: overlapRows,
        agreement: agreement,
        usedFallback: false,
      );

      if (best == null ||
          candidate.agreement > best.agreement + 0.015 ||
          ((candidate.agreement - best.agreement).abs() <= 0.015 &&
              candidate.overlapRows < best.overlapRows)) {
        best = candidate;
      }
    }

    return best;
  }

  int _rowCount(List<ArcBlueprintLiveCellEstimate> cells) {
    if (cells.isEmpty) return 0;
    return cells.map((cell) => cell.rowIndex).reduce(math.max) + 1;
  }

  ArcBlueprintLiveCellEstimate? _cellAt(
    List<ArcBlueprintLiveCellEstimate> cells,
    int row,
    int column,
  ) {
    for (final cell in cells) {
      if (cell.rowIndex == row && cell.columnIndex == column) return cell;
    }
    return null;
  }
}
