class ArcTraderSearchResult {
  final String userId;
  final String uagId;
  final String uagName;
  final String region;
  final String platform;
  final bool visibleInSearch;
  final bool isAway;
  final int openListingsCount;
  final int matchingOfferCount;
  final String availabilitySummary;

  const ArcTraderSearchResult({
    required this.userId,
    required this.uagId,
    required this.uagName,
    required this.region,
    required this.platform,
    required this.visibleInSearch,
    required this.isAway,
    required this.openListingsCount,
    required this.matchingOfferCount,
    required this.availabilitySummary,
  });

  factory ArcTraderSearchResult.fromMap(Map<String, dynamic> map) {
    return ArcTraderSearchResult(
      userId: (map['userId'] ?? '') as String,
      uagId: (map['uagId'] ?? '') as String,
      uagName: (map['uagName'] ?? '') as String,
      region: (map['region'] ?? '') as String,
      platform: (map['platform'] ?? '') as String,
      visibleInSearch: (map['visibleInSearch'] ?? true) as bool,
      isAway: (map['isAway'] ?? false) as bool,
      openListingsCount: (map['openListingsCount'] ?? 0) as int,
      matchingOfferCount: (map['matchingOfferCount'] ?? 0) as int,
      availabilitySummary: (map['availabilitySummary'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'uagId': uagId,
      'uagName': uagName,
      'region': region,
      'platform': platform,
      'visibleInSearch': visibleInSearch,
      'isAway': isAway,
      'openListingsCount': openListingsCount,
      'matchingOfferCount': matchingOfferCount,
      'availabilitySummary': availabilitySummary,
    };
  }
}
