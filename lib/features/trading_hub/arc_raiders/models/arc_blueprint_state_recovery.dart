import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';

class ArcBlueprintStateRecoverySource {
  const ArcBlueprintStateRecoverySource({
    required this.path,
    required this.states,
  });

  final String path;
  final Map<String, ArcBlueprintState> states;

  bool get hasStates => states.isNotEmpty;
}

class ArcBlueprintStateRecoveryPreview {
  const ArcBlueprintStateRecoveryPreview({
    required this.canonicalPath,
    required this.currentStates,
    required this.legacySources,
    required this.mergedStates,
  });

  final String canonicalPath;
  final Map<String, ArcBlueprintState> currentStates;
  final List<ArcBlueprintStateRecoverySource> legacySources;
  final Map<String, ArcBlueprintState> mergedStates;

  List<String> get legacyPathsWithData => legacySources
      .where((source) => source.hasStates)
      .map((source) => source.path)
      .toList(growable: false);

  int get recoveredStateCount => mergedStates.length - currentStates.length;

  bool get requiresMigration =>
      legacyPathsWithData.isNotEmpty &&
      mergedStates.length > currentStates.length;
}

class ArcBlueprintStateRecovery {
  const ArcBlueprintStateRecovery._();

  static Map<String, ArcBlueprintState> merge({
    required Map<String, ArcBlueprintState> currentStates,
    required Iterable<ArcBlueprintStateRecoverySource> legacySources,
  }) {
    final merged = Map<String, ArcBlueprintState>.from(currentStates);
    for (final source in legacySources) {
      for (final entry in source.states.entries) {
        final blueprintId = entry.key.trim().isNotEmpty
            ? entry.key.trim()
            : entry.value.blueprintId.trim();
        if (blueprintId.isEmpty) continue;

        final legacy = entry.value.copyWith(blueprintId: blueprintId);
        final current = merged[blueprintId];
        merged[blueprintId] = current == null
            ? legacy
            : _mergeState(current: current, legacy: legacy);
      }
    }
    return merged;
  }

  static ArcBlueprintState _mergeState({
    required ArcBlueprintState current,
    required ArcBlueprintState legacy,
  }) {
    final currentUpdatedAt = current.updatedAt;
    final legacyUpdatedAt = legacy.updatedAt;
    final newestUpdatedAt = switch ((currentUpdatedAt, legacyUpdatedAt)) {
      (final DateTime currentTime, final DateTime legacyTime) =>
        currentTime.isAfter(legacyTime) ? currentTime : legacyTime,
      (final DateTime currentTime, null) => currentTime,
      (null, final DateTime legacyTime) => legacyTime,
      _ => null,
    };

    final currentPriority = current.priorityRank;
    final legacyPriority = legacy.priorityRank;
    final priorityRank = currentPriority > 0
        ? currentPriority
        : legacyPriority > 0
        ? legacyPriority
        : 0;

    return ArcBlueprintState(
      blueprintId: current.blueprintId.trim().isNotEmpty
          ? current.blueprintId.trim()
          : legacy.blueprintId.trim(),
      owned: current.owned || legacy.owned,
      dupesOwned: current.dupesOwned > legacy.dupesOwned
          ? current.dupesOwned
          : legacy.dupesOwned,
      priorityRank: priorityRank,
      updatedAt: newestUpdatedAt,
    );
  }
}
