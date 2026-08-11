import 'package:cloud_firestore/cloud_firestore.dart';

enum ArcFavouriteNotificationPreference {
  immediate,
  duringAvailabilityOnly,
  nextLogin,
  digest,
  muted,
  favouriteRidersOnly,
}

class ArcFavouriteRider {
  const ArcFavouriteRider({
    required this.id,
    required this.ownerUid,
    required this.riderUid,
    this.privateNote = '',
    this.tags = const <String>[],
    this.notificationPreference =
        ArcFavouriteNotificationPreference.duringAvailabilityOnly,
    this.completedTrades = 0,
    this.squadSessions = 0,
    this.previousBlueprintOffer = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String riderUid;
  final String privateNote;
  final List<String> tags;
  final ArcFavouriteNotificationPreference notificationPreference;
  final int completedTrades;
  final int squadSessions;
  final bool previousBlueprintOffer;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static String idFor(String ownerUid, String riderUid) =>
      '${ownerUid.trim()}_${riderUid.trim()}';

  String get relationshipSummary {
    final parts = <String>[
      if (completedTrades > 0) '$completedTrades completed trades',
      if (squadSessions > 0) '$squadSessions squad sessions',
      if (previousBlueprintOffer) 'Previous blueprint offer',
    ];
    return parts.isEmpty ? 'Favourite Raider' : parts.join(' - ');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerUid': ownerUid,
      'riderUid': riderUid,
      'privateNote': privateNote,
      'tags': tags,
      'notificationPreference': notificationPreference.name,
      'completedTrades': completedTrades,
      'squadSessions': squadSessions,
      'previousBlueprintOffer': previousBlueprintOffer,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory ArcFavouriteRider.fromMap(Map<String, dynamic> map) {
    final ownerUid = _readString(map['ownerUid']);
    final riderUid = _readString(map['riderUid']);
    return ArcFavouriteRider(
      id: _readString(map['id'], idFor(ownerUid, riderUid)),
      ownerUid: ownerUid,
      riderUid: riderUid,
      privateNote: _readString(map['privateNote']),
      tags: _readStringList(map['tags']),
      notificationPreference: ArcFavouriteNotificationPreference.values
          .firstWhere(
            (value) => value.name == _readString(map['notificationPreference']),
            orElse: () =>
                ArcFavouriteNotificationPreference.duringAvailabilityOnly,
          ),
      completedTrades: _readInt(map['completedTrades']),
      squadSessions: _readInt(map['squadSessions']),
      previousBlueprintOffer: _readBool(map['previousBlueprintOffer']),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static String _readString(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

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

  static List<String> _readStringList(dynamic value) {
    if (value is Iterable) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }
}
