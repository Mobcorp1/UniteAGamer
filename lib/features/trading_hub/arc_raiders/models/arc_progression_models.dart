import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';

enum ArcProgressionStatus { locked, active, ready, completed, archived }

enum ArcProgressionObjectiveSource { tracker, manual }

@immutable
class ArcProgressionObjective {
  const ArcProgressionObjective({
    required this.id,
    required this.label,
    required this.requiredCount,
    required this.currentCount,
    this.source = ArcProgressionObjectiveSource.tracker,
    this.sourceHint,
  });

  final String id;
  final String label;
  final int requiredCount;
  final int currentCount;
  final ArcProgressionObjectiveSource source;
  final String? sourceHint;

  bool get complete => currentCount >= requiredCount;
  int get missingCount =>
      (requiredCount - currentCount).clamp(0, requiredCount);
  int get safeCurrentCount => currentCount.clamp(0, requiredCount);

  String get progressLabel => '$safeCurrentCount/$requiredCount $label';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'requiredCount': requiredCount,
      'currentCount': currentCount,
      'source': source.name,
      if (sourceHint != null) 'sourceHint': sourceHint,
    };
  }

  factory ArcProgressionObjective.fromMap(Map<String, dynamic> map) {
    return ArcProgressionObjective(
      id: _string(map['id']),
      label: _string(map['label']),
      requiredCount: _int(map['requiredCount']),
      currentCount: _int(map['currentCount']),
      source: ArcProgressionObjectiveSource.values.firstWhere(
        (source) => source.name == map['source'],
        orElse: () => ArcProgressionObjectiveSource.tracker,
      ),
      sourceHint: _nullableString(map['sourceHint']),
    );
  }
}

@immutable
class ArcQuestProgressionDefinition {
  const ArcQuestProgressionDefinition({
    required this.questId,
    required this.trader,
    required this.questName,
    required this.order,
    required this.prerequisiteQuestIds,
    required this.objectives,
  });

  final String questId;
  final String trader;
  final String questName;
  final int order;
  final List<String> prerequisiteQuestIds;
  final List<ArcProgressionObjective> objectives;

  String get questLabel => '$trader - $questName';
}

@immutable
class ArcQuestProgressionRecord {
  const ArcQuestProgressionRecord({
    required this.questId,
    required this.seasonId,
    required this.status,
    this.objectiveProgress = const <String, int>{},
    this.completedAt,
    this.rewardsGrantedAt,
    this.archivedAt,
    this.updatedAt,
  });

  final String questId;
  final String seasonId;
  final ArcProgressionStatus status;
  final Map<String, int> objectiveProgress;
  final DateTime? completedAt;
  final DateTime? rewardsGrantedAt;
  final DateTime? archivedAt;
  final DateTime? updatedAt;

  bool get completed => status == ArcProgressionStatus.completed;

  ArcQuestProgressionRecord copyWith({
    String? seasonId,
    ArcProgressionStatus? status,
    Map<String, int>? objectiveProgress,
    DateTime? completedAt,
    DateTime? rewardsGrantedAt,
    DateTime? archivedAt,
    DateTime? updatedAt,
  }) {
    return ArcQuestProgressionRecord(
      questId: questId,
      seasonId: seasonId ?? this.seasonId,
      status: status ?? this.status,
      objectiveProgress: objectiveProgress ?? this.objectiveProgress,
      completedAt: completedAt ?? this.completedAt,
      rewardsGrantedAt: rewardsGrantedAt ?? this.rewardsGrantedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questId': questId,
      'seasonId': seasonId,
      'status': status.name,
      'objectiveProgress': objectiveProgress,
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (rewardsGrantedAt != null)
        'rewardsGrantedAt': rewardsGrantedAt!.toIso8601String(),
      if (archivedAt != null) 'archivedAt': archivedAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory ArcQuestProgressionRecord.fromMap(
    String questId,
    Map<String, dynamic> map,
  ) {
    final rawProgress = map['objectiveProgress'];
    return ArcQuestProgressionRecord(
      questId: _nullableString(map['questId']) ?? questId,
      seasonId: _string(map['seasonId'], fallback: 'season-1'),
      status: ArcProgressionStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => ArcProgressionStatus.active,
      ),
      objectiveProgress: rawProgress is Map
          ? rawProgress.map(
              (key, value) => MapEntry(key.toString(), _int(value)),
            )
          : const <String, int>{},
      completedAt: _date(map['completedAt']),
      rewardsGrantedAt: _date(map['rewardsGrantedAt']),
      archivedAt: _date(map['archivedAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }
}

@immutable
class ArcQuestProgressionEntry {
  const ArcQuestProgressionEntry({
    required this.definition,
    required this.status,
    required this.objectives,
    this.record,
  });

  final ArcQuestProgressionDefinition definition;
  final ArcProgressionStatus status;
  final List<ArcProgressionObjective> objectives;
  final ArcQuestProgressionRecord? record;

  String get questId => definition.questId;
  String get questName => definition.questName;
  String get trader => definition.trader;
  String get questLabel => definition.questLabel;
  bool get completed => status == ArcProgressionStatus.completed;
  bool get locked => status == ArcProgressionStatus.locked;
  bool get readyToComplete => status == ArcProgressionStatus.ready;
  int get totalObjectives => objectives.length;
  int get completedObjectives =>
      objectives.where((objective) => objective.complete).length;
  int get requiredCount => objectives.fold<int>(
    0,
    (total, objective) => total + objective.requiredCount,
  );
  int get collectedCount => objectives.fold<int>(
    0,
    (total, objective) => total + objective.safeCurrentCount,
  );
  int get missingCount => objectives.fold<int>(
    0,
    (total, objective) => total + objective.missingCount,
  );
  int get completionPercent => requiredCount == 0
      ? 100
      : ((collectedCount / requiredCount) * 100).round().clamp(0, 100);
  String get progressLabel => '$completedObjectives/$totalObjectives items';
}

@immutable
class ArcQuestProgressionSnapshot {
  const ArcQuestProgressionSnapshot({
    required this.seasonId,
    required this.entries,
    required this.completedQuestIds,
    required this.archivedQuestIds,
    required this.trackingKnown,
  });

  static const empty = ArcQuestProgressionSnapshot(
    seasonId: 'season-1',
    entries: <ArcQuestProgressionEntry>[],
    completedQuestIds: <String>{},
    archivedQuestIds: <String>{},
    trackingKnown: false,
  );

  final String seasonId;
  final List<ArcQuestProgressionEntry> entries;
  final Set<String> completedQuestIds;
  final Set<String> archivedQuestIds;
  final bool trackingKnown;

  ArcQuestProgressionEntry? get activeQuest {
    for (final entry in entries) {
      if (entry.status == ArcProgressionStatus.ready ||
          entry.status == ArcProgressionStatus.active) {
        return entry;
      }
    }
    return entries.isEmpty ? null : entries.first;
  }

  int get completedCount => completedQuestIds.length;
  int get totalCount => entries.length;
  bool get hasReadyQuest => activeQuest?.readyToComplete ?? false;
  String get statusLabel {
    final active = activeQuest;
    if (active == null) return 'Set up';
    if (active.readyToComplete) return 'Ready';
    if (trackingKnown) return 'Active';
    return 'Set up';
  }
}

@immutable
class ArcScrappyProgressionDefinition {
  const ArcScrappyProgressionDefinition({
    required this.level,
    required this.title,
    required this.objectives,
  });

  final int level;
  final String title;
  final List<ArcProgressionObjective> objectives;
}

@immutable
class ArcScrappyProgressionState {
  const ArcScrappyProgressionState({
    required this.seasonId,
    this.currentLevel = 1,
    this.maximumLevelReachedThisSeason = 1,
    this.historicalMaximumLevel = 1,
    this.completedLevelIds = const <String>{},
    this.updatedAt,
  });

  static const empty = ArcScrappyProgressionState(seasonId: 'season-1');

  final String seasonId;
  final int currentLevel;
  final int maximumLevelReachedThisSeason;
  final int historicalMaximumLevel;
  final Set<String> completedLevelIds;
  final DateTime? updatedAt;

  ArcScrappyProgressionState copyWith({
    String? seasonId,
    int? currentLevel,
    int? maximumLevelReachedThisSeason,
    int? historicalMaximumLevel,
    Set<String>? completedLevelIds,
    DateTime? updatedAt,
  }) {
    return ArcScrappyProgressionState(
      seasonId: seasonId ?? this.seasonId,
      currentLevel: currentLevel ?? this.currentLevel,
      maximumLevelReachedThisSeason:
          maximumLevelReachedThisSeason ?? this.maximumLevelReachedThisSeason,
      historicalMaximumLevel:
          historicalMaximumLevel ?? this.historicalMaximumLevel,
      completedLevelIds: completedLevelIds ?? this.completedLevelIds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seasonId': seasonId,
      'currentLevel': currentLevel,
      'maximumLevelReachedThisSeason': maximumLevelReachedThisSeason,
      'historicalMaximumLevel': historicalMaximumLevel,
      'completedLevelIds': completedLevelIds.toList()..sort(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory ArcScrappyProgressionState.fromMap(Map<String, dynamic>? map) {
    if (map == null) return empty;
    final levels = map['completedLevelIds'];
    return ArcScrappyProgressionState(
      seasonId: _string(map['seasonId'], fallback: 'season-1'),
      currentLevel: _int(map['currentLevel'], fallback: 1),
      maximumLevelReachedThisSeason: _int(
        map['maximumLevelReachedThisSeason'],
        fallback: 1,
      ),
      historicalMaximumLevel: _int(map['historicalMaximumLevel'], fallback: 1),
      completedLevelIds: levels is Iterable
          ? levels.map((value) => value.toString()).toSet()
          : const <String>{},
      updatedAt: _date(map['updatedAt']),
    );
  }
}

@immutable
class ArcScrappyProgressionSnapshot {
  const ArcScrappyProgressionSnapshot({
    required this.state,
    required this.definitions,
    required this.nextUpgrade,
    required this.trackingKnown,
    required this.status,
    required this.completionPercent,
    required this.collectedCount,
    required this.requiredCount,
  });

  static const empty = ArcScrappyProgressionSnapshot(
    state: ArcScrappyProgressionState.empty,
    definitions: <ArcScrappyProgressionDefinition>[],
    nextUpgrade: null,
    trackingKnown: false,
    status: ArcCommandStatus.neutral,
    completionPercent: 0,
    collectedCount: 0,
    requiredCount: 0,
  );

  final ArcScrappyProgressionState state;
  final List<ArcScrappyProgressionDefinition> definitions;
  final ArcScrappyProgressionDefinition? nextUpgrade;
  final bool trackingKnown;
  final ArcCommandStatus status;
  final int completionPercent;
  final int collectedCount;
  final int requiredCount;

  bool get readyToUpgrade => status == ArcCommandStatus.ready;
  int get nextLevel => nextUpgrade?.level ?? state.currentLevel;
  String get statusLabel => readyToUpgrade
      ? 'Ready'
      : trackingKnown
      ? 'Active'
      : 'Set up';
  String get progressLabel => requiredCount == 0
      ? 'No upgrade target'
      : '$collectedCount/$requiredCount resources - $completionPercent%';
}

@immutable
class ArcBenchProgressionDefinition {
  const ArcBenchProgressionDefinition({
    required this.benchId,
    required this.station,
    required this.level,
    required this.objectives,
  });

  final String benchId;
  final String station;
  final int level;
  final List<ArcProgressionObjective> objectives;

  String get upgradeLabel => '$station Lv.$level';
}

@immutable
class ArcBenchProgressionRecord {
  const ArcBenchProgressionRecord({
    required this.benchId,
    required this.station,
    required this.seasonId,
    this.currentLevel = 0,
    this.maximumLevelReachedThisSeason = 0,
    this.historicalMaximumLevel = 0,
    this.completedLevelIds = const <String>{},
    this.updatedAt,
  });

  final String benchId;
  final String station;
  final String seasonId;
  final int currentLevel;
  final int maximumLevelReachedThisSeason;
  final int historicalMaximumLevel;
  final Set<String> completedLevelIds;
  final DateTime? updatedAt;

  ArcBenchProgressionRecord copyWith({
    String? seasonId,
    int? currentLevel,
    int? maximumLevelReachedThisSeason,
    int? historicalMaximumLevel,
    Set<String>? completedLevelIds,
    DateTime? updatedAt,
  }) {
    return ArcBenchProgressionRecord(
      benchId: benchId,
      station: station,
      seasonId: seasonId ?? this.seasonId,
      currentLevel: currentLevel ?? this.currentLevel,
      maximumLevelReachedThisSeason:
          maximumLevelReachedThisSeason ?? this.maximumLevelReachedThisSeason,
      historicalMaximumLevel:
          historicalMaximumLevel ?? this.historicalMaximumLevel,
      completedLevelIds: completedLevelIds ?? this.completedLevelIds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'benchId': benchId,
      'station': station,
      'seasonId': seasonId,
      'currentLevel': currentLevel,
      'maximumLevelReachedThisSeason': maximumLevelReachedThisSeason,
      'historicalMaximumLevel': historicalMaximumLevel,
      'completedLevelIds': completedLevelIds.toList()..sort(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory ArcBenchProgressionRecord.fromMap(
    String benchId,
    Map<String, dynamic> map,
  ) {
    final levels = map['completedLevelIds'];
    return ArcBenchProgressionRecord(
      benchId: _nullableString(map['benchId']) ?? benchId,
      station: _string(map['station']),
      seasonId: _string(map['seasonId'], fallback: 'season-1'),
      currentLevel: _int(map['currentLevel']),
      maximumLevelReachedThisSeason: _int(map['maximumLevelReachedThisSeason']),
      historicalMaximumLevel: _int(map['historicalMaximumLevel']),
      completedLevelIds: levels is Iterable
          ? levels.map((value) => value.toString()).toSet()
          : const <String>{},
      updatedAt: _date(map['updatedAt']),
    );
  }
}

@immutable
class ArcBenchProgressionSnapshot {
  const ArcBenchProgressionSnapshot({
    required this.recordsByBenchId,
    required this.definitions,
    required this.nextUpgrade,
    required this.trackingKnown,
    required this.status,
    required this.completionPercent,
    required this.collectedCount,
    required this.requiredCount,
  });

  static const empty = ArcBenchProgressionSnapshot(
    recordsByBenchId: <String, ArcBenchProgressionRecord>{},
    definitions: <ArcBenchProgressionDefinition>[],
    nextUpgrade: null,
    trackingKnown: false,
    status: ArcCommandStatus.neutral,
    completionPercent: 0,
    collectedCount: 0,
    requiredCount: 0,
  );

  final Map<String, ArcBenchProgressionRecord> recordsByBenchId;
  final List<ArcBenchProgressionDefinition> definitions;
  final ArcBenchProgressionDefinition? nextUpgrade;
  final bool trackingKnown;
  final ArcCommandStatus status;
  final int completionPercent;
  final int collectedCount;
  final int requiredCount;

  bool get readyToUpgrade => status == ArcCommandStatus.ready;
  String get station => nextUpgrade?.station ?? 'Bench';
  String get upgradeLabel => nextUpgrade?.upgradeLabel ?? 'Bench upgrade';
  String get statusLabel => readyToUpgrade
      ? 'Ready'
      : trackingKnown
      ? 'Active'
      : 'Set up';
  String get progressLabel => requiredCount == 0
      ? 'No upgrade target'
      : '$collectedCount/$requiredCount resources - $completionPercent%';
}

@immutable
class ArcProgressionRecords {
  const ArcProgressionRecords({
    required this.questRecords,
    required this.scrappyState,
    required this.benchRecords,
    this.seasonId = 'season-1',
  });

  static const empty = ArcProgressionRecords(
    questRecords: <String, ArcQuestProgressionRecord>{},
    scrappyState: ArcScrappyProgressionState.empty,
    benchRecords: <String, ArcBenchProgressionRecord>{},
  );

  final Map<String, ArcQuestProgressionRecord> questRecords;
  final ArcScrappyProgressionState scrappyState;
  final Map<String, ArcBenchProgressionRecord> benchRecords;
  final String seasonId;
}

@immutable
class ArcProgressionSnapshotBundle {
  const ArcProgressionSnapshotBundle({
    required this.quest,
    required this.scrappy,
    required this.bench,
  });

  static const empty = ArcProgressionSnapshotBundle(
    quest: ArcQuestProgressionSnapshot.empty,
    scrappy: ArcScrappyProgressionSnapshot.empty,
    bench: ArcBenchProgressionSnapshot.empty,
  );

  final ArcQuestProgressionSnapshot quest;
  final ArcScrappyProgressionSnapshot scrappy;
  final ArcBenchProgressionSnapshot bench;
}

String _string(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _date(Object? value) {
  if (value is DateTime) return value;
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
