import 'package:cloud_firestore/cloud_firestore.dart';

class ArcTradePreferences {
  const ArcTradePreferences({
    required this.ownerUid,
    this.fastTrades = false,
    this.bestOffer = false,
    this.fairTrades = true,
    this.communityFirst = false,
    this.giftExtras = false,
    this.favouriteRidersFirst = false,
    this.friendsFirst = false,
    this.fixedRequests = false,
    this.flexibleOffers = true,
    this.noUnsolicitedMessages = false,
    this.maxActiveOffers = 5,
    this.createdAt,
    this.updatedAt,
  });

  final String ownerUid;
  final bool fastTrades;
  final bool bestOffer;
  final bool fairTrades;
  final bool communityFirst;
  final bool giftExtras;
  final bool favouriteRidersFirst;
  final bool friendsFirst;
  final bool fixedRequests;
  final bool flexibleOffers;
  final bool noUnsolicitedMessages;
  final int maxActiveOffers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static ArcTradePreferences empty(String ownerUid) =>
      ArcTradePreferences(ownerUid: ownerUid);

  List<String> get rankingTags {
    return <String>[
      if (fastTrades) 'Fast trades',
      if (bestOffer) 'Best offer',
      if (fairTrades) 'Fair trades',
      if (communityFirst) 'Community first',
      if (giftExtras) 'Gift extras',
      if (favouriteRidersFirst) 'Favourite Raiders first',
      if (friendsFirst) 'Friends first',
      if (fixedRequests) 'Fixed requests',
      if (flexibleOffers) 'Flexible offers',
      if (noUnsolicitedMessages) 'No unsolicited messages',
    ];
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUid': ownerUid,
      'fastTrades': fastTrades,
      'bestOffer': bestOffer,
      'fairTrades': fairTrades,
      'communityFirst': communityFirst,
      'giftExtras': giftExtras,
      'favouriteRidersFirst': favouriteRidersFirst,
      'friendsFirst': friendsFirst,
      'fixedRequests': fixedRequests,
      'flexibleOffers': flexibleOffers,
      'noUnsolicitedMessages': noUnsolicitedMessages,
      'maxActiveOffers': maxActiveOffers,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory ArcTradePreferences.fromMap(Map<String, dynamic> map) {
    return ArcTradePreferences(
      ownerUid: _readString(map['ownerUid']),
      fastTrades: _readBool(map['fastTrades']),
      bestOffer: _readBool(map['bestOffer']),
      fairTrades: _readBool(map['fairTrades'], true),
      communityFirst: _readBool(map['communityFirst']),
      giftExtras: _readBool(map['giftExtras']),
      favouriteRidersFirst: _readBool(map['favouriteRidersFirst']),
      friendsFirst: _readBool(map['friendsFirst']),
      fixedRequests: _readBool(map['fixedRequests']),
      flexibleOffers: _readBool(map['flexibleOffers'], true),
      noUnsolicitedMessages: _readBool(map['noUnsolicitedMessages']),
      maxActiveOffers: _readInt(map['maxActiveOffers'], 5).clamp(1, 25).toInt(),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static String _readString(dynamic value) => value?.toString().trim() ?? '';

  static bool _readBool(dynamic value, [bool fallback = false]) {
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    return fallback;
  }

  static int _readInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
