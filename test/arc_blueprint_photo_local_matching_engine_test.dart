import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_local_matching_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

void main() {
  group('ArcBlueprintPhotoLocalMatchingEngine', () {
    const engine = ArcBlueprintPhotoLocalMatchingEngine();

    test('deduplicates overlapping rows while preserving blank cells', () {
      final result = engine.stitchAndScore([
        [
          _row('capture-1', 0, ['a', '']),
          _row('capture-1', 1, ['b', 'c'], signature: 'overlap-b-c'),
        ],
        [
          _row('capture-2', 0, ['b', 'c'], signature: 'overlap-b-c'),
          _row('capture-2', 1, ['d', '']),
        ],
      ]);

      expect(result.removedOverlapRows, 1);
      expect(result.rows, hasLength(3));
      expect(result.rows.first.cells.last.blank, isTrue);
      expect(
        result.candidates.map((candidate) => candidate.blueprintId),
        containsAll(['a', 'b', 'c', 'd']),
      );
    });

    test('keeps uncertain cells in review-only session state', () {
      final result = engine.stitchAndScore([
        [
          _row('capture-1', 0, ['anvil-splitter'], confidence: 0.7),
        ],
      ]);

      final session = result.applyToSession(
        const ArcBlueprintPhotoImportSession(
          id: 'session-1',
          uid: 'user-1',
          status: ArcBlueprintPhotoImportStatus.uploaded,
        ),
      );

      expect(result.needsUserReview, isTrue);
      expect(session.status, ArcBlueprintPhotoImportStatus.needsUserReview);
      expect(session.canWriteBlueprintState, isFalse);
      expect(session.writePreviewOnly, isTrue);
    });

    test('flags overlap conflicts for manual review', () {
      final result = engine.stitchAndScore([
        [
          _row('capture-1', 0, ['a'], signature: 'overlap'),
        ],
        [
          _row('capture-2', 0, ['b'], signature: 'overlap'),
        ],
      ]);

      expect(result.removedOverlapRows, 1);
      expect(result.conflictMessages, isNotEmpty);
      expect(result.needsUserReview, isTrue);
    });
  });
}

ArcBlueprintPhotoDetectedRow _row(
  String captureId,
  int rowIndex,
  List<String> blueprints, {
  String signature = '',
  double confidence = 0.96,
}) {
  return ArcBlueprintPhotoDetectedRow(
    captureId: captureId,
    rowIndex: rowIndex,
    overlapSignature: signature,
    cells: [
      for (var column = 0; column < blueprints.length; column++)
        ArcBlueprintPhotoDetectedCell(
          rowIndex: rowIndex,
          columnIndex: column,
          blueprintId: blueprints[column],
          label: blueprints[column],
          confidence: blueprints[column].isEmpty ? 0 : confidence,
          blank: blueprints[column].isEmpty,
          perceptualHash: 'hash-${blueprints[column]}',
          sourceCaptureId: captureId,
        ),
    ],
  );
}
