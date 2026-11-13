import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

@immutable
class ArcBlueprintLiveCellEstimate {
  const ArcBlueprintLiveCellEstimate({
    required this.rowIndex,
    required this.columnIndex,
    required this.state,
    required this.occupancyScore,
    required this.confidence,
    required this.observationCount,
    required this.stable,
  });

  final int rowIndex;
  final int columnIndex;
  final ArcBlueprintPhotoCellState state;
  final double occupancyScore;
  final double confidence;
  final int observationCount;
  final bool stable;
}

@immutable
class ArcBlueprintLiveOccupancySnapshot {
  const ArcBlueprintLiveOccupancySnapshot({
    required this.cells,
    required this.frameCount,
  });

  const ArcBlueprintLiveOccupancySnapshot.empty()
    : cells = const <ArcBlueprintLiveCellEstimate>[],
      frameCount = 0;

  final List<ArcBlueprintLiveCellEstimate> cells;
  final int frameCount;

  int get totalCellCount => cells.length;
  int get stableCellCount => cells.where((cell) => cell.stable).length;
  int get ownedStableCount => cells
      .where(
        (cell) => cell.stable && cell.state == ArcBlueprintPhotoCellState.owned,
      )
      .length;
  int get missingStableCount => cells
      .where(
        (cell) =>
            cell.stable && cell.state == ArcBlueprintPhotoCellState.missing,
      )
      .length;
  int get uncertainCellCount => cells
      .where(
        (cell) =>
            !cell.stable || cell.state == ArcBlueprintPhotoCellState.uncertain,
      )
      .length;

  bool get sectionStable =>
      cells.isNotEmpty && stableCellCount == totalCellCount;
}

class ArcBlueprintLiveOccupancyStabilizer {
  ArcBlueprintLiveOccupancyStabilizer({
    this.windowSize = 5,
    this.minimumObservations = 3,
    this.minimumAgreement = 0.75,
    this.maximumScoreSpread = 0.30,
    this.ownedThreshold = 0.84,
    this.missingThreshold = 0.22,
  }) : assert(windowSize >= minimumObservations),
       assert(minimumObservations >= 2);

  final int windowSize;
  final int minimumObservations;
  final double minimumAgreement;
  final double maximumScoreSpread;
  final double ownedThreshold;
  final double missingThreshold;

  final Map<int, List<double>> _scoresByCell = <int, List<double>>{};
  int _frameCount = 0;

  void reset() {
    _scoresByCell.clear();
    _frameCount = 0;
  }

  ArcBlueprintLiveOccupancySnapshot addFrame(
    List<ArcBlueprintPhotoOccupancySample> samples,
  ) {
    _frameCount += 1;

    for (final sample in samples) {
      if (sample.rowIndex < 0 ||
          sample.columnIndex < 0 ||
          sample.columnIndex >= 10) {
        continue;
      }

      final key = (sample.rowIndex * 10) + sample.columnIndex;
      final history = _scoresByCell.putIfAbsent(key, () => <double>[]);
      history.add(sample.occupancyScore.clamp(0.0, 1.0).toDouble());
      if (history.length > windowSize) {
        history.removeAt(0);
      }
    }

    final cells =
        _scoresByCell.entries.map((entry) {
          final rowIndex = entry.key ~/ 10;
          final columnIndex = entry.key % 10;
          final values = entry.value;
          final average = values.reduce((a, b) => a + b) / values.length;
          final states = values.map(_stateForScore).toList(growable: false);

          var ownedVotes = 0;
          var missingVotes = 0;
          var uncertainVotes = 0;
          for (final state in states) {
            switch (state) {
              case ArcBlueprintPhotoCellState.owned:
                ownedVotes += 1;
                break;
              case ArcBlueprintPhotoCellState.missing:
                missingVotes += 1;
                break;
              case ArcBlueprintPhotoCellState.uncertain:
                uncertainVotes += 1;
                break;
            }
          }

          final leadingVotes = math.max(
            ownedVotes,
            math.max(missingVotes, uncertainVotes),
          );
          final leadingState = ownedVotes == leadingVotes
              ? ArcBlueprintPhotoCellState.owned
              : missingVotes == leadingVotes
              ? ArcBlueprintPhotoCellState.missing
              : ArcBlueprintPhotoCellState.uncertain;

          final minimum = values.reduce((a, b) => a < b ? a : b);
          final maximum = values.reduce((a, b) => a > b ? a : b);
          final spread = maximum - minimum;
          final agreement = leadingVotes / values.length;
          final stable =
              values.length >= minimumObservations &&
              leadingState != ArcBlueprintPhotoCellState.uncertain &&
              agreement >= minimumAgreement &&
              spread <= maximumScoreSpread;

          final confidence =
              ((agreement * 0.72) +
                      ((1 - (spread / maximumScoreSpread).clamp(0.0, 1.0)) *
                          0.28))
                  .clamp(0.0, 1.0)
                  .toDouble();

          return ArcBlueprintLiveCellEstimate(
            rowIndex: rowIndex,
            columnIndex: columnIndex,
            state: leadingState,
            occupancyScore: average.clamp(0.0, 1.0).toDouble(),
            confidence: confidence,
            observationCount: values.length,
            stable: stable,
          );
        }).toList()..sort((a, b) {
          final rowComparison = a.rowIndex.compareTo(b.rowIndex);
          return rowComparison != 0
              ? rowComparison
              : a.columnIndex.compareTo(b.columnIndex);
        });

    return ArcBlueprintLiveOccupancySnapshot(
      cells: List<ArcBlueprintLiveCellEstimate>.unmodifiable(cells),
      frameCount: _frameCount,
    );
  }

  ArcBlueprintPhotoCellState _stateForScore(double score) {
    if (score >= ownedThreshold) {
      return ArcBlueprintPhotoCellState.owned;
    }
    if (score <= missingThreshold) {
      return ArcBlueprintPhotoCellState.missing;
    }
    return ArcBlueprintPhotoCellState.uncertain;
  }
}
