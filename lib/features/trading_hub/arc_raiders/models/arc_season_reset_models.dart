import 'package:cloud_firestore/cloud_firestore.dart';

enum ArcSeasonResetStatus { idle, previewReady, inProgress, completed, failed }

enum ArcSeasonResetClassification {
  preserved,
  reset,
  recalculated,
  manualReconfirm,
}

extension ArcSeasonResetClassificationLabel on ArcSeasonResetClassification {
  String get label => switch (this) {
    ArcSeasonResetClassification.preserved => 'Preserved',
    ArcSeasonResetClassification.reset => 'Reset',
    ArcSeasonResetClassification.recalculated => 'Recalculated',
    ArcSeasonResetClassification.manualReconfirm => 'Manual reconfirmation',
  };
}

class ArcSeasonResetPolicy {
  const ArcSeasonResetPolicy._();

  static const defaultCurrentSeasonId = 'closed-beta-season-1';
  static const resetPolicyVersion = 1;

  static const persistentSystems = <String>[
    'Account identity',
    'Authentication',
    'Legal consent',
    'Profile identity',
    'Embark ID',
    'Archetypes',
    'Communication style',
    'Squad intent',
    'Availability',
    'Favourite Riders',
    'Reputation',
    'Historical completed trades',
    'Permanent rewards',
    'Equipped cosmetics when still equipable',
  ];

  static const resetSystems = <String>[
    'Current-season Scrappy progression',
    'Current-season quest item progress',
    'Current-season bench material progress',
    'Current-season missions and Operation candidates',
    'Current-season Reward Vault progression state',
  ];

  static const recalculatedSystems = <String>[
    'Command Centre priorities',
    'Profile completion',
    'Active missions',
    'Operations availability',
    'Scrappy target',
    'Quest target',
    'Bench target',
    'Blueprint Tracker guidance',
    'Favourite Loadout missing-item state',
    'Trade Intelligence relevance',
  ];

  static const manualReconfirmSystems = <String>[
    'Current session intent',
    'Temporary matchmaking availability',
    'Active raid plans',
    'Expired trade availability',
    'Away status',
  ];

  static List<ArcSeasonResetSystemImpact> impacts({
    required int scrappyStateCount,
    required int questStateCount,
    required int benchStateCount,
    required int rewardCount,
    int operationProgressCount = 0,
  }) {
    return <ArcSeasonResetSystemImpact>[
      const ArcSeasonResetSystemImpact(
        id: 'profile',
        label: 'Profile, identity and reputation',
        classification: ArcSeasonResetClassification.preserved,
        reason: 'Identity and trust history are account-level state.',
      ),
      ArcSeasonResetSystemImpact(
        id: 'scrappy',
        label: 'Scrappy Tracker',
        classification: ArcSeasonResetClassification.reset,
        reason: 'Known current-season Scrappy item progress returns to zero.',
        itemCount: scrappyStateCount,
      ),
      ArcSeasonResetSystemImpact(
        id: 'quests',
        label: 'Quest Tracker',
        classification: ArcSeasonResetClassification.reset,
        reason: 'Known current-season quest item progress returns to zero.',
        itemCount: questStateCount,
      ),
      ArcSeasonResetSystemImpact(
        id: 'benches',
        label: 'Bench Tracker',
        classification: ArcSeasonResetClassification.reset,
        reason: 'Known current-season bench material progress returns to zero.',
        itemCount: benchStateCount,
      ),
      ArcSeasonResetSystemImpact(
        id: 'operations',
        label: 'Current-season Operations',
        classification: ArcSeasonResetClassification.reset,
        reason:
            'Seasonal Operation progress is archived and starts fresh next season.',
        itemCount: operationProgressCount,
      ),
      ArcSeasonResetSystemImpact(
        id: 'rewards',
        label: 'Reward Vault',
        classification: ArcSeasonResetClassification.preserved,
        reason:
            'Earned reward records are archived/retained; season-only equipability is evaluated separately.',
        itemCount: rewardCount,
      ),
      const ArcSeasonResetSystemImpact(
        id: 'command-centre',
        label: 'Command Centre',
        classification: ArcSeasonResetClassification.recalculated,
        reason: 'Priorities are rebuilt from the post-reset tracker state.',
      ),
      const ArcSeasonResetSystemImpact(
        id: 'temporary-state',
        label: 'Temporary activity state',
        classification: ArcSeasonResetClassification.manualReconfirm,
        reason:
            'Session intent, away status, active raid plans and expired trade availability should be reconfirmed.',
      ),
    ];
  }
}

class ArcSeasonResetSystemImpact {
  const ArcSeasonResetSystemImpact({
    required this.id,
    required this.label,
    required this.classification,
    required this.reason,
    this.itemCount = 0,
  });

  final String id;
  final String label;
  final ArcSeasonResetClassification classification;
  final String reason;
  final int itemCount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'classification': classification.name,
      'reason': reason,
      'itemCount': itemCount,
    };
  }

  factory ArcSeasonResetSystemImpact.fromMap(Map<String, dynamic> map) {
    return ArcSeasonResetSystemImpact(
      id: (map['id'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      classification: ArcSeasonResetClassification.values.firstWhere(
        (value) => value.name == map['classification'],
        orElse: () => ArcSeasonResetClassification.recalculated,
      ),
      reason: (map['reason'] ?? '').toString(),
      itemCount: _int(map['itemCount']),
    );
  }
}

class ArcSeasonHistoryEntry {
  const ArcSeasonHistoryEntry({
    required this.seasonId,
    required this.resetId,
    required this.completedAt,
    this.scrappyStateCount = 0,
    this.questStateCount = 0,
    this.benchStateCount = 0,
    this.operationProgressCount = 0,
    this.rewardCount = 0,
  });

  final String seasonId;
  final String resetId;
  final DateTime completedAt;
  final int scrappyStateCount;
  final int questStateCount;
  final int benchStateCount;
  final int operationProgressCount;
  final int rewardCount;

  Map<String, dynamic> toMap() {
    return {
      'seasonId': seasonId,
      'resetId': resetId,
      'completedAt': completedAt.toIso8601String(),
      'scrappyStateCount': scrappyStateCount,
      'questStateCount': questStateCount,
      'benchStateCount': benchStateCount,
      'operationProgressCount': operationProgressCount,
      'rewardCount': rewardCount,
    };
  }

  factory ArcSeasonHistoryEntry.fromMap(Map<String, dynamic> map) {
    return ArcSeasonHistoryEntry(
      seasonId: (map['seasonId'] ?? '').toString(),
      resetId: (map['resetId'] ?? '').toString(),
      completedAt:
          _date(map['completedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      scrappyStateCount: _int(map['scrappyStateCount']),
      questStateCount: _int(map['questStateCount']),
      benchStateCount: _int(map['benchStateCount']),
      operationProgressCount: _int(map['operationProgressCount']),
      rewardCount: _int(map['rewardCount']),
    );
  }
}

class ArcSeasonState {
  const ArcSeasonState({
    required this.currentSeasonId,
    this.currentSeasonStartedAt,
    this.lastCompletedSeasonId,
    this.lastResetId,
    this.lastResetAt,
    this.resetVersion = 0,
    this.resetStatus = ArcSeasonResetStatus.idle,
    this.pendingResetId,
    this.pendingNextSeasonId,
    this.seasonHistory = const <ArcSeasonHistoryEntry>[],
    this.lastResetResult = const <String, dynamic>{},
    this.lastReconciliation = const <String, dynamic>{},
  });

  final String currentSeasonId;
  final DateTime? currentSeasonStartedAt;
  final String? lastCompletedSeasonId;
  final String? lastResetId;
  final DateTime? lastResetAt;
  final int resetVersion;
  final ArcSeasonResetStatus resetStatus;
  final String? pendingResetId;
  final String? pendingNextSeasonId;
  final List<ArcSeasonHistoryEntry> seasonHistory;
  final Map<String, dynamic> lastResetResult;
  final Map<String, dynamic> lastReconciliation;

  bool get resetInProgress =>
      resetStatus == ArcSeasonResetStatus.inProgress &&
      (pendingResetId?.trim().isNotEmpty ?? false);

  ArcSeasonState copyWith({
    String? currentSeasonId,
    DateTime? currentSeasonStartedAt,
    String? lastCompletedSeasonId,
    String? lastResetId,
    DateTime? lastResetAt,
    int? resetVersion,
    ArcSeasonResetStatus? resetStatus,
    String? pendingResetId,
    String? pendingNextSeasonId,
    List<ArcSeasonHistoryEntry>? seasonHistory,
    Map<String, dynamic>? lastResetResult,
    Map<String, dynamic>? lastReconciliation,
  }) {
    return ArcSeasonState(
      currentSeasonId: currentSeasonId ?? this.currentSeasonId,
      currentSeasonStartedAt:
          currentSeasonStartedAt ?? this.currentSeasonStartedAt,
      lastCompletedSeasonId:
          lastCompletedSeasonId ?? this.lastCompletedSeasonId,
      lastResetId: lastResetId ?? this.lastResetId,
      lastResetAt: lastResetAt ?? this.lastResetAt,
      resetVersion: resetVersion ?? this.resetVersion,
      resetStatus: resetStatus ?? this.resetStatus,
      pendingResetId: pendingResetId ?? this.pendingResetId,
      pendingNextSeasonId: pendingNextSeasonId ?? this.pendingNextSeasonId,
      seasonHistory: seasonHistory ?? this.seasonHistory,
      lastResetResult: lastResetResult ?? this.lastResetResult,
      lastReconciliation: lastReconciliation ?? this.lastReconciliation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentSeasonId': currentSeasonId,
      'currentSeasonStartedAt': currentSeasonStartedAt?.toIso8601String(),
      'lastCompletedSeasonId': lastCompletedSeasonId,
      'lastResetId': lastResetId,
      'lastResetAt': lastResetAt?.toIso8601String(),
      'resetVersion': resetVersion,
      'resetStatus': resetStatus.name,
      'pendingResetId': pendingResetId,
      'pendingNextSeasonId': pendingNextSeasonId,
      'seasonHistory': seasonHistory.map((entry) => entry.toMap()).toList(),
      'lastResetResult': lastResetResult,
      'lastReconciliation': lastReconciliation,
      'policyVersion': ArcSeasonResetPolicy.resetPolicyVersion,
    };
  }

  factory ArcSeasonState.initial({DateTime? now}) {
    final resolvedNow = now ?? DateTime.now().toUtc();
    return ArcSeasonState(
      currentSeasonId: ArcSeasonResetPolicy.defaultCurrentSeasonId,
      currentSeasonStartedAt: resolvedNow,
    );
  }

  factory ArcSeasonState.fromMap(Map<String, dynamic> map) {
    final history = _listOfMaps(
      map['seasonHistory'],
    ).map(ArcSeasonHistoryEntry.fromMap).toList(growable: false);
    return ArcSeasonState(
      currentSeasonId:
          _string(map['currentSeasonId']) ??
          ArcSeasonResetPolicy.defaultCurrentSeasonId,
      currentSeasonStartedAt: _date(map['currentSeasonStartedAt']),
      lastCompletedSeasonId: _string(map['lastCompletedSeasonId']),
      lastResetId: _string(map['lastResetId']),
      lastResetAt: _date(map['lastResetAt']),
      resetVersion: _int(map['resetVersion']),
      resetStatus: ArcSeasonResetStatus.values.firstWhere(
        (value) => value.name == map['resetStatus'],
        orElse: () => ArcSeasonResetStatus.idle,
      ),
      pendingResetId: _string(map['pendingResetId']),
      pendingNextSeasonId: _string(map['pendingNextSeasonId']),
      seasonHistory: history,
      lastResetResult: _map(map['lastResetResult']),
      lastReconciliation: _map(map['lastReconciliation']),
    );
  }
}

class ArcSeasonResetPreview {
  const ArcSeasonResetPreview({
    required this.currentSeasonId,
    required this.nextSeasonId,
    required this.resetId,
    required this.resetVersion,
    required this.generatedAt,
    required this.impacts,
    this.scrappyStateCount = 0,
    this.questStateCount = 0,
    this.benchStateCount = 0,
    this.operationProgressCount = 0,
    this.rewardCount = 0,
  });

  final String currentSeasonId;
  final String nextSeasonId;
  final String resetId;
  final int resetVersion;
  final DateTime generatedAt;
  final List<ArcSeasonResetSystemImpact> impacts;
  final int scrappyStateCount;
  final int questStateCount;
  final int benchStateCount;
  final int operationProgressCount;
  final int rewardCount;

  List<ArcSeasonResetSystemImpact> impactsFor(
    ArcSeasonResetClassification classification,
  ) {
    return impacts
        .where((impact) => impact.classification == classification)
        .toList(growable: false);
  }

  Map<String, dynamic> toMap() {
    return {
      'currentSeasonId': currentSeasonId,
      'nextSeasonId': nextSeasonId,
      'resetId': resetId,
      'resetVersion': resetVersion,
      'generatedAt': generatedAt.toIso8601String(),
      'impacts': impacts.map((impact) => impact.toMap()).toList(),
      'scrappyStateCount': scrappyStateCount,
      'questStateCount': questStateCount,
      'benchStateCount': benchStateCount,
      'operationProgressCount': operationProgressCount,
      'rewardCount': rewardCount,
    };
  }
}

class ArcSeasonResetApplyResult {
  const ArcSeasonResetApplyResult({
    required this.resetId,
    required this.archivedSeasonId,
    required this.currentSeasonId,
    required this.resetVersion,
    required this.completedAt,
    this.alreadyApplied = false,
    this.resetStateIds = const <String>[],
    this.archivedOperationIds = const <String>[],
    this.archivedRewardCount = 0,
  });

  final String resetId;
  final String archivedSeasonId;
  final String currentSeasonId;
  final int resetVersion;
  final DateTime completedAt;
  final bool alreadyApplied;
  final List<String> resetStateIds;
  final List<String> archivedOperationIds;
  final int archivedRewardCount;

  Map<String, dynamic> toMap() {
    return {
      'resetId': resetId,
      'archivedSeasonId': archivedSeasonId,
      'currentSeasonId': currentSeasonId,
      'resetVersion': resetVersion,
      'completedAt': completedAt.toIso8601String(),
      'alreadyApplied': alreadyApplied,
      'resetStateIds': resetStateIds,
      'archivedOperationIds': archivedOperationIds,
      'archivedRewardCount': archivedRewardCount,
    };
  }
}

String? _string(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

DateTime? _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _listOfMaps(dynamic value) {
  if (value is! Iterable) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .toList(growable: false);
}
