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

enum ArcRaiderContractType { open, closed }

enum ArcRaiderParticipationStatus {
  interested,
  negotiating,
  active,
  evidenceSubmitted,
  verified,
  rejected,
  disputed,
  rewardPending,
  rewardDelivered,
  expired,
  withdrawn,
}

enum ArcRaiderCounterOfferStatus { proposed, accepted, rejected, countered }

enum ArcRaiderReportCategory {
  extractionRatting,
  ambushRatting,
  spawnRatting,
  lootCamping,
  objectiveCamping,
  doorwayCamping,
  traversalCamping,
  repeatedTargeting,
  griefing,
  harassment,
  scam,
  other,
}

enum ArcRaiderRepeatBehaviour { no, sameRaid, previousEncounter, notSure }

T _enumValue<T extends Enum>(List<T> values, dynamic raw, T fallback) =>
    values.firstWhere((e) => e.name == raw?.toString(), orElse: () => fallback);

DateTime? _date(dynamic value) => value is Timestamp
    ? value.toDate()
    : value is DateTime
    ? value
    : value is String
    ? DateTime.tryParse(value)
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

  final String id;
  final String submittedByUid;
  final String kind;
  final String url;
  final String storagePath;
  final String caption;
  final String socialPlatform;
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

  factory ArcRaiderEvidence.fromMap(Map<String, dynamic> map) =>
      ArcRaiderEvidence(
        id: '${map['id'] ?? ''}',
        submittedByUid: '${map['submittedByUid'] ?? ''}',
        kind: '${map['kind'] ?? ''}',
        url: '${map['url'] ?? ''}',
        storagePath: '${map['storagePath'] ?? ''}',
        caption: '${map['caption'] ?? ''}',
        socialPlatform: '${map['socialPlatform'] ?? ''}',
        createdAt: _date(map['createdAt']),
      );
}

class ArcRaiderRewardItem {
  const ArcRaiderRewardItem({
    required this.itemId,
    required this.name,
    required this.category,
    required this.quantity,
  });

  final String itemId;
  final String name;
  final String category;
  final int quantity;

  Map<String, dynamic> toMap() => {
    'itemId': itemId,
    'name': name,
    'category': category,
    'quantity': quantity,
  };

  factory ArcRaiderRewardItem.fromMap(Map<String, dynamic> map) =>
      ArcRaiderRewardItem(
        itemId: '${map['itemId'] ?? ''}',
        name: '${map['name'] ?? ''}',
        category: '${map['category'] ?? ''}',
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      );
}

class ArcRaiderRewardPoolEntry {
  const ArcRaiderRewardPoolEntry({
    required this.itemId,
    required this.name,
    required this.category,
    required this.quantityOffered,
    this.quantityRemaining = 0,
    this.quantityClaimed = 0,
    this.bundleId = '',
    this.bundled = false,
    this.createdAt,
    this.updatedAt,
  }) : assert(quantityOffered >= 0),
       assert(quantityRemaining >= 0),
       assert(quantityClaimed >= 0);

  final String itemId;
  final String name;
  final String category;
  final int quantityOffered;
  final int quantityRemaining;
  final int quantityClaimed;
  final String bundleId;
  final bool bundled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get available => quantityRemaining > 0;

  ArcRaiderRewardPoolEntry withVerifiedClaim({required int quantity}) {
    final amount = quantity <= 0 ? 0 : quantity;
    final nextRemaining = (quantityRemaining - amount).clamp(
      0,
      quantityRemaining,
    );
    return ArcRaiderRewardPoolEntry(
      itemId: itemId,
      name: name,
      category: category,
      quantityOffered: quantityOffered,
      quantityRemaining: nextRemaining,
      quantityClaimed: quantityClaimed + amount,
      bundleId: bundleId,
      bundled: bundled,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'itemId': itemId,
    'name': name,
    'category': category,
    'quantityOffered': quantityOffered,
    'quantityRemaining': quantityRemaining,
    'quantityClaimed': quantityClaimed,
    'bundleId': bundleId,
    'bundled': bundled,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
  };

  factory ArcRaiderRewardPoolEntry.fromMap(Map<String, dynamic> map) =>
      ArcRaiderRewardPoolEntry(
        itemId: '${map['itemId'] ?? ''}',
        name: '${map['name'] ?? ''}',
        category: '${map['category'] ?? ''}',
        quantityOffered:
            (map['quantityOffered'] as num?)?.toInt() ??
            (map['quantity'] as num?)?.toInt() ??
            1,
        quantityRemaining:
            (map['quantityRemaining'] as num?)?.toInt() ??
            (map['quantityOffered'] as num?)?.toInt() ??
            (map['quantity'] as num?)?.toInt() ??
            1,
        quantityClaimed: (map['quantityClaimed'] as num?)?.toInt() ?? 0,
        bundleId: '${map['bundleId'] ?? ''}',
        bundled:
            map['bundled'] == true ||
            map['bundleId']?.toString().isNotEmpty == true,
        createdAt: _date(map['createdAt']),
        updatedAt: _date(map['updatedAt']),
      );
}

class ArcRaiderContractParticipant {
  const ArcRaiderContractParticipant({
    required this.contractId,
    required this.hunterUid,
    required this.joinedAt,
    this.status = ArcRaiderParticipationStatus.interested,
    this.requestedReward = const {},
    this.negotiatedReward = const {},
    this.evidence = const [],
    this.claimedRewardIds = const [],
    this.moderationNotes = '',
    this.verifiedAt,
    this.updatedAt,
  });

  final String contractId;
  final String hunterUid;
  final DateTime? joinedAt;
  final ArcRaiderParticipationStatus status;
  final Map<String, dynamic> requestedReward;
  final Map<String, dynamic> negotiatedReward;
  final List<ArcRaiderEvidence> evidence;
  final List<String> claimedRewardIds;
  final String moderationNotes;
  final DateTime? verifiedAt;
  final DateTime? updatedAt;

  bool get isActive =>
      status == ArcRaiderParticipationStatus.active ||
      status == ArcRaiderParticipationStatus.evidenceSubmitted ||
      status == ArcRaiderParticipationStatus.verified ||
      status == ArcRaiderParticipationStatus.rewardPending ||
      status == ArcRaiderParticipationStatus.rewardDelivered;

  Map<String, dynamic> toMap() => {
    'contractId': contractId,
    'hunterUid': hunterUid,
    if (joinedAt != null) 'joinedAt': Timestamp.fromDate(joinedAt!),
    'status': status.name,
    'requestedReward': requestedReward,
    'negotiatedReward': negotiatedReward,
    'evidence': evidence.map((e) => e.toMap()).toList(),
    'claimedRewardIds': claimedRewardIds,
    'moderationNotes': moderationNotes,
    if (verifiedAt != null) 'verifiedAt': Timestamp.fromDate(verifiedAt!),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
  };

  factory ArcRaiderContractParticipant.fromMap(Map<String, dynamic> map) =>
      ArcRaiderContractParticipant(
        contractId: '${map['contractId'] ?? ''}',
        hunterUid: '${map['hunterUid'] ?? ''}',
        joinedAt: _date(map['joinedAt']),
        status: _enumValue(
          ArcRaiderParticipationStatus.values,
          map['status'],
          ArcRaiderParticipationStatus.interested,
        ),
        requestedReward: Map<String, dynamic>.from(
          (map['requestedReward'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{},
        ),
        negotiatedReward: Map<String, dynamic>.from(
          (map['negotiatedReward'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{},
        ),
        evidence: (map['evidence'] is Iterable)
            ? (map['evidence'] as Iterable)
                  .whereType<Map>()
                  .map(
                    (e) =>
                        ArcRaiderEvidence.fromMap(Map<String, dynamic>.from(e)),
                  )
                  .toList(growable: false)
            : const [],
        claimedRewardIds: ((map['claimedRewardIds'] as Iterable?) ?? const [])
            .whereType<String>()
            .toList(growable: false),
        moderationNotes: '${map['moderationNotes'] ?? ''}',
        verifiedAt: _date(map['verifiedAt']),
        updatedAt: _date(map['updatedAt']),
      );
}

class ArcRaiderCounterOffer {
  const ArcRaiderCounterOffer({
    required this.id,
    required this.contractId,
    required this.hunterUid,
    required this.requestedRewardItemIds,
    required this.quantities,
    this.bundleRequest = '',
    this.alternativeItemIds = const [],
    this.status = ArcRaiderCounterOfferStatus.proposed,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String contractId;
  final String hunterUid;
  final List<String> requestedRewardItemIds;
  final List<int> quantities;
  final String bundleRequest;
  final List<String> alternativeItemIds;
  final ArcRaiderCounterOfferStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'contractId': contractId,
    'hunterUid': hunterUid,
    'requestedRewardItemIds': requestedRewardItemIds,
    'quantities': quantities,
    'bundleRequest': bundleRequest,
    'alternativeItemIds': alternativeItemIds,
    'status': status.name,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
  };

  factory ArcRaiderCounterOffer.fromMap(Map<String, dynamic> map) =>
      ArcRaiderCounterOffer(
        id: '${map['id'] ?? ''}',
        contractId: '${map['contractId'] ?? ''}',
        hunterUid: '${map['hunterUid'] ?? ''}',
        requestedRewardItemIds:
            ((map['requestedRewardItemIds'] as Iterable?) ?? const [])
                .whereType<String>()
                .toList(growable: false),
        quantities: ((map['quantities'] as Iterable?) ?? const [])
            .whereType<num>()
            .map((value) => value.toInt())
            .toList(growable: false),
        bundleRequest: '${map['bundleRequest'] ?? ''}',
        alternativeItemIds:
            ((map['alternativeItemIds'] as Iterable?) ?? const [])
                .whereType<String>()
                .toList(growable: false),
        status: _enumValue(
          ArcRaiderCounterOfferStatus.values,
          map['status'],
          ArcRaiderCounterOfferStatus.proposed,
        ),
        createdAt: _date(map['createdAt']),
        updatedAt: _date(map['updatedAt']),
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
    this.mapDisplayName = '',
    this.locationLabel = '',
    this.locationX,
    this.locationY,
    this.nearestPoiId = '',
    this.nearestPoiName = '',
    this.atExtraction = false,
    this.extractionId = '',
    this.extractionName = '',
    this.rattingSubtype = '',
    this.serverRegion = '',
    this.incidentAt,
    this.repeatBehaviour = ArcRaiderRepeatBehaviour.no,
    this.repeatCount = 1,
    this.eventContext = '',
    this.reporterReputationSnapshot = 0,
    this.socialContentUrl = '',
    this.evidence = const [],
    this.requestContract = false,
    this.rewardItems = const [],
    this.moderationNotes = '',
    this.moderatedByUid = '',
    this.createdAt,
    this.updatedAt,
    this.submittedAt,
    this.moderatedAt,
  });

  final String id;
  final String reporterUid;
  final String targetUid;
  final String targetDisplayName;
  final String targetGameIdentity;
  final String description;
  final String encounterContext;
  final String mapId;
  final String mapDisplayName;
  final String locationLabel;
  final double? locationX;
  final double? locationY;
  final String nearestPoiId;
  final String nearestPoiName;
  final bool atExtraction;
  final String extractionId;
  final String extractionName;
  final String rattingSubtype;
  final String serverRegion;
  final DateTime? incidentAt;
  final ArcRaiderRepeatBehaviour repeatBehaviour;
  final int repeatCount;
  final String eventContext;
  final String socialContentUrl;
  final String moderationNotes;
  final String moderatedByUid;
  final ArcRaiderReportCategory category;
  final ArcRaiderReportStatus status;
  final int reporterReputationSnapshot;
  final List<ArcRaiderEvidence> evidence;
  final bool requestContract;
  final List<ArcRaiderRewardItem> rewardItems;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;
  final DateTime? moderatedAt;

  bool get canSubmit =>
      reporterUid.isNotEmpty &&
      targetDisplayName.trim().length >= 2 &&
      description.trim().length >= 20 &&
      mapId.isNotEmpty &&
      serverRegion.isNotEmpty &&
      incidentAt != null &&
      locationX != null &&
      locationY != null &&
      reporterUid != targetUid &&
      (!atExtraction || extractionId.isNotEmpty) &&
      (!requestContract || rewardItems.isNotEmpty);

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
    'mapDisplayName': mapDisplayName,
    'locationLabel': locationLabel,
    'locationX': locationX,
    'locationY': locationY,
    'nearestPoiId': nearestPoiId,
    'nearestPoiName': nearestPoiName,
    'atExtraction': atExtraction,
    'extractionId': extractionId,
    'extractionName': extractionName,
    'rattingSubtype': rattingSubtype,
    'serverRegion': serverRegion,
    if (incidentAt != null) 'incidentAt': Timestamp.fromDate(incidentAt!),
    'repeatBehaviour': repeatBehaviour.name,
    'repeatCount': repeatCount,
    'eventContext': eventContext,
    'reporterReputationSnapshot': reporterReputationSnapshot,
    'socialContentUrl': socialContentUrl,
    'evidence': evidence.map((e) => e.toMap()).toList(),
    'requestContract': requestContract,
    'rewardItems': rewardItems.map((e) => e.toMap()).toList(),
    'status': status.name,
    'moderationNotes': moderationNotes,
    'moderatedByUid': moderatedByUid,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    if (submittedAt != null) 'submittedAt': Timestamp.fromDate(submittedAt!),
    if (moderatedAt != null) 'moderatedAt': Timestamp.fromDate(moderatedAt!),
  };

  factory ArcRaiderReport.fromMap(Map<String, dynamic> map) => ArcRaiderReport(
    id: '${map['id'] ?? ''}',
    reporterUid: '${map['reporterUid'] ?? ''}',
    targetUid: '${map['targetUid'] ?? ''}',
    targetDisplayName: '${map['targetDisplayName'] ?? ''}',
    targetGameIdentity: '${map['targetGameIdentity'] ?? ''}',
    category: _enumValue(
      ArcRaiderReportCategory.values,
      map['category'],
      ArcRaiderReportCategory.other,
    ),
    description: '${map['description'] ?? ''}',
    encounterContext: '${map['encounterContext'] ?? ''}',
    mapId: '${map['mapId'] ?? ''}',
    mapDisplayName: '${map['mapDisplayName'] ?? ''}',
    locationLabel: '${map['locationLabel'] ?? ''}',
    locationX: (map['locationX'] as num?)?.toDouble(),
    locationY: (map['locationY'] as num?)?.toDouble(),
    nearestPoiId: '${map['nearestPoiId'] ?? ''}',
    nearestPoiName: '${map['nearestPoiName'] ?? ''}',
    atExtraction: map['atExtraction'] == true,
    extractionId: '${map['extractionId'] ?? ''}',
    extractionName: '${map['extractionName'] ?? ''}',
    rattingSubtype: '${map['rattingSubtype'] ?? ''}',
    serverRegion: '${map['serverRegion'] ?? ''}',
    incidentAt: _date(map['incidentAt']),
    repeatBehaviour: _enumValue(
      ArcRaiderRepeatBehaviour.values,
      map['repeatBehaviour'],
      ArcRaiderRepeatBehaviour.no,
    ),
    repeatCount: (map['repeatCount'] as num?)?.toInt() ?? 1,
    eventContext: '${map['eventContext'] ?? ''}',
    reporterReputationSnapshot:
        (map['reporterReputationSnapshot'] as num?)?.toInt() ?? 0,
    socialContentUrl: '${map['socialContentUrl'] ?? ''}',
    evidence: (map['evidence'] is Iterable)
        ? (map['evidence'] as Iterable)
              .whereType<Map>()
              .map(
                (e) => ArcRaiderEvidence.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList(growable: false)
        : const [],
    requestContract: map['requestContract'] == true,
    rewardItems: (map['rewardItems'] is Iterable)
        ? (map['rewardItems'] as Iterable)
              .whereType<Map>()
              .map(
                (e) =>
                    ArcRaiderRewardItem.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList(growable: false)
        : const [],
    status: _enumValue(
      ArcRaiderReportStatus.values,
      map['status'],
      ArcRaiderReportStatus.draft,
    ),
    moderationNotes: '${map['moderationNotes'] ?? ''}',
    moderatedByUid: '${map['moderatedByUid'] ?? ''}',
    createdAt: _date(map['createdAt']),
    updatedAt: _date(map['updatedAt']),
    submittedAt: _date(map['submittedAt']),
    moderatedAt: _date(map['moderatedAt']),
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
    this.contractType = ArcRaiderContractType.open,
    this.rewardItems = const [],
    this.rewardPool = const [],
    this.rewardSummary = '',
    this.reputationReward = 10,
    this.participantCount = 0,
    this.evidenceRequirements =
        'Provide clear in-app evidence that identifies the encounter and outcome.',
    this.evidence = const [],
    this.resolution = '',
    this.moderationNotes = '',
    this.moderatedByUid = '',
    this.socialContentUrl = '',
    this.closedContractEntitlement = '',
    this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.evidenceSubmittedAt,
    this.resolvedAt,
    this.expiresAt,
  });

  final String id;
  final String reportId;
  final String targetUid;
  final String targetDisplayName;
  final String reporterUid;
  final String hunterUid;
  final ArcRaiderContractType contractType;
  final List<ArcRaiderRewardItem> rewardItems;
  final List<ArcRaiderRewardPoolEntry> rewardPool;
  final String rewardSummary;
  final String evidenceRequirements;
  final String resolution;
  final String moderationNotes;
  final String moderatedByUid;
  final String socialContentUrl;
  final String closedContractEntitlement;
  final int reputationReward;
  final int participantCount;
  final ArcRaiderContractStatus status;
  final List<ArcRaiderEvidence> evidence;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? evidenceSubmittedAt;
  final DateTime? resolvedAt;
  final DateTime? expiresAt;

  bool get isClosedContract => contractType == ArcRaiderContractType.closed;
  bool get hasRemainingRewards => rewardPool.isNotEmpty
      ? rewardPool.any((entry) => entry.quantityRemaining > 0)
      : rewardItems.any((item) => item.quantity > 0);
  bool get isExhausted => rewardPool.isNotEmpty
      ? rewardPool.every((entry) => entry.quantityRemaining <= 0)
      : rewardItems.every((item) => item.quantity <= 0);
  bool get isExpired =>
      expiresAt != null &&
      expiresAt!.isBefore(DateTime.now()) &&
      !{
        ArcRaiderContractStatus.completed,
        ArcRaiderContractStatus.cancelled,
        ArcRaiderContractStatus.rejected,
      }.contains(status);
  bool get isLive =>
      !{
        ArcRaiderContractStatus.completed,
        ArcRaiderContractStatus.cancelled,
        ArcRaiderContractStatus.rejected,
        ArcRaiderContractStatus.expired,
      }.contains(status) &&
      !isExpired &&
      hasRemainingRewards;
  bool get canAccept =>
      status == ArcRaiderContractStatus.available &&
      !isExpired &&
      hasRemainingRewards;

  ArcRaiderContract applyVerifiedRewardClaim({
    required String itemId,
    int quantity = 1,
  }) {
    final nextPool = rewardPool.isEmpty
        ? rewardItems
              .map(
                (item) => ArcRaiderRewardPoolEntry(
                  itemId: itemId,
                  name: item.name,
                  category: item.category,
                  quantityOffered: item.quantity,
                  quantityRemaining: item.quantity,
                  quantityClaimed: 0,
                ),
              )
              .toList(growable: false)
        : rewardPool
              .map(
                (entry) => entry.itemId == itemId
                    ? entry.withVerifiedClaim(quantity: quantity)
                    : entry,
              )
              .toList(growable: false);
    final nextStatus = nextPool.every((entry) => entry.quantityRemaining <= 0)
        ? ArcRaiderContractStatus.cancelled
        : status;
    return ArcRaiderContract(
      id: id,
      reportId: reportId,
      targetUid: targetUid,
      targetDisplayName: targetDisplayName,
      reporterUid: reporterUid,
      hunterUid: hunterUid,
      contractType: contractType,
      status: nextStatus,
      rewardItems: rewardItems,
      rewardPool: nextPool,
      rewardSummary: rewardSummary,
      reputationReward: reputationReward,
      participantCount: participantCount,
      evidenceRequirements: evidenceRequirements,
      evidence: evidence,
      resolution: resolution,
      moderationNotes: moderationNotes,
      moderatedByUid: moderatedByUid,
      socialContentUrl: socialContentUrl,
      closedContractEntitlement: closedContractEntitlement,
      createdAt: createdAt,
      updatedAt: updatedAt,
      acceptedAt: acceptedAt,
      evidenceSubmittedAt: evidenceSubmittedAt,
      resolvedAt: resolvedAt,
      expiresAt: expiresAt,
    );
  }

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

  static Duration maxDurationForType(ArcRaiderContractType type) =>
      type == ArcRaiderContractType.closed
      ? const Duration(days: 7)
      : const Duration(days: 14);

  static bool isValidClosedContractExpiry(
    DateTime? expiresAt,
    DateTime createdAt,
  ) {
    if (expiresAt == null) {
      return false;
    }
    final max = createdAt.add(const Duration(days: 7));
    return !expiresAt.isBefore(createdAt) &&
        !expiresAt.isAfter(max.add(const Duration(minutes: 1)));
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'reportId': reportId,
    'targetUid': targetUid,
    'targetDisplayName': targetDisplayName,
    'reporterUid': reporterUid,
    'hunterUid': hunterUid,
    'contractType': contractType.name,
    'status': status.name,
    'rewardItems': rewardItems.map((e) => e.toMap()).toList(),
    'rewardPool': rewardPool.map((e) => e.toMap()).toList(),
    'rewardSummary': rewardSummary,
    'reputationReward': reputationReward,
    'participantCount': participantCount,
    'evidenceRequirements': evidenceRequirements,
    'evidence': evidence.map((e) => e.toMap()).toList(),
    'resolution': resolution,
    'moderationNotes': moderationNotes,
    'moderatedByUid': moderatedByUid,
    'socialContentUrl': socialContentUrl,
    'closedContractEntitlement': closedContractEntitlement,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
    if (evidenceSubmittedAt != null)
      'evidenceSubmittedAt': Timestamp.fromDate(evidenceSubmittedAt!),
    if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
    if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
  };

  factory ArcRaiderContract.fromMap(Map<String, dynamic> map) {
    final rewardItems = (map['rewardItems'] is Iterable)
        ? (map['rewardItems'] as Iterable)
              .whereType<Map>()
              .map(
                (e) =>
                    ArcRaiderRewardItem.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList(growable: false)
        : const <ArcRaiderRewardItem>[];
    final rewardPool = (map['rewardPool'] is Iterable)
        ? (map['rewardPool'] as Iterable)
              .whereType<Map>()
              .map(
                (e) => ArcRaiderRewardPoolEntry.fromMap(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(growable: false)
        : rewardItems
              .map(
                (item) => ArcRaiderRewardPoolEntry(
                  itemId: item.itemId,
                  name: item.name,
                  category: item.category,
                  quantityOffered: item.quantity,
                  quantityRemaining: item.quantity,
                  quantityClaimed: 0,
                ),
              )
              .toList(growable: false);
    return ArcRaiderContract(
      id: '${map['id'] ?? ''}',
      reportId: '${map['reportId'] ?? ''}',
      targetUid: '${map['targetUid'] ?? ''}',
      targetDisplayName: '${map['targetDisplayName'] ?? ''}',
      reporterUid: '${map['reporterUid'] ?? ''}',
      hunterUid: '${map['hunterUid'] ?? ''}',
      contractType: _enumValue(
        ArcRaiderContractType.values,
        map['contractType'],
        ArcRaiderContractType.open,
      ),
      status: _enumValue(
        ArcRaiderContractStatus.values,
        map['status'],
        ArcRaiderContractStatus.available,
      ),
      rewardItems: rewardItems,
      rewardPool: rewardPool,
      rewardSummary: '${map['rewardSummary'] ?? ''}',
      reputationReward: (map['reputationReward'] as num?)?.toInt() ?? 10,
      participantCount:
          (map['participantCount'] as num?)?.toInt() ??
          (map['activeParticipantCount'] as num?)?.toInt() ??
          0,
      evidenceRequirements: '${map['evidenceRequirements'] ?? ''}',
      evidence: (map['evidence'] is Iterable)
          ? (map['evidence'] as Iterable)
                .whereType<Map>()
                .map(
                  (e) =>
                      ArcRaiderEvidence.fromMap(Map<String, dynamic>.from(e)),
                )
                .toList(growable: false)
          : const [],
      resolution: '${map['resolution'] ?? ''}',
      moderationNotes: '${map['moderationNotes'] ?? ''}',
      moderatedByUid: '${map['moderatedByUid'] ?? ''}',
      socialContentUrl: '${map['socialContentUrl'] ?? ''}',
      closedContractEntitlement: '${map['closedContractEntitlement'] ?? ''}',
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
      acceptedAt: _date(map['acceptedAt']),
      evidenceSubmittedAt: _date(map['evidenceSubmittedAt']),
      resolvedAt: _date(map['resolvedAt']),
      expiresAt: _date(map['expiresAt']),
    );
  }
}
