import 'package:cloud_firestore/cloud_firestore.dart';

enum ArcBlueprintWatchType {
  blueprint,
  rider,
  favouriteRiderListings,
  previousTradePartner,
  previousBlueprintOffer,
}

enum ArcBlueprintWatchNotificationPreference {
  immediate,
  duringAvailabilityOnly,
  nextLogin,
  digest,
  muted,
  favouriteRidersOnly,
}

class ArcBlueprintWatch {
  const ArcBlueprintWatch({
    required this.id,
    required this.ownerUid,
    required this.type,
    this.blueprintId = '',
    this.blueprintDisplayName = '',
    this.objectiveId = '',
    this.riderUid = '',
    this.sourceListingId = '',
    this.preferredAcquisitionMethods = const <String>[],
    this.minimumMatchScore = 60,
    this.favouriteRidersOnly = false,
    this.notificationsEnabled = true,
    this.notificationPreference =
        ArcBlueprintWatchNotificationPreference.duringAvailabilityOnly,
    this.active = true,
    this.linkedListingId = '',
    this.linkedOpportunityId = '',
    this.lastMatchedAt,
    this.lastNotifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final ArcBlueprintWatchType type;
  final String blueprintId;
  final String blueprintDisplayName;
  final String objectiveId;
  final String riderUid;
  final String sourceListingId;
  final List<String> preferredAcquisitionMethods;
  final int minimumMatchScore;
  final bool favouriteRidersOnly;
  final bool notificationsEnabled;
  final ArcBlueprintWatchNotificationPreference notificationPreference;
  final bool active;
  final String linkedListingId;
  final String linkedOpportunityId;
  final DateTime? lastMatchedAt;
  final DateTime? lastNotifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static String idFor({
    required String ownerUid,
    required String blueprintId,
    ArcBlueprintWatchType type = ArcBlueprintWatchType.blueprint,
    String objectiveId = '',
  }) {
    final owner = _normalizeId(ownerUid);
    final blueprint = _normalizeId(blueprintId);
    final objective = _normalizeId(objectiveId);
    final objectivePart = objective.isEmpty ? 'default' : objective;
    return [
      owner,
      type.name,
      blueprint,
      objectivePart,
    ].where((part) => part.isNotEmpty).join('__');
  }

  bool get isPaused => !active;
  bool get hasMatch =>
      linkedListingId.trim().isNotEmpty ||
      linkedOpportunityId.trim().isNotEmpty ||
      lastMatchedAt != null;
  bool get shouldNotify =>
      notificationsEnabled &&
      notificationPreference != ArcBlueprintWatchNotificationPreference.muted;

  String get displayName =>
      blueprintDisplayName.trim().isEmpty ? blueprintId : blueprintDisplayName;

  String get stateLabel {
    if (!active) return 'Paused';
    if (hasMatch) return 'Match found';
    return 'Active';
  }

  ArcBlueprintWatch copyWith({
    String? id,
    String? ownerUid,
    ArcBlueprintWatchType? type,
    String? blueprintId,
    String? blueprintDisplayName,
    String? objectiveId,
    String? riderUid,
    String? sourceListingId,
    List<String>? preferredAcquisitionMethods,
    int? minimumMatchScore,
    bool? favouriteRidersOnly,
    bool? notificationsEnabled,
    ArcBlueprintWatchNotificationPreference? notificationPreference,
    bool? active,
    String? linkedListingId,
    String? linkedOpportunityId,
    DateTime? lastMatchedAt,
    DateTime? lastNotifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearLinkedListing = false,
    bool clearLinkedOpportunity = false,
    bool clearLastMatchedAt = false,
    bool clearLastNotifiedAt = false,
  }) {
    return ArcBlueprintWatch(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      type: type ?? this.type,
      blueprintId: blueprintId ?? this.blueprintId,
      blueprintDisplayName: blueprintDisplayName ?? this.blueprintDisplayName,
      objectiveId: objectiveId ?? this.objectiveId,
      riderUid: riderUid ?? this.riderUid,
      sourceListingId: sourceListingId ?? this.sourceListingId,
      preferredAcquisitionMethods:
          preferredAcquisitionMethods ?? this.preferredAcquisitionMethods,
      minimumMatchScore: (minimumMatchScore ?? this.minimumMatchScore)
          .clamp(0, 100)
          .toInt(),
      favouriteRidersOnly: favouriteRidersOnly ?? this.favouriteRidersOnly,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationPreference:
          notificationPreference ?? this.notificationPreference,
      active: active ?? this.active,
      linkedListingId: clearLinkedListing
          ? ''
          : linkedListingId ?? this.linkedListingId,
      linkedOpportunityId: clearLinkedOpportunity
          ? ''
          : linkedOpportunityId ?? this.linkedOpportunityId,
      lastMatchedAt: clearLastMatchedAt
          ? null
          : lastMatchedAt ?? this.lastMatchedAt,
      lastNotifiedAt: clearLastNotifiedAt
          ? null
          : lastNotifiedAt ?? this.lastNotifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerUid': ownerUid,
      'type': type.name,
      'blueprintId': blueprintId,
      'blueprintDisplayName': blueprintDisplayName,
      'objectiveId': objectiveId,
      'riderUid': riderUid,
      'sourceListingId': sourceListingId,
      'preferredAcquisitionMethods': preferredAcquisitionMethods,
      'minimumMatchScore': minimumMatchScore.clamp(0, 100).toInt(),
      'favouriteRidersOnly': favouriteRidersOnly,
      'notificationsEnabled': notificationsEnabled,
      'notificationPreference': notificationPreference.name,
      'active': active,
      'linkedListingId': linkedListingId,
      'linkedOpportunityId': linkedOpportunityId,
      'lastMatchedAt': lastMatchedAt == null
          ? null
          : Timestamp.fromDate(lastMatchedAt!),
      'lastNotifiedAt': lastNotifiedAt == null
          ? null
          : Timestamp.fromDate(lastNotifiedAt!),
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory ArcBlueprintWatch.fromMap(Map<String, dynamic> map) {
    return ArcBlueprintWatch(
      id: _readString(map['id']),
      ownerUid: _readString(map['ownerUid']),
      type: ArcBlueprintWatchType.values.firstWhere(
        (value) => value.name == _readString(map['type']),
        orElse: () => ArcBlueprintWatchType.blueprint,
      ),
      blueprintId: _readString(map['blueprintId']),
      blueprintDisplayName: _readString(map['blueprintDisplayName']),
      objectiveId: _readString(map['objectiveId']),
      riderUid: _readString(map['riderUid']),
      sourceListingId: _readString(map['sourceListingId']),
      preferredAcquisitionMethods: _readStringList(
        map['preferredAcquisitionMethods'],
      ),
      minimumMatchScore: _readInt(
        map['minimumMatchScore'],
        60,
      ).clamp(0, 100).toInt(),
      favouriteRidersOnly: _readBool(map['favouriteRidersOnly']),
      notificationsEnabled: _readBool(map['notificationsEnabled'], true),
      notificationPreference: ArcBlueprintWatchNotificationPreference.values
          .firstWhere(
            (value) => value.name == _readString(map['notificationPreference']),
            orElse: () =>
                ArcBlueprintWatchNotificationPreference.duringAvailabilityOnly,
          ),
      active: map['active'] != false,
      linkedListingId: _readString(map['linkedListingId']),
      linkedOpportunityId: _readString(map['linkedOpportunityId']),
      lastMatchedAt: _readDate(map['lastMatchedAt']),
      lastNotifiedAt: _readDate(map['lastNotifiedAt']),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static String _readString(dynamic value) => value?.toString().trim() ?? '';

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    final text = _readString(value);
    if (text.isEmpty) return const <String>[];
    return text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static int _readInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _readBool(dynamic value, [bool fallback = false]) {
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    return fallback;
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
