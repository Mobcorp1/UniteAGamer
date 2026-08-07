import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_canonical_grid.dart';

void main() {
  test('defines the authoritative 83-position Blueprint grid', () {
    expect(ArcBlueprintCanonicalGrid.topCapturePositions(), hasLength(50));
    expect(ArcBlueprintCanonicalGrid.bottomCapturePositions(), hasLength(33));
    expect(ArcBlueprintCanonicalGrid.totalPositions, 83);
  });

  test('final row contains only canonical columns 0, 1 and 2', () {
    final finalRow = <int>[
      for (var column = 0; column < ArcBlueprintCanonicalGrid.columns; column++)
        if (ArcBlueprintCanonicalGrid.hasGlobalCell(
          rowIndex: 8,
          columnIndex: column,
        ))
          column,
    ];

    expect(finalRow, [0, 1, 2]);
    expect(
      ArcBlueprintCanonicalGrid.indexForGlobalCell(rowIndex: 8, columnIndex: 3),
      isNull,
    );
  });

  test('canonical index 82 resolves to row 8 column 2', () {
    final position = ArcBlueprintCanonicalGrid.positionForIndex(82);

    expect(position, isNotNull);
    expect(position!.globalRowIndex, 8);
    expect(position.columnIndex, 2);
  });
}
