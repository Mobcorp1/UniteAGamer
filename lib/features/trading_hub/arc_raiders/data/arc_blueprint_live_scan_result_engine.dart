import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_occupancy_stabilizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_canonical_grid.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

@immutable
class ArcBlueprintLiveScanDecisionResult {
  const ArcBlueprintLiveScanDecisionResult({
    required this.decisions,
    required this.errors,
  });
  final List<ArcBlueprintPhotoCellDecision> decisions;
  final List<String> errors;
  bool get succeeded =>
      errors.isEmpty &&
      decisions.length == ArcBlueprintCanonicalGrid.totalPositions;
}

class ArcBlueprintLiveScanResultEngine {
  const ArcBlueprintLiveScanResultEngine();

  ArcBlueprintLiveScanDecisionResult build({
    required ArcBlueprintLiveOccupancySnapshot top,
    required ArcBlueprintLiveOccupancySnapshot bottom,
  }) {
    final errors = <String>[];
    if (!top.sectionStable || top.totalCellCount != 50) {
      errors.add(
        'Top live scan is incomplete: expected 50 stable cells, received ${top.stableCellCount}/${top.totalCellCount}.',
      );
    }
    if (!bottom.sectionStable || bottom.totalCellCount != 33) {
      errors.add(
        'Bottom live scan is incomplete: expected 33 stable cells, received ${bottom.stableCellCount}/${bottom.totalCellCount}.',
      );
    }
    final byIndex = <int, ArcBlueprintLiveCellEstimate>{};
    for (final cell in <ArcBlueprintLiveCellEstimate>[
      ...top.cells,
      ...bottom.cells,
    ]) {
      final index = (cell.rowIndex * 10) + cell.columnIndex;
      if (index < 0 || index >= ArcBlueprintCanonicalGrid.totalPositions) {
        errors.add(
          'Invalid live grid position R${cell.rowIndex + 1}C${cell.columnIndex + 1}.',
        );
      } else if (byIndex.containsKey(index)) {
        errors.add(
          'Duplicate live grid position R${cell.rowIndex + 1}C${cell.columnIndex + 1}.',
        );
      } else {
        byIndex[index] = cell;
      }
    }
    if (byIndex.length != ArcBlueprintCanonicalGrid.totalPositions) {
      errors.add(
        'Live scan returned ${byIndex.length} unique positions; ${ArcBlueprintCanonicalGrid.totalPositions} are required.',
      );
    }
    final ids = ArcBlueprintSeedData.blueprints
        .map((b) => b.id)
        .toList(growable: false);
    if (ids.length < ArcBlueprintCanonicalGrid.totalPositions) {
      errors.add(
        'Canonical Blueprint seed data contains only ${ids.length} positions.',
      );
    }
    if (errors.isNotEmpty) {
      return ArcBlueprintLiveScanDecisionResult(
        decisions: const [],
        errors: List.unmodifiable(errors),
      );
    }
    final decisions = <ArcBlueprintPhotoCellDecision>[];
    for (
      var index = 0;
      index < ArcBlueprintCanonicalGrid.totalPositions;
      index++
    ) {
      final cell = byIndex[index]!;
      decisions.add(
        ArcBlueprintPhotoCellDecision(
          blueprintId: ids[index],
          blueprintIndex: index,
          state: cell.state,
          confidence: cell.confidence.clamp(0.0, 1.0).toDouble(),
          sourceCaptureId: 'live-scanner',
          rowIndex: cell.rowIndex,
          columnIndex: cell.columnIndex,
        ),
      );
    }
    return ArcBlueprintLiveScanDecisionResult(
      decisions: List.unmodifiable(decisions),
      errors: const [],
    );
  }
}
