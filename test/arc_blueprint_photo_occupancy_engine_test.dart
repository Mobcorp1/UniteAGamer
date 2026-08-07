import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
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

void main() {
  group('ArcBlueprintPhotoOccupancyEngine overlap merge', () {
    const engine = ArcBlueprintPhotoOccupancyEngine(columns: 10);

    test('creates exactly nine unique rows from two five-row captures', () {
      final ids = List<String>.generate(90, (index) => 'bp_$index');
      final top = <ArcBlueprintPhotoOccupancySample>[
        for (var row = 0; row < 5; row++)
          for (var column = 0; column < 10; column++)
            sample('top', row, column, row == 4 ? 0.85 : 0.90),
      ];
      final bottom = <ArcBlueprintPhotoOccupancySample>[
        for (var row = 0; row < 5; row++)
          for (var column = 0; column < 10; column++)
            sample('bottom', row, column, row == 0 ? 0.85 : 0.80),
      ];

      final result = engine.classify(
        orderedBlueprintIds: ids,
        topCapture: top,
        bottomCapture: bottom,
        bottomStartRow: 4,
        overlapRows: 1,
      );

      expect(result.errors, isEmpty);
      expect(result.overlapRowsRemoved, 1);
      expect(result.decisions, hasLength(90));
      expect(result.decisions.map((item) => item.rowIndex).toSet(), {
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
      });
    });

    test('bottom row one is authoritative over top row five', () {
      final ids = List<String>.generate(90, (index) => 'bp_$index');
      final top = <ArcBlueprintPhotoOccupancySample>[
        for (var row = 0; row < 5; row++)
          for (var column = 0; column < 10; column++)
            sample('top', row, column, row == 4 ? 0.74 : 0.90),
      ];
      final bottom = <ArcBlueprintPhotoOccupancySample>[
        for (var row = 0; row < 5; row++)
          for (var column = 0; column < 10; column++)
            sample('bottom', row, column, row == 0 ? 0.76 : 0.80),
      ];

      final result = engine.classify(
        orderedBlueprintIds: ids,
        topCapture: top,
        bottomCapture: bottom,
        bottomStartRow: 4,
        overlapRows: 1,
      );

      final overlapDecision = result.decisions[40];
      expect(result.errors, isEmpty);
      expect(overlapDecision.rowIndex, 4);
      expect(overlapDecision.sourceCaptureId, 'bottom');
      expect(overlapDecision.state, ArcBlueprintPhotoCellState.owned);
    });

    test('rejects a bottom image whose first row does not match overlap', () {
      final ids = List<String>.generate(90, (index) => 'bp_$index');
      final top = <ArcBlueprintPhotoOccupancySample>[
        for (var row = 0; row < 5; row++)
          for (var column = 0; column < 10; column++)
            sample('top', row, column, 0.90),
      ];
      final bottom = <ArcBlueprintPhotoOccupancySample>[
        for (var row = 0; row < 5; row++)
          for (var column = 0; column < 10; column++)
            sample('bottom', row, column, row == 0 ? 0.05 : 0.80),
      ];

      final result = engine.classify(
        orderedBlueprintIds: ids,
        topCapture: top,
        bottomCapture: bottom,
        bottomStartRow: 4,
        overlapRows: 1,
      );

      expect(result.errors.join(' '), contains('do not overlap correctly'));
      expect(result.needsReview, isTrue);
    });

    test('still classifies owned, missing and uncertain cells', () {
      const smallEngine = ArcBlueprintPhotoOccupancyEngine(columns: 3);
      final result = smallEngine.classify(
        orderedBlueprintIds: const ['a', 'b', 'c', 'd', 'e', 'f'],
        topCapture: [
          sample('top', 0, 0, 0.95),
          sample('top', 0, 1, 0.05),
          sample('top', 0, 2, 0.50),
        ],
        bottomCapture: [
          sample('bottom', 0, 0, 0.90),
          sample('bottom', 0, 1, 0.10),
          sample('bottom', 0, 2, 0.80),
        ],
        bottomStartRow: 1,
        overlapRows: 0,
      );

      expect(result.decisions[0].state, ArcBlueprintPhotoCellState.owned);
      expect(result.decisions[1].state, ArcBlueprintPhotoCellState.missing);
      expect(result.decisions[2].state, ArcBlueprintPhotoCellState.uncertain);
      expect(result.decisions[3].sourceCaptureId, 'bottom');
    });
  });
}
