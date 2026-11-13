import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_live_occupancy_stabilizer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_scan_segment_reconciler.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
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
      decisions.length == ArcBlueprintSeedData.blueprints.length;
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
        'First live scan is incomplete: expected 50 stable cells, received '
        '${top.stableCellCount}/${top.totalCellCount}.',
      );
    }
    if (!bottom.sectionStable || bottom.totalCellCount != 50) {
      errors.add(
        'Second live scan is incomplete: expected 50 stable cells, received '
        '${bottom.stableCellCount}/${bottom.totalCellCount}.',
      );
    }

    final ids = ArcBlueprintSeedData.blueprints
        .map((blueprint) => blueprint.id)
        .toList(growable: false);
    final requiredCount = ids.length;
    if (requiredCount == 0) {
      errors.add('Canonical Blueprint seed data is empty.');
    }

    if (errors.isNotEmpty) {
      return ArcBlueprintLiveScanDecisionResult(
        decisions: const <ArcBlueprintPhotoCellDecision>[],
        errors: List<String>.unmodifiable(errors),
      );
    }

    final reconciled = const ArcBlueprintScanSegmentReconciler().reconcile(
      first: top,
      second: bottom,
    );

    final byIndex = <int, ArcBlueprintLiveCellEstimate>{
      for (final cell in reconciled.cells)
        (cell.rowIndex * 10) + cell.columnIndex: cell,
    };

    final missingPositions = <int>[];
    for (var index = 0; index < requiredCount; index++) {
      if (!byIndex.containsKey(index)) {
        missingPositions.add(index);
      }
    }

    if (missingPositions.isNotEmpty) {
      errors.add(
        'Live scan returned ${requiredCount - missingPositions.length}/'
        '$requiredCount required Blueprint positions. Scroll farther and retry '
        'the second section so no rows are skipped.',
      );
    }

    if (errors.isNotEmpty) {
      return ArcBlueprintLiveScanDecisionResult(
        decisions: const <ArcBlueprintPhotoCellDecision>[],
        errors: List<String>.unmodifiable(errors),
      );
    }

    final decisions = <ArcBlueprintPhotoCellDecision>[];
    for (var index = 0; index < requiredCount; index++) {
      final cell = byIndex[index]!;
      decisions.add(
        ArcBlueprintPhotoCellDecision(
          blueprintId: ids[index],
          blueprintIndex: index,
          state: cell.state,
          confidence: cell.confidence.clamp(0.0, 1.0).toDouble(),
          sourceCaptureId: reconciled.alignment.usedFallback
              ? 'live-scanner-contiguous'
              : 'live-scanner-overlap',
          rowIndex: cell.rowIndex,
          columnIndex: cell.columnIndex,
        ),
      );
    }

    return ArcBlueprintLiveScanDecisionResult(
      decisions: List<ArcBlueprintPhotoCellDecision>.unmodifiable(decisions),
      errors: const <String>[],
    );
  }
}
