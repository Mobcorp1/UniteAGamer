import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_canonical_grid.dart';

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
    required this.errors,
  });

  final List<ArcBlueprintPhotoCellDecision> decisions;
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
    this.columns = ArcBlueprintCanonicalGrid.columns,
    this.ownedThreshold = 0.72,
    this.missingThreshold = 0.28,
  });

  final int columns;
  final double ownedThreshold;
  final double missingThreshold;

  ArcBlueprintPhotoOccupancyResult classify({
    required List<String> orderedBlueprintIds,
    required List<ArcBlueprintPhotoOccupancySample> samples,
  }) {
    final errors = <String>[];
    if (orderedBlueprintIds.isEmpty) {
      return const ArcBlueprintPhotoOccupancyResult(
        decisions: <ArcBlueprintPhotoCellDecision>[],
        errors: <String>['Blueprint order is empty.'],
      );
    }
    if (columns <= 0) {
      return const ArcBlueprintPhotoOccupancyResult(
        decisions: <ArcBlueprintPhotoCellDecision>[],
        errors: <String>['Grid column count must be greater than zero.'],
      );
    }

    final samplesByIndex = <int, ArcBlueprintPhotoOccupancySample>{};
    for (final sample in samples) {
      final index = _indexForSample(sample, orderedBlueprintIds.length);
      if (index == null) {
        errors.add(
          'The scanner produced a non-existent Blueprint slot at row ${sample.rowIndex + 1}, column ${sample.columnIndex + 1}.',
        );
        continue;
      }
      if (samplesByIndex.containsKey(index)) {
        errors.add(
          'The scanner produced a duplicate Blueprint position at row ${sample.rowIndex + 1}, column ${sample.columnIndex + 1}.',
        );
        continue;
      }
      samplesByIndex[index] = sample;
    }

    final decisions = <ArcBlueprintPhotoCellDecision>[];
    for (var index = 0; index < orderedBlueprintIds.length; index++) {
      final sample = samplesByIndex[index];
      final position = _positionForIndex(index);
      if (sample == null) {
        decisions.add(
          ArcBlueprintPhotoCellDecision(
            blueprintId: orderedBlueprintIds[index],
            blueprintIndex: index,
            state: ArcBlueprintPhotoCellState.uncertain,
            confidence: 0,
            sourceCaptureId: '',
            rowIndex: position.rowIndex,
            columnIndex: position.columnIndex,
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
      errors: errors,
    );
  }

  int? _indexForSample(
    ArcBlueprintPhotoOccupancySample sample,
    int blueprintCount,
  ) {
    if (_usesCanonicalGrid(blueprintCount)) {
      return ArcBlueprintCanonicalGrid.indexForGlobalCell(
        rowIndex: sample.rowIndex,
        columnIndex: sample.columnIndex,
      );
    }

    final index = (sample.rowIndex * columns) + sample.columnIndex;
    return index >= 0 && index < blueprintCount ? index : null;
  }

  ({int rowIndex, int columnIndex}) _positionForIndex(int index) {
    if (columns == ArcBlueprintCanonicalGrid.columns &&
        index < ArcBlueprintCanonicalGrid.totalPositions) {
      final position = ArcBlueprintCanonicalGrid.positionForIndex(index);
      if (position != null) {
        return (
          rowIndex: position.globalRowIndex,
          columnIndex: position.columnIndex,
        );
      }
    }

    return (rowIndex: index ~/ columns, columnIndex: index % columns);
  }

  bool _usesCanonicalGrid(int blueprintCount) {
    return columns == ArcBlueprintCanonicalGrid.columns &&
        blueprintCount == ArcBlueprintCanonicalGrid.totalPositions;
  }
}
