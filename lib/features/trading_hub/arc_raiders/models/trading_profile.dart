import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/trading_listing.dart';

class TradingProfile {
  final String uid;
  final String displayName;
  final String embarkId;
  final String region;
  final String profileImageUrl;
  final String gamerTag;
  final String preferredPlatform;
  final int completedTrades;
  final int noShows;
  final int betrayalFlags;
  final int cancelledTrades;
  final int successfulTradeStreak;
  final int totalOffersSent;
  final int totalOffersReceived;
  final bool foundingTrader;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TradingProfile({
    required this.uid,
    required this.displayName,
    required this.embarkId,
    required this.region,
    required this.profileImageUrl,
    required this.gamerTag,
    required this.preferredPlatform,
    required this.completedTrades,
    required this.noShows,
    required this.betrayalFlags,
    required this.cancelledTrades,
    required this.successfulTradeStreak,
    required this.totalOffersSent,
    required this.totalOffersReceived,
    required this.foundingTrader,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TradingProfile.empty(String uid) {
    return TradingProfile(
      uid: uid,
      displayName: 'New Trader',
      embarkId: '',
      region: 'Flexible',
      profileImageUrl: '',
      gamerTag: '',
      preferredPlatform: '',
      completedTrades: 0,
      noShows: 0,
      betrayalFlags: 0,
      cancelledTrades: 0,
      successfulTradeStreak: 0,
      totalOffersSent: 0,
      totalOffersReceived: 0,
      foundingTrader: false,
      createdAt: null,
      updatedAt: null,
    );
  }

  TradingRiskLevel get riskLevel {
    if (betrayalFlags >= 2 || noShows >= 2) {
      return TradingRiskLevel.high;
    }
    if (completedTrades >= 3 && betrayalFlags == 0 && noShows == 0) {
      return TradingRiskLevel.low;
    }
    return TradingRiskLevel.medium;
  }

  String get riskLabel {
    switch (riskLevel) {
      case TradingRiskLevel.low:
        return 'Low Risk';
      case TradingRiskLevel.medium:
        return 'Moderate Risk';
      case TradingRiskLevel.high:
        return 'Caution';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'embarkId': embarkId,
      'region': region,
      'profileImageUrl': profileImageUrl,
      'gamerTag': gamerTag,
      'preferredPlatform': preferredPlatform,
      'completedTrades': completedTrades,
      'noShows': noShows,
      'betrayalFlags': betrayalFlags,
      'cancelledTrades': cancelledTrades,
      'successfulTradeStreak': successfulTradeStreak,
      'totalOffersSent': totalOffersSent,
      'totalOffersReceived': totalOffersReceived,
      'foundingTrader': foundingTrader,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory TradingProfile.fromMap(Map<String, dynamic> map) {
    return TradingProfile(
      uid: (map['uid'] ?? '') as String,
      displayName: (map['displayName'] ?? 'New Trader') as String,
      embarkId: (map['embarkId'] ?? '') as String,
      region: (map['region'] ?? 'Flexible') as String,
      profileImageUrl: (map['profileImageUrl'] ?? '') as String,
      gamerTag: (map['gamerTag'] ?? '') as String,
      preferredPlatform: (map['preferredPlatform'] ?? '') as String,
      completedTrades: (map['completedTrades'] ?? 0) as int,
      noShows: (map['noShows'] ?? 0) as int,
      betrayalFlags: (map['betrayalFlags'] ?? 0) as int,
      cancelledTrades: (map['cancelledTrades'] ?? 0) as int,
      successfulTradeStreak: (map['successfulTradeStreak'] ?? 0) as int,
      totalOffersSent: (map['totalOffersSent'] ?? 0) as int,
      totalOffersReceived: (map['totalOffersReceived'] ?? 0) as int,
      foundingTrader: (map['foundingTrader'] ?? false) as bool,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  TradingProfile copyWith({
    String? uid,
    String? displayName,
    String? embarkId,
    String? region,
    String? profileImageUrl,
    String? gamerTag,
    String? preferredPlatform,
    int? completedTrades,
    int? noShows,
    int? betrayalFlags,
    int? cancelledTrades,
    int? successfulTradeStreak,
    int? totalOffersSent,
    int? totalOffersReceived,
    bool? foundingTrader,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TradingProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      embarkId: embarkId ?? this.embarkId,
      region: region ?? this.region,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      gamerTag: gamerTag ?? this.gamerTag,
      preferredPlatform: preferredPlatform ?? this.preferredPlatform,
      completedTrades: completedTrades ?? this.completedTrades,
      noShows: noShows ?? this.noShows,
      betrayalFlags: betrayalFlags ?? this.betrayalFlags,
      cancelledTrades: cancelledTrades ?? this.cancelledTrades,
      successfulTradeStreak:
          successfulTradeStreak ?? this.successfulTradeStreak,
      totalOffersSent: totalOffersSent ?? this.totalOffersSent,
      totalOffersReceived: totalOffersReceived ?? this.totalOffersReceived,
      foundingTrader: foundingTrader ?? this.foundingTrader,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
