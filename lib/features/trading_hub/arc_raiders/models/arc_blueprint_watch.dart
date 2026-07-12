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
    this.riderUid = '',
    this.sourceListingId = '',
    this.notificationPreference =
        ArcBlueprintWatchNotificationPreference.duringAvailabilityOnly,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final ArcBlueprintWatchType type;
  final String blueprintId;
  final String riderUid;
  final String sourceListingId;
  final ArcBlueprintWatchNotificationPreference notificationPreference;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerUid': ownerUid,
      'type': type.name,
      'blueprintId': blueprintId,
      'riderUid': riderUid,
      'sourceListingId': sourceListingId,
      'notificationPreference': notificationPreference.name,
      'active': active,
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
      riderUid: _readString(map['riderUid']),
      sourceListingId: _readString(map['sourceListingId']),
      notificationPreference: ArcBlueprintWatchNotificationPreference.values
          .firstWhere(
            (value) => value.name == _readString(map['notificationPreference']),
            orElse: () =>
                ArcBlueprintWatchNotificationPreference.duringAvailabilityOnly,
          ),
      active: map['active'] != false,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static String _readString(dynamic value) => value?.toString().trim() ?? '';

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
