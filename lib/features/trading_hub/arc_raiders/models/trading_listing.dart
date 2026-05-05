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
  final List<String> offeredTradeItemIds;
  final List<String> wantedTradeItemIds;
  final List<String> offeredTradeItemNames;
  final List<String> wantedTradeItemNames;
  final bool wantsNothing;
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
    this.offeredBlueprintNames = const <String>[],
    this.wantedBlueprintNames = const <String>[],
    this.offeredAssetNames = const <String>[],
    this.wantedAssetNames = const <String>[],
    this.offeredTradeItemIds = const <String>[],
    this.wantedTradeItemIds = const <String>[],
    this.offeredTradeItemNames = const <String>[],
    this.wantedTradeItemNames = const <String>[],
    this.wantsNothing = false,
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
      offeredTradeItemIds: const [],
      wantedTradeItemIds: const [],
      offeredTradeItemNames: const [],
      wantedTradeItemNames: const [],
      wantsNothing: false,
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

  static String _readString(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int _readInt(dynamic value, [int fallback = 0]) {
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

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return const <String>[];
    return text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String get listingTypeLabel {
    switch (listingType) {
      case TradingListingType.specificWant:
        return 'Specific Want';
      case TradingListingType.openToOffers:
        return 'Open to Offers';
    }
  }

  bool get isFreeGiveaway => wantsNothing;

  String get giveawayLabel => wantsNothing ? 'Free Giveaway' : listingTypeLabel;

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
    if (wantsNothing) return 'Free giveaway • no return wanted';
    final types = <String>[];
    if (acceptsBlueprints) types.add('Blueprints');
    if (acceptsSeeds) types.add('Seeds');
    if (acceptsResources) types.add('Resources');
    if (wantedTradeItemNames.isNotEmpty || wantedTradeItemIds.isNotEmpty) {
      types.add('Trade Items');
    }
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
    items.addAll(offeredTradeItemNames);
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
    if (wantsNothing) return const ['Free giveaway'];
    items.addAll(wantedAssetNames);
    items.addAll(wantedTradeItemNames);
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
    if (wantsNothing) return 'Nothing wanted • free giveaway';
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
      'offeredTradeItemIds': offeredTradeItemIds,
      'wantedTradeItemIds': wantedTradeItemIds,
      'offeredTradeItemNames': offeredTradeItemNames,
      'wantedTradeItemNames': wantedTradeItemNames,
      'wantsNothing': wantsNothing,
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
      id: _readString(map['id']),
      ownerUid: _readString(map['ownerUid']),
      traderName: _readString(map['traderName'], 'New Trader'),
      gamerTag: _readString(map['gamerTag']),
      preferredPlatform: _readString(map['preferredPlatform']),
      title: _readString(map['title']),
      offeredItem: _readString(map['offeredItem']),
      wantedText: _readString(map['wantedText']),
      offeredBlueprintNames: _readStringList(map['offeredBlueprintNames']),
      wantedBlueprintNames: _readStringList(map['wantedBlueprintNames']),
      offeredAssetNames: _readStringList(map['offeredAssetNames']),
      wantedAssetNames: _readStringList(map['wantedAssetNames']),
      offeredTradeItemIds: _readStringList(map['offeredTradeItemIds']),
      wantedTradeItemIds: _readStringList(map['wantedTradeItemIds']),
      offeredTradeItemNames: _readStringList(map['offeredTradeItemNames']).isNotEmpty
          ? _readStringList(map['offeredTradeItemNames'])
          : _readStringList(map['offeredAssetNames']),
      wantedTradeItemNames: _readStringList(map['wantedTradeItemNames']).isNotEmpty
          ? _readStringList(map['wantedTradeItemNames'])
          : _readStringList(map['wantedAssetNames']),
      wantsNothing: _readBool(map['wantsNothing']),
      listingType: TradingListingType.values.firstWhere(
        (value) => value.name == (map['listingType'] ?? ''),
        orElse: () => TradingListingType.specificWant,
      ),
      riskLevel: TradingRiskLevel.values.firstWhere(
        (value) => value.name == (map['riskLevel'] ?? ''),
        orElse: () => TradingRiskLevel.medium,
      ),
      completedTrades: _readInt(map['completedTrades']),
      noShows: _readInt(map['noShows']),
      betrayalFlags: _readInt(map['betrayalFlags']),
      region: _readString(map['region'], 'Flexible'),
      playWindow: _readString(map['playWindow'], 'Flexible'),
      smallBundles: _readInt(map['smallBundles']),
      mediumBundles: _readInt(map['mediumBundles']),
      largeBundles: _readInt(map['largeBundles']),
      seedTotalOffered: _readInt(map['seedTotalOffered']),
      acceptsBlueprints: _readBool(map['acceptsBlueprints'], true),
      acceptsSeeds: _readBool(map['acceptsSeeds']),
      acceptsResources: _readBool(map['acceptsResources']),
      seriousOffersOnly: _readBool(map['seriousOffersOnly']),
      tradeAsBundle: _readBool(map['tradeAsBundle'], true),
      allowPartialOffers: _readBool(map['allowPartialOffers']),
      expiresAt: _readDate(map['expiresAt']) ?? DateTime.now(),
      notes: _readString(map['notes']),
      active: _readBool(map['active'], true),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }
}
