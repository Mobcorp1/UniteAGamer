import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

void main() {
  group('ArcBlueprintPhotoOccupancyEngine', () {
    const engine = ArcBlueprintPhotoOccupancyEngine(columns: 3);

    test(
      'maps fixed grid positions to owned, missing, and uncertain states',
      () {
        final result = engine.classify(
          orderedBlueprintIds: const ['a', 'b', 'c', 'd', 'e', 'f'],
          topCapture: const [
            ArcBlueprintPhotoOccupancySample(
              captureId: 'top',
              rowIndex: 0,
              columnIndex: 0,
              occupancyScore: 0.95,
            ),
            ArcBlueprintPhotoOccupancySample(
              captureId: 'top',
              rowIndex: 0,
              columnIndex: 1,
              occupancyScore: 0.05,
            ),
            ArcBlueprintPhotoOccupancySample(
              captureId: 'top',
              rowIndex: 0,
              columnIndex: 2,
              occupancyScore: 0.50,
            ),
          ],
          bottomCapture: const [
            ArcBlueprintPhotoOccupancySample(
              captureId: 'bottom',
              rowIndex: 0,
              columnIndex: 0,
              occupancyScore: 0.90,
            ),
            ArcBlueprintPhotoOccupancySample(
              captureId: 'bottom',
              rowIndex: 0,
              columnIndex: 1,
              occupancyScore: 0.10,
            ),
            ArcBlueprintPhotoOccupancySample(
              captureId: 'bottom',
              rowIndex: 0,
              columnIndex: 2,
              occupancyScore: 0.80,
            ),
          ],
          bottomStartRow: 1,
          overlapRows: 0,
        );

        expect(result.decisions.map((item) => item.blueprintId), [
          'a',
          'b',
          'c',
          'd',
          'e',
          'f',
        ]);
        expect(result.decisions[0].state, ArcBlueprintPhotoCellState.owned);
        expect(result.decisions[1].state, ArcBlueprintPhotoCellState.missing);
        expect(result.decisions[2].state, ArcBlueprintPhotoCellState.uncertain);
        expect(result.decisions[3].state, ArcBlueprintPhotoCellState.owned);
      },
    );

    test('removes one overlapping row and reports disagreement', () {
      final result = engine.classify(
        orderedBlueprintIds: const ['a', 'b', 'c', 'd', 'e', 'f'],
        topCapture: const [
          ArcBlueprintPhotoOccupancySample(
            captureId: 'top',
            rowIndex: 0,
            columnIndex: 0,
            occupancyScore: 0.9,
          ),
          ArcBlueprintPhotoOccupancySample(
            captureId: 'top',
            rowIndex: 1,
            columnIndex: 0,
            occupancyScore: 0.9,
          ),
        ],
        bottomCapture: const [
          ArcBlueprintPhotoOccupancySample(
            captureId: 'bottom',
            rowIndex: 0,
            columnIndex: 0,
            occupancyScore: 0.1,
          ),
        ],
        bottomStartRow: 1,
      );

      expect(result.overlapRowsRemoved, 1);
      expect(result.errors, isNotEmpty);
      expect(result.needsReview, isTrue);
    });

    test(
      'does not infer duplicates and requires user confirmation before write',
      () {
        final result = engine.classify(
          orderedBlueprintIds: const ['a'],
          topCapture: const [
            ArcBlueprintPhotoOccupancySample(
              captureId: 'top',
              rowIndex: 0,
              columnIndex: 0,
              occupancyScore: 0.95,
            ),
          ],
          bottomCapture: const [],
          bottomStartRow: 1,
          overlapRows: 0,
        );
        final session = result.applyToSession(
          const ArcBlueprintPhotoImportSession(
            id: 'session',
            uid: 'user',
            status: ArcBlueprintPhotoImportStatus.uploaded,
            captures: [
              ArcBlueprintPhotoCapture(
                id: 'top',
                imagePath: 'top.png',
                sequenceIndex: 0,
              ),
              ArcBlueprintPhotoCapture(
                id: 'bottom',
                imagePath: 'bottom.png',
                sequenceIndex: 1,
              ),
            ],
          ),
        );

        expect(session.decisions.single.owned, isTrue);
        expect(session.canWriteBlueprintState, isFalse);
        expect(session.writeBlockReason, contains('Confirm'));
      },
    );
  });
}
