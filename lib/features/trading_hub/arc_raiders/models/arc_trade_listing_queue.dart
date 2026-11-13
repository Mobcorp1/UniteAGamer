import 'package:cloud_firestore/cloud_firestore.dart';

enum ArcDuplicateReleasePolicy {
  immediatelyAfterCompletion,
  afterThirtyMinutes,
  afterTwoHours,
  nextLogin,
  askBeforeRelisting,
  neverAutomaticallyRelist,
}

enum ArcTradeListingQueueStatus {
  active,
  paused,
  blocked,
  completed,
  cancelled,
}

class ArcTradeListingQueueItem {
  const ArcTradeListingQueueItem({
    required this.id,
    required this.ownerUid,
    required this.blueprintId,
    required this.blueprintName,
    required this.sourceListingId,
    required this.releasePolicy,
    this.position = 0,
    this.publiclyReleased = false,
    this.status = ArcTradeListingQueueStatus.active,
    this.activeListingId = '',
    this.lastReleasedListingId = '',
    this.totalQueued = 1,
    this.releasedQuantity = 0,
    this.publicQuantity = 1,
    this.blockedReason = '',
    this.autoReleaseEnabled = false,
    this.createdAt,
    this.releaseAt,
    this.lastReleasedAt,
    this.completedAt,
    this.cancelledAt,
    this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String blueprintId;
  final String blueprintName;
  final String sourceListingId;
  final ArcDuplicateReleasePolicy releasePolicy;
  final int position;
  final bool publiclyReleased;
  final ArcTradeListingQueueStatus status;
  final String activeListingId;
  final String lastReleasedListingId;
  final int totalQueued;
  final int releasedQuantity;
  final int publicQuantity;
  final String blockedReason;
  final bool autoReleaseEnabled;
  final DateTime? createdAt;
  final DateTime? releaseAt;
  final DateTime? lastReleasedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? updatedAt;

  static String idFor({
    required String ownerUid,
    required String sourceListingId,
  }) {
    final owner = _normalizeId(ownerUid);
    final listing = _normalizeId(sourceListingId);
    return [
      owner,
      'listing-queue',
      listing,
    ].where((part) => part.isNotEmpty).join('__');
  }

  factory ArcTradeListingQueueItem.createForListing({
    required String id,
    required String ownerUid,
    required String blueprintId,
    required String blueprintName,
    required String sourceListingId,
    required ArcDuplicateReleasePolicy releasePolicy,
    required int queuedQuantity,
    DateTime? now,
  }) {
    final safeQuantity = queuedQuantity < 0 ? 0 : queuedQuantity;
    final created = now ?? DateTime.now();
    return ArcTradeListingQueueItem(
      id: id,
      ownerUid: ownerUid,
      blueprintId: blueprintId,
      blueprintName: blueprintName,
      sourceListingId: sourceListingId,
      activeListingId: sourceListingId,
      releasePolicy: releasePolicy,
      totalQueued: safeQuantity,
      releasedQuantity: 0,
      publicQuantity: 1,
      autoReleaseEnabled:
          releasePolicy != ArcDuplicateReleasePolicy.askBeforeRelisting &&
          releasePolicy != ArcDuplicateReleasePolicy.neverAutomaticallyRelist,
      createdAt: created,
      updatedAt: created,
    );
  }

  DateTime? nextReleaseAt(DateTime completedAt) {
    switch (releasePolicy) {
      case ArcDuplicateReleasePolicy.immediatelyAfterCompletion:
        return completedAt;
      case ArcDuplicateReleasePolicy.afterThirtyMinutes:
        return completedAt.add(const Duration(minutes: 30));
      case ArcDuplicateReleasePolicy.afterTwoHours:
        return completedAt.add(const Duration(hours: 2));
      case ArcDuplicateReleasePolicy.nextLogin:
      case ArcDuplicateReleasePolicy.askBeforeRelisting:
      case ArcDuplicateReleasePolicy.neverAutomaticallyRelist:
        return null;
    }
  }

  int get remainingQuantity =>
      (totalQueued - releasedQuantity).clamp(0, totalQueued).toInt();
  bool get isPaused => status == ArcTradeListingQueueStatus.paused;
  bool get isBlocked => status == ArcTradeListingQueueStatus.blocked;
  bool get isTerminal =>
      status == ArcTradeListingQueueStatus.completed ||
      status == ArcTradeListingQueueStatus.cancelled;
  bool get hasRemaining => remainingQuantity > 0;
  bool get canManuallyRelease =>
      !isPaused &&
      !isTerminal &&
      hasRemaining &&
      releasePolicy != ArcDuplicateReleasePolicy.neverAutomaticallyRelist;

  String get statusLabel {
    switch (status) {
      case ArcTradeListingQueueStatus.active:
        return hasRemaining ? 'Active' : 'Completed';
      case ArcTradeListingQueueStatus.paused:
        return 'Paused';
      case ArcTradeListingQueueStatus.blocked:
        return 'Blocked';
      case ArcTradeListingQueueStatus.completed:
        return 'Completed';
      case ArcTradeListingQueueStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get releasePolicyLabel {
    switch (releasePolicy) {
      case ArcDuplicateReleasePolicy.immediatelyAfterCompletion:
        return 'Release immediately after close';
      case ArcDuplicateReleasePolicy.afterThirtyMinutes:
        return 'Release after 30 minutes';
      case ArcDuplicateReleasePolicy.afterTwoHours:
        return 'Release after 2 hours';
      case ArcDuplicateReleasePolicy.nextLogin:
        return 'Release next login';
      case ArcDuplicateReleasePolicy.askBeforeRelisting:
        return 'Manual release only';
      case ArcDuplicateReleasePolicy.neverAutomaticallyRelist:
        return 'Do not relist automatically';
    }
  }

  bool shouldReleaseAt(DateTime now) {
    final target = releaseAt;
    if (!canManuallyRelease || publiclyReleased || target == null) return false;
    return !target.isAfter(now);
  }

  ArcTradeListingQueueItem copyWith({
    String? id,
    String? ownerUid,
    String? blueprintId,
    String? blueprintName,
    String? sourceListingId,
    ArcDuplicateReleasePolicy? releasePolicy,
    int? position,
    bool? publiclyReleased,
    ArcTradeListingQueueStatus? status,
    String? activeListingId,
    String? lastReleasedListingId,
    int? totalQueued,
    int? releasedQuantity,
    int? publicQuantity,
    String? blockedReason,
    bool? autoReleaseEnabled,
    DateTime? createdAt,
    DateTime? releaseAt,
    DateTime? lastReleasedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? updatedAt,
    bool clearReleaseAt = false,
    bool clearBlockedReason = false,
    bool clearActiveListingId = false,
  }) {
    final nextTotal = (totalQueued ?? this.totalQueued).clamp(0, 999).toInt();
    final nextReleased = (releasedQuantity ?? this.releasedQuantity)
        .clamp(0, nextTotal)
        .toInt();
    return ArcTradeListingQueueItem(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      blueprintId: blueprintId ?? this.blueprintId,
      blueprintName: blueprintName ?? this.blueprintName,
      sourceListingId: sourceListingId ?? this.sourceListingId,
      releasePolicy: releasePolicy ?? this.releasePolicy,
      position: position ?? this.position,
      publiclyReleased: publiclyReleased ?? this.publiclyReleased,
      status: status ?? this.status,
      activeListingId: clearActiveListingId
          ? ''
          : activeListingId ?? this.activeListingId,
      lastReleasedListingId:
          lastReleasedListingId ?? this.lastReleasedListingId,
      totalQueued: nextTotal,
      releasedQuantity: nextReleased,
      publicQuantity: (publicQuantity ?? this.publicQuantity)
          .clamp(1, 1)
          .toInt(),
      blockedReason: clearBlockedReason
          ? ''
          : blockedReason ?? this.blockedReason,
      autoReleaseEnabled: autoReleaseEnabled ?? this.autoReleaseEnabled,
      createdAt: createdAt ?? this.createdAt,
      releaseAt: clearReleaseAt ? null : releaseAt ?? this.releaseAt,
      lastReleasedAt: lastReleasedAt ?? this.lastReleasedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerUid': ownerUid,
      'blueprintId': blueprintId,
      'blueprintName': blueprintName,
      'sourceListingId': sourceListingId,
      'releasePolicy': releasePolicy.name,
      'position': position,
      'publiclyReleased': publiclyReleased,
      'status': status.name,
      'activeListingId': activeListingId,
      'lastReleasedListingId': lastReleasedListingId,
      'totalQueued': totalQueued,
      'releasedQuantity': releasedQuantity,
      'remainingQuantity': remainingQuantity,
      'publicQuantity': publicQuantity,
      'blockedReason': blockedReason,
      'autoReleaseEnabled': autoReleaseEnabled,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'releaseAt': releaseAt == null ? null : Timestamp.fromDate(releaseAt!),
      'lastReleasedAt': lastReleasedAt == null
          ? null
          : Timestamp.fromDate(lastReleasedAt!),
      'completedAt': completedAt == null
          ? null
          : Timestamp.fromDate(completedAt!),
      'cancelledAt': cancelledAt == null
          ? null
          : Timestamp.fromDate(cancelledAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory ArcTradeListingQueueItem.fromMap(Map<String, dynamic> map) {
    return ArcTradeListingQueueItem(
      id: _readString(map['id']),
      ownerUid: _readString(map['ownerUid']),
      blueprintId: _readString(map['blueprintId']),
      blueprintName: _readString(map['blueprintName']),
      sourceListingId: _readString(map['sourceListingId']),
      releasePolicy: ArcDuplicateReleasePolicy.values.firstWhere(
        (value) => value.name == _readString(map['releasePolicy']),
        orElse: () => ArcDuplicateReleasePolicy.askBeforeRelisting,
      ),
      position: _readInt(map['position']),
      publiclyReleased: _readBool(map['publiclyReleased']),
      status: ArcTradeListingQueueStatus.values.firstWhere(
        (value) => value.name == _readString(map['status']),
        orElse: () => ArcTradeListingQueueStatus.active,
      ),
      activeListingId: _readString(map['activeListingId']).isEmpty
          ? _readString(map['sourceListingId'])
          : _readString(map['activeListingId']),
      lastReleasedListingId: _readString(map['lastReleasedListingId']),
      totalQueued: _readInt(map['totalQueued'], 1).clamp(0, 999).toInt(),
      releasedQuantity: _readInt(map['releasedQuantity']).clamp(0, 999).toInt(),
      publicQuantity: _readInt(map['publicQuantity'], 1).clamp(1, 1).toInt(),
      blockedReason: _readString(map['blockedReason']),
      autoReleaseEnabled: _readBool(map['autoReleaseEnabled']),
      createdAt: _readDate(map['createdAt']),
      releaseAt: _readDate(map['releaseAt']),
      lastReleasedAt: _readDate(map['lastReleasedAt']),
      completedAt: _readDate(map['completedAt']),
      cancelledAt: _readDate(map['cancelledAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static String _readString(dynamic value) => value?.toString().trim() ?? '';

  static int _readInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().trim().toLowerCase() == 'true';
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _normalizeId(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}
