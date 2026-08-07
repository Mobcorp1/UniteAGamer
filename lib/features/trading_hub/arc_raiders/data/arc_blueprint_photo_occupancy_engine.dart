import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

class ArcBlueprintPhotoOccupancySample {
  const ArcBlueprintPhotoOccupancySample({
    required this.captureId,
    required this.rowIndex,
    required this.columnIndex,
    required this.occupancyScore,
  });

  final String captureId;
  final int rowIndex;
  final int columnIndex;
  final double occupancyScore;
}

class ArcBlueprintPhotoOccupancyResult {
  const ArcBlueprintPhotoOccupancyResult({
    required this.decisions,
    required this.overlapRowsRemoved,
    required this.errors,
  });

  final List<ArcBlueprintPhotoCellDecision> decisions;
  final int overlapRowsRemoved;
  final List<String> errors;

  bool get needsReview =>
      errors.isNotEmpty || decisions.any((item) => item.needsReview);

  ArcBlueprintPhotoImportSession applyToSession(
    ArcBlueprintPhotoImportSession session,
  ) {
    return session.copyWith(
      status: needsReview
          ? ArcBlueprintPhotoImportStatus.needsUserReview
          : ArcBlueprintPhotoImportStatus.confirmed,
      decisions: decisions,
      confirmedByUser: false,
      writePreviewOnly: true,
      errorMessage: errors.join(' '),
      updatedAt: DateTime.now(),
    );
  }
}

class ArcBlueprintPhotoOccupancyEngine {
  const ArcBlueprintPhotoOccupancyEngine({
    this.columns = 7,
    this.ownedThreshold = 0.72,
    this.missingThreshold = 0.28,
  });

  final int columns;
  final double ownedThreshold;
  final double missingThreshold;

  ArcBlueprintPhotoOccupancyResult classify({
    required List<String> orderedBlueprintIds,
    required List<ArcBlueprintPhotoOccupancySample> topCapture,
    required List<ArcBlueprintPhotoOccupancySample> bottomCapture,
    required int bottomStartRow,
    int overlapRows = 1,
  }) {
    final errors = <String>[];
    if (orderedBlueprintIds.isEmpty) {
      return const ArcBlueprintPhotoOccupancyResult(
        decisions: <ArcBlueprintPhotoCellDecision>[],
        overlapRowsRemoved: 0,
        errors: <String>['Blueprint order is empty.'],
      );
    }
    if (columns <= 0) {
      return const ArcBlueprintPhotoOccupancyResult(
        decisions: <ArcBlueprintPhotoCellDecision>[],
        overlapRowsRemoved: 0,
        errors: <String>['Grid column count must be greater than zero.'],
      );
    }

    final samplesByIndex = <int, ArcBlueprintPhotoOccupancySample>{};
    for (final sample in topCapture) {
      final index = (sample.rowIndex * columns) + sample.columnIndex;
      if (index >= 0 && index < orderedBlueprintIds.length) {
        samplesByIndex[index] = sample;
      }
    }

    // The top capture's final row and the bottom capture's first row are the
    // same in-game row. The bottom copy is authoritative. This creates four
    // unique top rows plus all five bottom rows: nine unique rows in total.
    final comparedOverlapRows = <int>{};
    final mismatchCellsByRow = <int, int>{};
    final comparedCellsByRow = <int, int>{};

    for (final sample in bottomCapture) {
      final globalRow = bottomStartRow + sample.rowIndex;
      final index = (globalRow * columns) + sample.columnIndex;
      if (index < 0 || index >= orderedBlueprintIds.length) continue;

      final isOverlap = sample.rowIndex >= 0 && sample.rowIndex < overlapRows;
      final existing = samplesByIndex[index];

      if (isOverlap) {
        comparedOverlapRows.add(globalRow);
        if (existing == null) {
          errors.add(
            'The shared overlap row is incomplete at column '
            '${sample.columnIndex + 1}.',
          );
        } else {
          comparedCellsByRow.update(
            globalRow,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
          if ((existing.occupancyScore - sample.occupancyScore).abs() > 0.35) {
            mismatchCellsByRow.update(
              globalRow,
              (value) => value + 1,
              ifAbsent: () => 1,
            );
          }
        }
      }

      // Always replace the overlap with the bottom capture. Top row 5 is
      // deliberately discarded; bottom row 1 becomes global row 5.
      samplesByIndex[index] = ArcBlueprintPhotoOccupancySample(
        captureId: sample.captureId,
        rowIndex: globalRow,
        columnIndex: sample.columnIndex,
        occupancyScore: sample.occupancyScore,
      );
    }

    for (final row in comparedOverlapRows) {
      final compared = comparedCellsByRow[row] ?? 0;
      final mismatches = mismatchCellsByRow[row] ?? 0;
      if (compared < columns) {
        errors.add(
          'The two photos do not contain a complete shared overlap row.',
        );
        continue;
      }
      if (mismatches > (columns / 3).floor()) {
        errors.add(
          'The two photos do not overlap correctly. Retake the bottom image '
          'with its first row matching the top image final row.',
        );
      }
    }

    final removed = comparedOverlapRows.length;

    final decisions = <ArcBlueprintPhotoCellDecision>[];
    for (var index = 0; index < orderedBlueprintIds.length; index++) {
      final sample = samplesByIndex[index];
      if (sample == null) {
        decisions.add(
          ArcBlueprintPhotoCellDecision(
            blueprintId: orderedBlueprintIds[index],
            blueprintIndex: index,
            state: ArcBlueprintPhotoCellState.uncertain,
            confidence: 0,
            sourceCaptureId: '',
            rowIndex: index ~/ columns,
            columnIndex: index % columns,
          ),
        );
        continue;
      }

      final score = sample.occupancyScore.clamp(0.0, 1.0).toDouble();
      final state = score >= ownedThreshold
          ? ArcBlueprintPhotoCellState.owned
          : score <= missingThreshold
          ? ArcBlueprintPhotoCellState.missing
          : ArcBlueprintPhotoCellState.uncertain;
      final confidence = switch (state) {
        ArcBlueprintPhotoCellState.owned => score,
        ArcBlueprintPhotoCellState.missing => 1 - score,
        ArcBlueprintPhotoCellState.uncertain => 1 - ((score - 0.5).abs() * 2),
      };

      decisions.add(
        ArcBlueprintPhotoCellDecision(
          blueprintId: orderedBlueprintIds[index],
          blueprintIndex: index,
          state: state,
          confidence: confidence.clamp(0.0, 1.0).toDouble(),
          sourceCaptureId: sample.captureId,
          rowIndex: sample.rowIndex,
          columnIndex: sample.columnIndex,
        ),
      );
    }

    return ArcBlueprintPhotoOccupancyResult(
      decisions: decisions,
      overlapRowsRemoved: removed,
      errors: errors,
    );
  }
}
