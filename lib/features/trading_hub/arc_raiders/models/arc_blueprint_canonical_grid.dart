import 'package:flutter/foundation.dart';

@immutable
class ArcBlueprintCanonicalPosition {
  const ArcBlueprintCanonicalPosition({
    required this.canonicalIndex,
    required this.localRowIndex,
    required this.globalRowIndex,
    required this.columnIndex,
  });

  final int canonicalIndex;
  final int localRowIndex;
  final int globalRowIndex;
  final int columnIndex;
}

class ArcBlueprintCanonicalGrid {
  const ArcBlueprintCanonicalGrid._();

  static const int columns = 10;
  static const int topRows = 5;
  static const int bottomFullRows = 3;
  static const int bottomRows = 4;
  static const int finalRowColumns = 3;
  static const int totalPositions = 83;

  static const List<int> topRowColumnCounts = <int>[10, 10, 10, 10, 10];
  static const List<int> bottomRowColumnCounts = <int>[10, 10, 10, 3];
  static const List<int> fullRowColumnCounts = <int>[
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    10,
    3,
  ];

  static int columnCountForGlobalRow(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= fullRowColumnCounts.length) return 0;
    return fullRowColumnCounts[rowIndex];
  }

  static int columnCountForBottomLocalRow(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= bottomRowColumnCounts.length) return 0;
    return bottomRowColumnCounts[rowIndex];
  }

  static bool hasGlobalCell({required int rowIndex, required int columnIndex}) {
    return columnIndex >= 0 && columnIndex < columnCountForGlobalRow(rowIndex);
  }

  static int? indexForGlobalCell({
    required int rowIndex,
    required int columnIndex,
  }) {
    if (!hasGlobalCell(rowIndex: rowIndex, columnIndex: columnIndex)) {
      return null;
    }
    var index = 0;
    for (var row = 0; row < rowIndex; row++) {
      index += fullRowColumnCounts[row];
    }
    return index + columnIndex;
  }

  static ArcBlueprintCanonicalPosition? positionForIndex(int canonicalIndex) {
    if (canonicalIndex < 0 || canonicalIndex >= totalPositions) return null;
    var offset = canonicalIndex;
    for (var row = 0; row < fullRowColumnCounts.length; row++) {
      final columnsInRow = fullRowColumnCounts[row];
      if (offset < columnsInRow) {
        return ArcBlueprintCanonicalPosition(
          canonicalIndex: canonicalIndex,
          localRowIndex: row,
          globalRowIndex: row,
          columnIndex: offset,
        );
      }
      offset -= columnsInRow;
    }
    return null;
  }

  static List<ArcBlueprintCanonicalPosition> topCapturePositions() {
    return <ArcBlueprintCanonicalPosition>[
      for (var row = 0; row < topRows; row++)
        for (var column = 0; column < columns; column++)
          ArcBlueprintCanonicalPosition(
            canonicalIndex: indexForGlobalCell(
              rowIndex: row,
              columnIndex: column,
            )!,
            localRowIndex: row,
            globalRowIndex: row,
            columnIndex: column,
          ),
    ];
  }

  static List<ArcBlueprintCanonicalPosition> bottomCapturePositions() {
    return <ArcBlueprintCanonicalPosition>[
      for (var row = 0; row < bottomRows; row++)
        for (
          var column = 0;
          column < columnCountForBottomLocalRow(row);
          column++
        )
          ArcBlueprintCanonicalPosition(
            canonicalIndex: indexForGlobalCell(
              rowIndex: topRows + row,
              columnIndex: column,
            )!,
            localRowIndex: row,
            globalRowIndex: topRows + row,
            columnIndex: column,
          ),
    ];
  }
}
