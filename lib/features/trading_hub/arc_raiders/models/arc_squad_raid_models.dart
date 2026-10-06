import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_tier.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

enum ArcSquadRaidFairnessMode {
  balancedSquad,
  leaderPriorities,
  maximumSquadValue,
}

extension ArcSquadRaidFairnessModeX on ArcSquadRaidFairnessMode {
  String get label => switch (this) {
    ArcSquadRaidFairnessMode.balancedSquad => 'Balanced squad',
    ArcSquadRaidFairnessMode.leaderPriorities => 'Leader priorities',
    ArcSquadRaidFairnessMode.maximumSquadValue => 'Maximum squad value',
  };

  String get description => switch (this) {
    ArcSquadRaidFairnessMode.balancedSquad =>
      'Give every Raider meaningful progress where the route allows it.',
    ArcSquadRaidFairnessMode.leaderPriorities =>
      'Bias the run toward the squad leader while keeping efficient teammate stops.',
    ArcSquadRaidFairnessMode.maximumSquadValue =>
      'Maximise total squad progress per minute regardless of equal distribution.',
  };
}

enum ArcSquadObjectiveClass {
  sharedCompletion,
  individualLoot,
  scarceCompetitive,
  repeatableEncounter,
  renewableResource,
  oneOffInteraction,
}

extension ArcSquadObjectiveClassX on ArcSquadObjectiveClass {
  String get label => switch (this) {
    ArcSquadObjectiveClass.sharedCompletion => 'Shared completion',
    ArcSquadObjectiveClass.individualLoot => 'Individual loot',
    ArcSquadObjectiveClass.scarceCompetitive => 'Scarce pickup',
    ArcSquadObjectiveClass.repeatableEncounter => 'Repeatable encounter',
    ArcSquadObjectiveClass.renewableResource => 'Renewable resource',
    ArcSquadObjectiveClass.oneOffInteraction => 'One-off interaction',
  };
}

class ArcSquadRaidObjectiveProjection {
  const ArcSquadRaidObjectiveProjection({
    required this.id,
    required this.ownerUid,
    required this.ownerLabel,
    required this.label,
    required this.system,
    required this.itemName,
    required this.missingCount,
    required this.classification,
    required this.baseWeight,
    this.sourceHint,
    this.blueprintId,
    this.mapNames = const <String>[],
    this.conditionNames = const <String>[],
  });

  final String id;
  final String ownerUid;
  final String ownerLabel;
  final String label;
  final String system;
  final String itemName;
  final int missingCount;
  final String? sourceHint;
  final String? blueprintId;
  final List<String> mapNames;
  final List<String> conditionNames;
  final ArcSquadObjectiveClass classification;
  final double baseWeight;

  String get overlapKey {
    final item = itemName.trim().isEmpty ? label : itemName;
    return '${system.trim().toLowerCase()}|${item.trim().toLowerCase()}';
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'ownerUid': ownerUid,
    'ownerLabel': ownerLabel,
    'label': label,
    'system': system,
    'itemName': itemName,
    'missingCount': missingCount,
    'sourceHint': sourceHint,
    'blueprintId': blueprintId,
    'mapNames': mapNames,
    'conditionNames': conditionNames,
    'classification': classification.name,
    'baseWeight': baseWeight,
  };

  factory ArcSquadRaidObjectiveProjection.fromMap(
    Map<String, dynamic> map, {
    required String fallbackOwnerUid,
    required String fallbackOwnerLabel,
  }) {
    List<String> readList(dynamic value) => value is Iterable
        ? value
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    return ArcSquadRaidObjectiveProjection(
      id: map['id']?.toString().trim() ?? '',
      ownerUid: map['ownerUid']?.toString().trim().isNotEmpty == true
          ? map['ownerUid'].toString().trim()
          : fallbackOwnerUid,
      ownerLabel: map['ownerLabel']?.toString().trim().isNotEmpty == true
          ? map['ownerLabel'].toString().trim()
          : fallbackOwnerLabel,
      label: map['label']?.toString().trim() ?? 'Squad objective',
      system: map['system']?.toString().trim() ?? 'Tracker',
      itemName: map['itemName']?.toString().trim() ?? '',
      missingCount: (map['missingCount'] as num?)?.toInt() ?? 0,
      sourceHint: map['sourceHint']?.toString().trim(),
      blueprintId: map['blueprintId']?.toString().trim(),
      mapNames: readList(map['mapNames']),
      conditionNames: readList(map['conditionNames']),
      classification: ArcSquadObjectiveClass.values.firstWhere(
        (item) => item.name == map['classification'],
        orElse: () => ArcSquadObjectiveClass.individualLoot,
      ),
      baseWeight: (map['baseWeight'] as num?)?.toDouble() ?? 1,
    );
  }
}

class ArcSquadRaidProjection {
  const ArcSquadRaidProjection({
    required this.ownerUid,
    required this.ownerLabel,
    required this.tier,
    required this.objectiveLimit,
    required this.objectives,
    this.sharing = ArcRaidObjectiveSharing.allChosenRaidPlanObjectives,
    this.updatedAt,
  });

  final String ownerUid;
  final String ownerLabel;
  final UagSubscriptionTier tier;
  final int objectiveLimit;
  final List<ArcSquadRaidObjectiveProjection> objectives;
  final ArcRaidObjectiveSharing sharing;
  final DateTime? updatedAt;

  String get contentSignature {
    final objectiveSignature = objectives
        .map(
          (item) =>
              '${item.id}:${item.missingCount}:${item.baseWeight.toStringAsFixed(2)}',
        )
        .join('|');
    return '${tier.name}|$objectiveLimit|${sharing.name}|$objectiveSignature';
  }

  factory ArcSquadRaidProjection.fromMap(
    String ownerUid,
    Map<String, dynamic> map,
  ) {
    final ownerLabel = map['ownerLabel']?.toString().trim() ?? 'Squad Raider';
    final rawObjectives = map['objectives'];
    return ArcSquadRaidProjection(
      ownerUid: ownerUid,
      ownerLabel: ownerLabel,
      tier: UagSubscriptionTier.fromValue(map['tier']?.toString()),
      objectiveLimit: (map['objectiveLimit'] as num?)?.toInt() ?? 1,
      sharing: ArcRaidObjectiveSharing.values.firstWhere(
        (item) => item.name == map['sharingMode'],
        orElse: () => ArcRaidObjectiveSharing.allChosenRaidPlanObjectives,
      ),
      objectives: rawObjectives is Iterable
          ? rawObjectives
                .whereType<Map>()
                .map(
                  (item) => ArcSquadRaidObjectiveProjection.fromMap(
                    Map<String, dynamic>.from(item),
                    fallbackOwnerUid: ownerUid,
                    fallbackOwnerLabel: ownerLabel,
                  ),
                )
                .where((item) => item.id.isNotEmpty)
                .toList(growable: false)
          : const <ArcSquadRaidObjectiveProjection>[],
      updatedAt: _readDate(map['updatedAt']),
    );
  }
}

class ArcSquadRaidSession {
  const ArcSquadRaidSession({
    required this.id,
    required this.leaderUid,
    required this.leaderLabel,
    required this.memberUids,
    required this.memberLabels,
    required this.fairnessMode,
    required this.status,
    this.routePlan,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String leaderUid;
  final String leaderLabel;
  final List<String> memberUids;
  final Map<String, String> memberLabels;
  final ArcSquadRaidFairnessMode fairnessMode;
  final String status;
  final ArcRaidRoutePlan? routePlan;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get active => status == 'active';
  bool isMember(String? uid) => uid != null && memberUids.contains(uid);
  bool isLeader(String? uid) => uid != null && leaderUid == uid;
  int get squadSize => memberUids.length;

  factory ArcSquadRaidSession.fromMap(
    String id,
    Map<String, dynamic> map, {
    ArcRaidRoutePlan? routePlan,
  }) {
    final rawMembers = map['memberUids'];
    final rawLabels = map['memberLabels'];
    return ArcSquadRaidSession(
      id: id,
      leaderUid: map['leaderUid']?.toString().trim() ?? '',
      leaderLabel: map['leaderLabel']?.toString().trim() ?? 'Squad Leader',
      memberUids: rawMembers is Iterable
          ? rawMembers
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toList(growable: false)
          : const <String>[],
      memberLabels: rawLabels is Map
          ? rawLabels.map(
              (key, value) =>
                  MapEntry(key.toString().trim(), value.toString().trim()),
            )
          : const <String, String>{},
      fairnessMode: ArcSquadRaidFairnessMode.values.firstWhere(
        (item) => item.name == map['fairnessMode'],
        orElse: () => ArcSquadRaidFairnessMode.balancedSquad,
      ),
      status: map['status']?.toString().trim() ?? 'active',
      routePlan: routePlan,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }
}

class ArcSquadRaidBundle {
  const ArcSquadRaidBundle({required this.session, required this.projections});

  final ArcSquadRaidSession session;
  final Map<String, ArcSquadRaidProjection> projections;

  bool get allMembersSynced =>
      session.memberUids.every(projections.containsKey);

  int get syncedCount =>
      session.memberUids.where(projections.containsKey).length;

  int get totalObjectiveCount => projections.values.fold<int>(
    0,
    (total, projection) => total + projection.objectives.length,
  );
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
