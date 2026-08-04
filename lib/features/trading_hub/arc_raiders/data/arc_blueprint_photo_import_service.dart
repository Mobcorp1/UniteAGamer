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
    final unresolved = decisions
        .where((decision) => decision.needsReview)
        .toList();
    if (unresolved.isNotEmpty) {
      throw StateError(
        'Review every uncertain Blueprint slot before importing.',
      );
    }

    final existing = await _repository.loadMyBlueprintStates();
    final updates = ArcBlueprintPhotoImportService.buildUpdates(
      decisions: decisions,
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
