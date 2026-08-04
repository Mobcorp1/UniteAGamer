import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

void main() {
  test('guides exactly two captures and never models duplicate counts', () {
    const session = ArcBlueprintPhotoImportSession(
      id: 'import',
      uid: 'user',
      status: ArcBlueprintPhotoImportStatus.draft,
    );

    expect(session.requiredCaptureCount, 2);
    expect(session.nextCaptureStep, ArcBlueprintPhotoCaptureStep.captureTop);
    expect(session.writeBlockReason, contains('top section'));
  });

  test(
    'confirmed reviewed session can update ownership only after explicit confirmation',
    () {
      const decision = ArcBlueprintPhotoCellDecision(
        blueprintId: 'anvil',
        blueprintIndex: 0,
        state: ArcBlueprintPhotoCellState.owned,
        confidence: 0.97,
        sourceCaptureId: 'top',
        rowIndex: 0,
        columnIndex: 0,
      );
      const session = ArcBlueprintPhotoImportSession(
        id: 'import',
        uid: 'user',
        status: ArcBlueprintPhotoImportStatus.confirmed,
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
        decisions: [decision],
        confirmedByUser: true,
        writePreviewOnly: false,
      );

      expect(session.canWriteBlueprintState, isTrue);
      final restored = ArcBlueprintPhotoImportSession.fromMap(session.toMap());
      expect(restored.decisions.single.blueprintId, 'anvil');
      expect(restored.canWriteBlueprintState, isTrue);
    },
  );

  test('uncertain slot remains blocked until manually confirmed', () {
    const uncertain = ArcBlueprintPhotoCellDecision(
      blueprintId: 'anvil',
      blueprintIndex: 0,
      state: ArcBlueprintPhotoCellState.uncertain,
      confidence: 0.5,
      sourceCaptureId: 'top',
      rowIndex: 0,
      columnIndex: 0,
    );
    expect(uncertain.needsReview, isTrue);
    expect(
      uncertain
          .copyWith(
            state: ArcBlueprintPhotoCellState.missing,
            manuallyConfirmed: true,
          )
          .needsReview,
      isFalse,
    );
  });
}
