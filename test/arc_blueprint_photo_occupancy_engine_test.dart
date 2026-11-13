import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_canonical_grid.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

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

List<String> get ids => List<String>.generate(
  ArcBlueprintCanonicalGrid.totalPositions,
  (index) => 'bp_$index',
);

List<ArcBlueprintPhotoOccupancySample> samplesWithOwnedCount(int ownedCount) {
  return <ArcBlueprintPhotoOccupancySample>[
    for (final position in ArcBlueprintCanonicalGrid.topCapturePositions())
      sample(
        'top',
        position.globalRowIndex,
        position.columnIndex,
        position.canonicalIndex < ownedCount ? 0.92 : 0.08,
      ),
    for (final position in ArcBlueprintCanonicalGrid.bottomCapturePositions())
      sample(
        'bottom',
        position.globalRowIndex,
        position.columnIndex,
        position.canonicalIndex < ownedCount ? 0.92 : 0.08,
      ),
  ];
}

void main() {
  group('ArcBlueprintPhotoOccupancyEngine canonical grid', () {
    const engine = ArcBlueprintPhotoOccupancyEngine(columns: 10);

    test('classifies exactly 83 canonical physical positions', () {
      final result = engine.classify(
        orderedBlueprintIds: ids,
        samples: samplesWithOwnedCount(10),
      );

      expect(result.errors, isEmpty);
      expect(result.decisions, hasLength(83));
      expect(result.decisions.where((item) => item.owned), hasLength(10));
    });

    test('final row only contains canonical columns 0, 1 and 2', () {
      final result = engine.classify(
        orderedBlueprintIds: ids,
        samples: samplesWithOwnedCount(0),
      );

      final finalRow = result.decisions
          .where((decision) => decision.rowIndex == 8)
          .toList(growable: false);

      expect(finalRow, hasLength(3));
      expect(finalRow.map((item) => item.columnIndex), [0, 1, 2]);
    });

    test(
      'rejects non-existent final-row columns instead of creating slots',
      () {
        final invalid = <ArcBlueprintPhotoOccupancySample>[
          ...samplesWithOwnedCount(0),
          sample('bottom', 8, 3, 0.02),
        ];

        final result = engine.classify(
          orderedBlueprintIds: ids,
          samples: invalid,
        );

        expect(
          result.errors.join(' '),
          contains('non-existent Blueprint slot'),
        );
        expect(result.decisions, hasLength(83));
      },
    );

    test('physical count is independent of ownership recognition', () {
      for (final ownedCount in <int>[0, 10, 40]) {
        final result = engine.classify(
          orderedBlueprintIds: ids,
          samples: samplesWithOwnedCount(ownedCount),
        );

        expect(result.decisions, hasLength(83));
        expect(
          result.decisions.where((item) => item.owned),
          hasLength(ownedCount),
        );
      }
    });

    test('uncertain samples remain as canonical physical positions', () {
      final uncertain = samplesWithOwnedCount(0)
          .map((cell) {
            if (cell.rowIndex == 2 && cell.columnIndex == 4) {
              return sample(
                cell.captureId,
                cell.rowIndex,
                cell.columnIndex,
                0.5,
              );
            }
            return cell;
          })
          .toList(growable: false);

      final result = engine.classify(
        orderedBlueprintIds: ids,
        samples: uncertain,
      );

      expect(result.decisions, hasLength(83));
      final decision = result.decisions.firstWhere(
        (item) => item.rowIndex == 2 && item.columnIndex == 4,
      );
      expect(decision.state, ArcBlueprintPhotoCellState.uncertain);
      expect(decision.needsReview, isTrue);
    });

    test('blank-like samples do not invent owned Blueprints', () {
      final result = engine.classify(
        orderedBlueprintIds: ids,
        samples: samplesWithOwnedCount(0),
      );

      expect(result.decisions.where((item) => item.owned), isEmpty);
    });
  });
}
