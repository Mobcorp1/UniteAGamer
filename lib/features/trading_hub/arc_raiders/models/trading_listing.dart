import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TradingRiskLevel {
  low,
  medium,
  high,
}

enum TradingListingType {
  specificWant,
  openToOffers,
}

class TradingListing {
  final String id;
  final String ownerUid;
  final String traderName;
  final String gamerTag;
  final String preferredPlatform;
  final String title;
  final String offeredItem;
  final String wantedText;
  final List<String> offeredBlueprintNames;
  final List<String> wantedBlueprintNames;
  final List<String> offeredAssetNames;
  final List<String> wantedAssetNames;
  final TradingListingType listingType;
  final TradingRiskLevel riskLevel;
  final int completedTrades;
  final int noShows;
  final int betrayalFlags;
  final String region;
  final String playWindow;
  final int smallBundles;
  final int mediumBundles;
  final int largeBundles;
  final int seedTotalOffered;
  final bool acceptsBlueprints;
  final bool acceptsSeeds;
  final bool acceptsResources;
  final bool seriousOffersOnly;
  final bool tradeAsBundle;
  final bool allowPartialOffers;
  final DateTime expiresAt;
  final String notes;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TradingListing({
    required this.id,
    required this.ownerUid,
    required this.traderName,
    required this.gamerTag,
    required this.preferredPlatform,
    required this.title,
    required this.offeredItem,
    required this.wantedText,
    required this.offeredBlueprintNames,
    required this.wantedBlueprintNames,
    required this.offeredAssetNames,
    required this.wantedAssetNames,
    required this.listingType,
    required this.riskLevel,
    required this.completedTrades,
    required this.noShows,
    required this.betrayalFlags,
    required this.region,
    required this.playWindow,
    required this.smallBundles,
    required this.mediumBundles,
    required this.largeBundles,
    required this.seedTotalOffered,
    required this.acceptsBlueprints,
    required this.acceptsSeeds,
    required this.acceptsResources,
    required this.seriousOffersOnly,
    required this.tradeAsBundle,
    required this.allowPartialOffers,
    required this.expiresAt,
    required this.notes,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TradingListing.empty() {
    final now = DateTime.now();
    return TradingListing(
      id: '',
      ownerUid: '',
      traderName: 'New Trader',
      gamerTag: '',
      preferredPlatform: '',
      title: '',
      offeredItem: '',
      wantedText: '',
      offeredBlueprintNames: const [],
      wantedBlueprintNames: const [],
      offeredAssetNames: const [],
      wantedAssetNames: const [],
      listingType: TradingListingType.specificWant,
      riskLevel: TradingRiskLevel.medium,
      completedTrades: 0,
      noShows: 0,
      betrayalFlags: 0,
      region: 'Flexible',
      playWindow: 'Flexible',
      smallBundles: 0,
      mediumBundles: 0,
      largeBundles: 0,
      seedTotalOffered: 0,
      acceptsBlueprints: true,
      acceptsSeeds: false,
      acceptsResources: false,
      seriousOffersOnly: false,
      tradeAsBundle: true,
      allowPartialOffers: false,
      expiresAt: now.add(const Duration(days: 3)),
      notes: '',
      active: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  String get listingTypeLabel {
    switch (listingType) {
      case TradingListingType.specificWant:
        return 'Specific Want';
      case TradingListingType.openToOffers:
        return 'Open to Offers';
    }
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

  Color riskColor() {
    switch (riskLevel) {
      case TradingRiskLevel.low:
        return Colors.greenAccent;
      case TradingRiskLevel.medium:
        return Colors.amberAccent;
      case TradingRiskLevel.high:
        return Colors.redAccent;
    }
  }

  bool get isLive => active && expiresAt.isAfter(DateTime.now());

  bool get hasSeedOffer => seedTotalOffered > 0;

  String expiryLabel() {
    if (!active) return 'Closed';
    final now = DateTime.now();
    if (expiresAt.isBefore(now)) return 'Expired';
    final difference = expiresAt.difference(now);
    if (difference.inDays >= 1) {
      return 'Expires in ${difference.inDays}d';
    }
    if (difference.inHours >= 1) {
      return 'Expires in ${difference.inHours}h';
    }
    final minutes = difference.inMinutes < 1 ? 1 : difference.inMinutes;
    return 'Expires in ${minutes}m';
  }

  String get acceptedTradeTypesLabel {
    final types = <String>[];
    if (acceptsBlueprints) types.add('Blueprints');
    if (acceptsSeeds) types.add('Seeds');
    if (acceptsResources) types.add('Resources');
    return types.isEmpty ? 'None set' : types.join(' • ');
  }

  String get traderDisplayLine {
    final name = traderName.trim().isNotEmpty ? traderName.trim() : 'Unknown Trader';
    final tag = gamerTag.trim();
    final platform = preferredPlatform.trim();
    final parts = <String>[name];
    if (tag.isNotEmpty) parts.add(tag);
    if (platform.isNotEmpty) parts.add(platform);
    return parts.join(' • ');
  }

  String get reputationSummary =>
      'Trades: $completedTrades • No-shows: $noShows • Betrayal flags: $betrayalFlags';

  List<String> get allOfferedItems {
    final items = <String>[];
    items.addAll(offeredBlueprintNames);
    items.addAll(offeredAssetNames);
    if (offeredItem.trim().isNotEmpty && !items.contains(offeredItem.trim())) {
      items.add(offeredItem.trim());
    }
    if (seedTotalOffered > 0) {
      items.add('$seedTotalOffered seeds');
    }
    return items;
  }

  List<String> get allWantedItems {
    final items = <String>[];
    items.addAll(wantedBlueprintNames);
    items.addAll(wantedAssetNames);
    if (wantedText.trim().isNotEmpty && !items.contains(wantedText.trim())) {
      items.add(wantedText.trim());
    }
    return items;
  }

  String get tradeFormatLabel => tradeAsBundle
      ? (allowPartialOffers ? 'Bundle preferred • partial offers allowed' : 'Bundle only')
      : (allowPartialOffers ? 'Mix and match • partial offers allowed' : 'Mix and match');

  String get offeredSummary {
    if (allOfferedItems.isEmpty) return offeredItem.trim().isNotEmpty ? offeredItem.trim() : 'Nothing listed';
    return allOfferedItems.join(', ');
  }

  String get wantedSummary {
    if (allWantedItems.isEmpty) return wantedText.trim().isNotEmpty ? wantedText.trim() : 'Open to offers';
    return allWantedItems.join(', ');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerUid': ownerUid,
      'traderName': traderName,
      'gamerTag': gamerTag,
      'preferredPlatform': preferredPlatform,
      'title': title,
      'offeredItem': offeredItem,
      'wantedText': wantedText,
      'offeredBlueprintNames': offeredBlueprintNames,
      'wantedBlueprintNames': wantedBlueprintNames,
      'offeredAssetNames': offeredAssetNames,
      'wantedAssetNames': wantedAssetNames,
      'listingType': listingType.name,
      'riskLevel': riskLevel.name,
      'completedTrades': completedTrades,
      'noShows': noShows,
      'betrayalFlags': betrayalFlags,
      'region': region,
      'playWindow': playWindow,
      'smallBundles': smallBundles,
      'mediumBundles': mediumBundles,
      'largeBundles': largeBundles,
      'seedTotalOffered': seedTotalOffered,
      'acceptsBlueprints': acceptsBlueprints,
      'acceptsSeeds': acceptsSeeds,
      'acceptsResources': acceptsResources,
      'seriousOffersOnly': seriousOffersOnly,
      'tradeAsBundle': tradeAsBundle,
      'allowPartialOffers': allowPartialOffers,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'notes': notes,
      'active': active,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory TradingListing.fromMap(Map<String, dynamic> map) {
    return TradingListing(
      id: (map['id'] ?? '') as String,
      ownerUid: (map['ownerUid'] ?? '') as String,
      traderName: (map['traderName'] ?? 'New Trader') as String,
      gamerTag: (map['gamerTag'] ?? '') as String,
      preferredPlatform: (map['preferredPlatform'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      offeredItem: (map['offeredItem'] ?? '') as String,
      wantedText: (map['wantedText'] ?? '') as String,
      offeredBlueprintNames: _readStringList(map['offeredBlueprintNames']),
      wantedBlueprintNames: _readStringList(map['wantedBlueprintNames']),
      offeredAssetNames: _readStringList(map['offeredAssetNames']),
      wantedAssetNames: _readStringList(map['wantedAssetNames']),
      listingType: TradingListingType.values.firstWhere(
        (value) => value.name == (map['listingType'] ?? ''),
        orElse: () => TradingListingType.specificWant,
      ),
      riskLevel: TradingRiskLevel.values.firstWhere(
        (value) => value.name == (map['riskLevel'] ?? ''),
        orElse: () => TradingRiskLevel.medium,
      ),
      completedTrades: (map['completedTrades'] ?? 0) as int,
      noShows: (map['noShows'] ?? 0) as int,
      betrayalFlags: (map['betrayalFlags'] ?? 0) as int,
      region: (map['region'] ?? 'Flexible') as String,
      playWindow: (map['playWindow'] ?? 'Flexible') as String,
      smallBundles: (map['smallBundles'] ?? 0) as int,
      mediumBundles: (map['mediumBundles'] ?? 0) as int,
      largeBundles: (map['largeBundles'] ?? 0) as int,
      seedTotalOffered: (map['seedTotalOffered'] ?? 0) as int,
      acceptsBlueprints: (map['acceptsBlueprints'] ?? true) as bool,
      acceptsSeeds: (map['acceptsSeeds'] ?? false) as bool,
      acceptsResources: (map['acceptsResources'] ?? false) as bool,
      seriousOffersOnly: (map['seriousOffersOnly'] ?? false) as bool,
      tradeAsBundle: (map['tradeAsBundle'] ?? true) as bool,
      allowPartialOffers: (map['allowPartialOffers'] ?? false) as bool,
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: (map['notes'] ?? '') as String,
      active: (map['active'] ?? true) as bool,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
