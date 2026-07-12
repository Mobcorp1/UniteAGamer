import 'package:cloud_firestore/cloud_firestore.dart';

enum ArcDuplicateReleasePolicy {
  immediatelyAfterCompletion,
  afterThirtyMinutes,
  afterTwoHours,
  nextLogin,
  askBeforeRelisting,
  neverAutomaticallyRelist,
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
    this.createdAt,
    this.releaseAt,
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
  final DateTime? createdAt;
  final DateTime? releaseAt;
  final DateTime? updatedAt;

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

  bool shouldReleaseAt(DateTime now) {
    final target = releaseAt;
    if (publiclyReleased || target == null) return false;
    return !target.isAfter(now);
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
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'releaseAt': releaseAt == null ? null : Timestamp.fromDate(releaseAt!),
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
      createdAt: _readDate(map['createdAt']),
      releaseAt: _readDate(map['releaseAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static String _readString(dynamic value) => value?.toString().trim() ?? '';

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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
}
