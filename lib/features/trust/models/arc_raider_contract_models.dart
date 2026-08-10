import 'package:cloud_firestore/cloud_firestore.dart';

enum ArcRaiderReportStatus {
  draft,
  submitted,
  pendingReview,
  approved,
  rejected,
  withdrawn,
}

enum ArcRaiderContractStatus {
  available,
  accepted,
  inProgress,
  evidenceSubmitted,
  completed,
  rejected,
  disputed,
  expired,
  cancelled,
}

enum ArcRaiderReportCategory {
  harassment,
  griefing,
  betrayal,
  scam,
  noShow,
  impersonation,
  unsafeCommunication,
  repeatedTargeting,
  other,
}

T _enumValue<T extends Enum>(List<T> values, dynamic raw, T fallback) =>
    values.firstWhere((e) => e.name == raw?.toString(), orElse: () => fallback);
DateTime? _date(dynamic v) => v is Timestamp
    ? v.toDate()
    : v is DateTime
    ? v
    : v is String
    ? DateTime.tryParse(v)
    : null;

class ArcRaiderEvidence {
  const ArcRaiderEvidence({
    required this.id,
    required this.submittedByUid,
    required this.kind,
    required this.url,
    this.storagePath = '',
    this.caption = '',
    this.socialPlatform = '',
    this.createdAt,
  });
  final String id,
      submittedByUid,
      kind,
      url,
      storagePath,
      caption,
      socialPlatform;
  final DateTime? createdAt;
  Map<String, dynamic> toMap() => {
    'id': id,
    'submittedByUid': submittedByUid,
    'kind': kind,
    'url': url,
    'storagePath': storagePath,
    'caption': caption,
    'socialPlatform': socialPlatform,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
  };
  factory ArcRaiderEvidence.fromMap(Map<String, dynamic> m) =>
      ArcRaiderEvidence(
        id: '${m['id'] ?? ''}',
        submittedByUid: '${m['submittedByUid'] ?? ''}',
        kind: '${m['kind'] ?? ''}',
        url: '${m['url'] ?? ''}',
        storagePath: '${m['storagePath'] ?? ''}',
        caption: '${m['caption'] ?? ''}',
        socialPlatform: '${m['socialPlatform'] ?? ''}',
        createdAt: _date(m['createdAt']),
      );
}

class ArcRaiderReport {
  const ArcRaiderReport({
    required this.id,
    required this.reporterUid,
    required this.targetDisplayName,
    required this.category,
    required this.description,
    required this.status,
    this.targetUid = '',
    this.targetGameIdentity = '',
    this.encounterContext = '',
    this.mapId = '',
    this.eventContext = '',
    this.reporterReputationSnapshot = 0,
    this.socialContentUrl = '',
    this.evidence = const [],
    this.moderationNotes = '',
    this.moderatedByUid = '',
    this.createdAt,
    this.updatedAt,
    this.submittedAt,
    this.moderatedAt,
  });
  final String id,
      reporterUid,
      targetUid,
      targetDisplayName,
      targetGameIdentity,
      description,
      encounterContext,
      mapId,
      eventContext,
      socialContentUrl,
      moderationNotes,
      moderatedByUid;
  final ArcRaiderReportCategory category;
  final ArcRaiderReportStatus status;
  final int reporterReputationSnapshot;
  final List<ArcRaiderEvidence> evidence;
  final DateTime? createdAt, updatedAt, submittedAt, moderatedAt;
  bool get canSubmit =>
      reporterUid.isNotEmpty &&
      targetDisplayName.trim().length >= 2 &&
      description.trim().length >= 20 &&
      reporterUid != targetUid;
  bool get canWithdraw =>
      status == ArcRaiderReportStatus.draft ||
      status == ArcRaiderReportStatus.submitted ||
      status == ArcRaiderReportStatus.pendingReview;
  Map<String, dynamic> toMap() => {
    'id': id,
    'reporterUid': reporterUid,
    'targetUid': targetUid,
    'targetDisplayName': targetDisplayName,
    'targetGameIdentity': targetGameIdentity,
    'category': category.name,
    'description': description,
    'encounterContext': encounterContext,
    'mapId': mapId,
    'eventContext': eventContext,
    'reporterReputationSnapshot': reporterReputationSnapshot,
    'socialContentUrl': socialContentUrl,
    'evidence': evidence.map((e) => e.toMap()).toList(),
    'status': status.name,
    'moderationNotes': moderationNotes,
    'moderatedByUid': moderatedByUid,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    if (submittedAt != null) 'submittedAt': Timestamp.fromDate(submittedAt!),
    if (moderatedAt != null) 'moderatedAt': Timestamp.fromDate(moderatedAt!),
  };
  factory ArcRaiderReport.fromMap(Map<String, dynamic> m) => ArcRaiderReport(
    id: '${m['id'] ?? ''}',
    reporterUid: '${m['reporterUid'] ?? ''}',
    targetUid: '${m['targetUid'] ?? ''}',
    targetDisplayName: '${m['targetDisplayName'] ?? ''}',
    targetGameIdentity: '${m['targetGameIdentity'] ?? ''}',
    category: _enumValue(
      ArcRaiderReportCategory.values,
      m['category'],
      ArcRaiderReportCategory.other,
    ),
    description: '${m['description'] ?? ''}',
    encounterContext: '${m['encounterContext'] ?? ''}',
    mapId: '${m['mapId'] ?? ''}',
    eventContext: '${m['eventContext'] ?? ''}',
    reporterReputationSnapshot:
        (m['reporterReputationSnapshot'] as num?)?.toInt() ?? 0,
    socialContentUrl: '${m['socialContentUrl'] ?? ''}',
    evidence: (m['evidence'] is Iterable)
        ? (m['evidence'] as Iterable)
              .whereType<Map>()
              .map(
                (e) => ArcRaiderEvidence.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList(growable: false)
        : const [],
    status: _enumValue(
      ArcRaiderReportStatus.values,
      m['status'],
      ArcRaiderReportStatus.draft,
    ),
    moderationNotes: '${m['moderationNotes'] ?? ''}',
    moderatedByUid: '${m['moderatedByUid'] ?? ''}',
    createdAt: _date(m['createdAt']),
    updatedAt: _date(m['updatedAt']),
    submittedAt: _date(m['submittedAt']),
    moderatedAt: _date(m['moderatedAt']),
  );
}

class ArcRaiderContract {
  const ArcRaiderContract({
    required this.id,
    required this.reportId,
    required this.targetDisplayName,
    required this.reporterUid,
    required this.status,
    this.targetUid = '',
    this.hunterUid = '',
    this.rewardSummary = 'Community reputation',
    this.reputationReward = 10,
    this.evidenceRequirements =
        'Provide clear in-app evidence that identifies the encounter and outcome.',
    this.evidence = const [],
    this.resolution = '',
    this.moderationNotes = '',
    this.moderatedByUid = '',
    this.socialContentUrl = '',
    this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.evidenceSubmittedAt,
    this.resolvedAt,
    this.expiresAt,
  });
  final String id,
      reportId,
      targetUid,
      targetDisplayName,
      reporterUid,
      hunterUid,
      rewardSummary,
      evidenceRequirements,
      resolution,
      moderationNotes,
      moderatedByUid,
      socialContentUrl;
  final int reputationReward;
  final ArcRaiderContractStatus status;
  final List<ArcRaiderEvidence> evidence;
  final DateTime? createdAt,
      updatedAt,
      acceptedAt,
      evidenceSubmittedAt,
      resolvedAt,
      expiresAt;
  bool get isExpired =>
      expiresAt != null &&
      expiresAt!.isBefore(DateTime.now()) &&
      !{
        ArcRaiderContractStatus.completed,
        ArcRaiderContractStatus.cancelled,
        ArcRaiderContractStatus.rejected,
      }.contains(status);
  bool get canAccept =>
      status == ArcRaiderContractStatus.available && !isExpired;
  bool canTransitionTo(ArcRaiderContractStatus next) {
    const allowed = <ArcRaiderContractStatus, Set<ArcRaiderContractStatus>>{
      ArcRaiderContractStatus.available: {
        ArcRaiderContractStatus.accepted,
        ArcRaiderContractStatus.expired,
        ArcRaiderContractStatus.cancelled,
      },
      ArcRaiderContractStatus.accepted: {
        ArcRaiderContractStatus.inProgress,
        ArcRaiderContractStatus.cancelled,
      },
      ArcRaiderContractStatus.inProgress: {
        ArcRaiderContractStatus.evidenceSubmitted,
        ArcRaiderContractStatus.disputed,
        ArcRaiderContractStatus.cancelled,
      },
      ArcRaiderContractStatus.evidenceSubmitted: {
        ArcRaiderContractStatus.completed,
        ArcRaiderContractStatus.rejected,
        ArcRaiderContractStatus.disputed,
      },
      ArcRaiderContractStatus.disputed: {
        ArcRaiderContractStatus.completed,
        ArcRaiderContractStatus.rejected,
        ArcRaiderContractStatus.cancelled,
      },
    };
    return allowed[status]?.contains(next) ?? false;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'reportId': reportId,
    'targetUid': targetUid,
    'targetDisplayName': targetDisplayName,
    'reporterUid': reporterUid,
    'hunterUid': hunterUid,
    'status': status.name,
    'rewardSummary': rewardSummary,
    'reputationReward': reputationReward,
    'evidenceRequirements': evidenceRequirements,
    'evidence': evidence.map((e) => e.toMap()).toList(),
    'resolution': resolution,
    'moderationNotes': moderationNotes,
    'moderatedByUid': moderatedByUid,
    'socialContentUrl': socialContentUrl,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
    if (evidenceSubmittedAt != null)
      'evidenceSubmittedAt': Timestamp.fromDate(evidenceSubmittedAt!),
    if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
    if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
  };
  factory ArcRaiderContract.fromMap(Map<String, dynamic> m) =>
      ArcRaiderContract(
        id: '${m['id'] ?? ''}',
        reportId: '${m['reportId'] ?? ''}',
        targetUid: '${m['targetUid'] ?? ''}',
        targetDisplayName: '${m['targetDisplayName'] ?? ''}',
        reporterUid: '${m['reporterUid'] ?? ''}',
        hunterUid: '${m['hunterUid'] ?? ''}',
        status: _enumValue(
          ArcRaiderContractStatus.values,
          m['status'],
          ArcRaiderContractStatus.available,
        ),
        rewardSummary: '${m['rewardSummary'] ?? 'Community reputation'}',
        reputationReward: (m['reputationReward'] as num?)?.toInt() ?? 10,
        evidenceRequirements: '${m['evidenceRequirements'] ?? ''}',
        evidence: (m['evidence'] is Iterable)
            ? (m['evidence'] as Iterable)
                  .whereType<Map>()
                  .map(
                    (e) =>
                        ArcRaiderEvidence.fromMap(Map<String, dynamic>.from(e)),
                  )
                  .toList(growable: false)
            : const [],
        resolution: '${m['resolution'] ?? ''}',
        moderationNotes: '${m['moderationNotes'] ?? ''}',
        moderatedByUid: '${m['moderatedByUid'] ?? ''}',
        socialContentUrl: '${m['socialContentUrl'] ?? ''}',
        createdAt: _date(m['createdAt']),
        updatedAt: _date(m['updatedAt']),
        acceptedAt: _date(m['acceptedAt']),
        evidenceSubmittedAt: _date(m['evidenceSubmittedAt']),
        resolvedAt: _date(m['resolvedAt']),
        expiresAt: _date(m['expiresAt']),
      );
}
