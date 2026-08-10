import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';

class ArcBlueprintPhotoImportSummary {
  const ArcBlueprintPhotoImportSummary({
    required this.ownedCount,
    required this.missingCount,
    required this.preservedDuplicateCount,
  });

  final int ownedCount;
  final int missingCount;
  final int preservedDuplicateCount;
}

class ArcBlueprintPhotoImportService {
  ArcBlueprintPhotoImportService({ArcBlueprintRepository? repository})
    : _repository = repository ?? ArcBlueprintRepository();

  final ArcBlueprintRepository _repository;

  Future<ArcBlueprintPhotoImportSummary> apply(
    Iterable<ArcBlueprintPhotoCellDecision> decisions,
  ) async {
    final existing = await _repository.loadMyBlueprintStates();
    final decisionList = decisions.toList(growable: false);
    final blockReason =
        ArcBlueprintPhotoImportService.automaticUpdateBlockReason(
          decisions: decisionList,
          existing: existing,
        );
    if (blockReason != null) {
      throw FormatException(blockReason);
    }

    final updates = ArcBlueprintPhotoImportService.buildUpdates(
      decisions: decisionList,
      existing: existing,
    );
    var ownedCount = 0;
    var missingCount = 0;
    var preservedDuplicateCount = 0;
    for (final update in updates) {
      if (update.owned) {
        ownedCount++;
      } else {
        missingCount++;
      }
      preservedDuplicateCount += update.dupesOwned;
    }

    await _repository.saveBlueprintStates(updates);
    return ArcBlueprintPhotoImportSummary(
      ownedCount: ownedCount,
      missingCount: missingCount,
      preservedDuplicateCount: preservedDuplicateCount,
    );
  }

  static String? automaticUpdateBlockReason({
    required Iterable<ArcBlueprintPhotoCellDecision> decisions,
    required Map<String, ArcBlueprintState> existing,
  }) {
    final decisionList = decisions.toList(growable: false);
    if (decisionList.isEmpty) return null;

    final existingOwned = existing.values.where((state) => state.owned).length;
    final ownedDecisions = decisionList
        .where((decision) => decision.state == ArcBlueprintPhotoCellState.owned)
        .toList(growable: false);
    final additions = ownedDecisions.where((decision) {
      return existing[decision.blueprintId]?.owned != true;
    }).length;

    if (decisionList.length >= 80 &&
        ownedDecisions.length >= decisionList.length - 1 &&
        existingOwned < (decisionList.length * 0.85).floor()) {
      return 'The scan tried to mark almost every Blueprint as owned. '
          'Nothing was changed. Re-align the four corners with the cell grid '
          'and retake the images.';
    }

    if (existingOwned > 0 && additions > 24) {
      return 'The scan attempted to add $additions new Blueprints at once. '
          'Nothing was changed because that result is outside the automatic '
          'update safety limit.';
    }

    return null;
  }

  static List<ArcBlueprintState> buildUpdates({
    required Iterable<ArcBlueprintPhotoCellDecision> decisions,
    required Map<String, ArcBlueprintState> existing,
  }) {
    return decisions
        .map((decision) {
          final current =
              existing[decision.blueprintId] ??
              ArcBlueprintState.empty(decision.blueprintId);
          final requestedOwned =
              current.owned ||
              decision.state == ArcBlueprintPhotoCellState.owned;
          return current.copyWith(
            owned: requestedOwned,
            dupesOwned: current.dupesOwned,
            priorityRank: current.priorityRank,
            updatedAt: DateTime.now(),
          );
        })
        .toList(growable: false);
  }
}
