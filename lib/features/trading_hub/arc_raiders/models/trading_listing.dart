import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_listing_queue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_trade_bundle_models.dart';

enum TradingRiskLevel { low, medium, high }

enum TradingListingType { specificWant, openToOffers }

enum TradingListingMode {
  availableNow,
  laterToday,
  collectOffers,
  nextLogin,
  scheduledWindow,
  gift,
  favouriteRidersFirst,
  fixedReturn,
  bestSuitableOffer,
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
  final List<ArcTradeBundleTemplate> acceptedBundles;
  final bool allowCustomBundleOffers;
  final TradingListingMode listingMode;
  final String scheduledWindow;
  final String sellerTimezone;
  final ArcDuplicateReleasePolicy duplicateReleasePolicy;
  final bool favouriteRidersFirst;
  final bool fixedReturn;
  final bool bestSuitableOffer;
  final int maxActiveOffers;
  final String queueId;
  final String queueSourceListingId;
  final int queueReleaseNumber;
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
    this.acceptedBundles = const <ArcTradeBundleTemplate>[],
    this.allowCustomBundleOffers = false,
    this.listingMode = TradingListingMode.availableNow,
    this.scheduledWindow = '',
    this.sellerTimezone = '',
    this.duplicateReleasePolicy = ArcDuplicateReleasePolicy.askBeforeRelisting,
    this.favouriteRidersFirst = false,
    this.fixedReturn = false,
    this.bestSuitableOffer = false,
    this.maxActiveOffers = 5,
    this.queueId = '',
    this.queueSourceListingId = '',
    this.queueReleaseNumber = 0,
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
      acceptedBundles: const <ArcTradeBundleTemplate>[],
      allowCustomBundleOffers: false,
      listingMode: TradingListingMode.availableNow,
      scheduledWindow: '',
      sellerTimezone: '',
      duplicateReleasePolicy: ArcDuplicateReleasePolicy.askBeforeRelisting,
      favouriteRidersFirst: false,
      fixedReturn: false,
      bestSuitableOffer: false,
      maxActiveOffers: 5,
      queueId: '',
      queueSourceListingId: '',
      queueReleaseNumber: 0,
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

  String get listingModeLabel {
    switch (listingMode) {
      case TradingListingMode.availableNow:
        return 'Available now';
      case TradingListingMode.laterToday:
        return 'Later today';
      case TradingListingMode.collectOffers:
        return 'Collect offers';
      case TradingListingMode.nextLogin:
        return 'Next login';
      case TradingListingMode.scheduledWindow:
        return scheduledWindow.trim().isEmpty
            ? 'Scheduled window'
            : 'Scheduled: ${scheduledWindow.trim()}';
      case TradingListingMode.gift:
        return 'Gift';
      case TradingListingMode.favouriteRidersFirst:
        return 'Favourite Riders first';
      case TradingListingMode.fixedReturn:
        return 'Fixed return';
      case TradingListingMode.bestSuitableOffer:
        return 'Best suitable offer';
    }
  }

  String get duplicateReleasePolicyLabel {
    switch (duplicateReleasePolicy) {
      case ArcDuplicateReleasePolicy.immediatelyAfterCompletion:
        return 'Relist after completion';
      case ArcDuplicateReleasePolicy.afterThirtyMinutes:
        return 'Relist after 30 minutes';
      case ArcDuplicateReleasePolicy.afterTwoHours:
        return 'Relist after 2 hours';
      case ArcDuplicateReleasePolicy.nextLogin:
        return 'Relist next login';
      case ArcDuplicateReleasePolicy.askBeforeRelisting:
        return 'Ask before relisting';
      case ArcDuplicateReleasePolicy.neverAutomaticallyRelist:
        return 'Never auto relist';
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
  bool get isQueueLinked => queueId.trim().isNotEmpty;

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
    if (wantsNothing) return 'Free giveaway - no return wanted';
    final types = <String>[];
    if (acceptsBlueprints) types.add('Blueprints');
    if (acceptsSeeds) types.add('Seeds');
    if (acceptsResources) types.add('Resources');
    if (wantedTradeItemNames.isNotEmpty || wantedTradeItemIds.isNotEmpty) {
      types.add('Trade Items');
    }
    return types.isEmpty ? 'None set' : types.join(' - ');
  }

  String get traderDisplayLine {
    final name = traderName.trim().isNotEmpty
        ? traderName.trim()
        : 'Unknown Trader';
    final tag = gamerTag.trim();
    final platform = preferredPlatform.trim();
    final parts = <String>[name];
    if (tag.isNotEmpty) parts.add(tag);
    if (platform.isNotEmpty) parts.add(platform);
    return parts.join(' - ');
  }

  String get reputationSummary =>
      'Trades: $completedTrades - No-shows: $noShows - Betrayal flags: $betrayalFlags';

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

  bool get hasExactAcceptedBundles =>
      acceptedBundles.any((bundle) => bundle.active);

  String get tradeFormatLabel => tradeAsBundle
      ? (allowPartialOffers
            ? 'Bundle preferred - partial offers allowed'
            : 'Bundle only')
      : (allowPartialOffers
            ? 'Mix and match - partial offers allowed'
            : 'Mix and match');

  String get offeredSummary {
    if (allOfferedItems.isEmpty) {
      return offeredItem.trim().isNotEmpty
          ? offeredItem.trim()
          : 'Nothing listed';
    }
    return allOfferedItems.join(', ');
  }

  String get wantedSummary {
    if (wantsNothing) return 'Nothing wanted - free giveaway';
    if (allWantedItems.isEmpty) {
      return wantedText.trim().isNotEmpty
          ? wantedText.trim()
          : 'Open to offers';
    }
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
      'acceptedBundles': acceptedBundles
          .map((bundle) => bundle.toMap())
          .toList(),
      'allowCustomBundleOffers': allowCustomBundleOffers,
      'listingMode': listingMode.name,
      'scheduledWindow': scheduledWindow,
      'sellerTimezone': sellerTimezone,
      'duplicateReleasePolicy': duplicateReleasePolicy.name,
      'favouriteRidersFirst': favouriteRidersFirst,
      'fixedReturn': fixedReturn,
      'bestSuitableOffer': bestSuitableOffer,
      'maxActiveOffers': maxActiveOffers,
      'queueId': queueId,
      'queueSourceListingId': queueSourceListingId,
      'queueReleaseNumber': queueReleaseNumber,
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
      offeredTradeItemNames:
          _readStringList(map['offeredTradeItemNames']).isNotEmpty
          ? _readStringList(map['offeredTradeItemNames'])
          : _readStringList(map['offeredAssetNames']),
      wantedTradeItemNames:
          _readStringList(map['wantedTradeItemNames']).isNotEmpty
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
      acceptedBundles: map['acceptedBundles'] is List
          ? (map['acceptedBundles'] as List)
                .whereType<Map>()
                .map(
                  (item) => ArcTradeBundleTemplate.fromMap(
                    item.map((key, value) => MapEntry(key.toString(), value)),
                  ),
                )
                .where((bundle) => bundle.isValid)
                .toList(growable: false)
          : const <ArcTradeBundleTemplate>[],
      allowCustomBundleOffers: _readBool(map['allowCustomBundleOffers']),
      listingMode: TradingListingMode.values.firstWhere(
        (value) => value.name == _readString(map['listingMode']),
        orElse: () => _readBool(map['wantsNothing'])
            ? TradingListingMode.gift
            : TradingListingMode.availableNow,
      ),
      scheduledWindow: _readString(map['scheduledWindow']),
      sellerTimezone: _readString(map['sellerTimezone']),
      duplicateReleasePolicy: ArcDuplicateReleasePolicy.values.firstWhere(
        (value) => value.name == _readString(map['duplicateReleasePolicy']),
        orElse: () => ArcDuplicateReleasePolicy.askBeforeRelisting,
      ),
      favouriteRidersFirst: _readBool(map['favouriteRidersFirst']),
      fixedReturn: _readBool(map['fixedReturn']),
      bestSuitableOffer: _readBool(map['bestSuitableOffer']),
      maxActiveOffers: _readInt(map['maxActiveOffers'], 5).clamp(1, 25).toInt(),
      queueId: _readString(map['queueId']),
      queueSourceListingId: _readString(map['queueSourceListingId']),
      queueReleaseNumber: _readInt(map['queueReleaseNumber']),
      expiresAt: _readDate(map['expiresAt']) ?? DateTime.now(),
      notes: _readString(map['notes']),
      active: _readBool(map['active'], true),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  TradingListing copyWith({
    String? id,
    String? ownerUid,
    String? traderName,
    String? gamerTag,
    String? preferredPlatform,
    String? title,
    String? offeredItem,
    String? wantedText,
    List<String>? offeredBlueprintNames,
    List<String>? wantedBlueprintNames,
    List<String>? offeredAssetNames,
    List<String>? wantedAssetNames,
    List<String>? offeredTradeItemIds,
    List<String>? wantedTradeItemIds,
    List<String>? offeredTradeItemNames,
    List<String>? wantedTradeItemNames,
    bool? wantsNothing,
    TradingListingType? listingType,
    TradingRiskLevel? riskLevel,
    int? completedTrades,
    int? noShows,
    int? betrayalFlags,
    String? region,
    String? playWindow,
    int? smallBundles,
    int? mediumBundles,
    int? largeBundles,
    int? seedTotalOffered,
    bool? acceptsBlueprints,
    bool? acceptsSeeds,
    bool? acceptsResources,
    bool? seriousOffersOnly,
    bool? tradeAsBundle,
    bool? allowPartialOffers,
    List<ArcTradeBundleTemplate>? acceptedBundles,
    bool? allowCustomBundleOffers,
    TradingListingMode? listingMode,
    String? scheduledWindow,
    String? sellerTimezone,
    ArcDuplicateReleasePolicy? duplicateReleasePolicy,
    bool? favouriteRidersFirst,
    bool? fixedReturn,
    bool? bestSuitableOffer,
    int? maxActiveOffers,
    String? queueId,
    String? queueSourceListingId,
    int? queueReleaseNumber,
    DateTime? expiresAt,
    String? notes,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TradingListing(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      traderName: traderName ?? this.traderName,
      gamerTag: gamerTag ?? this.gamerTag,
      preferredPlatform: preferredPlatform ?? this.preferredPlatform,
      title: title ?? this.title,
      offeredItem: offeredItem ?? this.offeredItem,
      wantedText: wantedText ?? this.wantedText,
      offeredBlueprintNames:
          offeredBlueprintNames ?? this.offeredBlueprintNames,
      wantedBlueprintNames: wantedBlueprintNames ?? this.wantedBlueprintNames,
      offeredAssetNames: offeredAssetNames ?? this.offeredAssetNames,
      wantedAssetNames: wantedAssetNames ?? this.wantedAssetNames,
      offeredTradeItemIds: offeredTradeItemIds ?? this.offeredTradeItemIds,
      wantedTradeItemIds: wantedTradeItemIds ?? this.wantedTradeItemIds,
      offeredTradeItemNames:
          offeredTradeItemNames ?? this.offeredTradeItemNames,
      wantedTradeItemNames: wantedTradeItemNames ?? this.wantedTradeItemNames,
      wantsNothing: wantsNothing ?? this.wantsNothing,
      listingType: listingType ?? this.listingType,
      riskLevel: riskLevel ?? this.riskLevel,
      completedTrades: completedTrades ?? this.completedTrades,
      noShows: noShows ?? this.noShows,
      betrayalFlags: betrayalFlags ?? this.betrayalFlags,
      region: region ?? this.region,
      playWindow: playWindow ?? this.playWindow,
      smallBundles: smallBundles ?? this.smallBundles,
      mediumBundles: mediumBundles ?? this.mediumBundles,
      largeBundles: largeBundles ?? this.largeBundles,
      seedTotalOffered: seedTotalOffered ?? this.seedTotalOffered,
      acceptsBlueprints: acceptsBlueprints ?? this.acceptsBlueprints,
      acceptsSeeds: acceptsSeeds ?? this.acceptsSeeds,
      acceptsResources: acceptsResources ?? this.acceptsResources,
      seriousOffersOnly: seriousOffersOnly ?? this.seriousOffersOnly,
      tradeAsBundle: tradeAsBundle ?? this.tradeAsBundle,
      allowPartialOffers: allowPartialOffers ?? this.allowPartialOffers,
      acceptedBundles: acceptedBundles ?? this.acceptedBundles,
      allowCustomBundleOffers:
          allowCustomBundleOffers ?? this.allowCustomBundleOffers,
      listingMode: listingMode ?? this.listingMode,
      scheduledWindow: scheduledWindow ?? this.scheduledWindow,
      sellerTimezone: sellerTimezone ?? this.sellerTimezone,
      duplicateReleasePolicy:
          duplicateReleasePolicy ?? this.duplicateReleasePolicy,
      favouriteRidersFirst: favouriteRidersFirst ?? this.favouriteRidersFirst,
      fixedReturn: fixedReturn ?? this.fixedReturn,
      bestSuitableOffer: bestSuitableOffer ?? this.bestSuitableOffer,
      maxActiveOffers: (maxActiveOffers ?? this.maxActiveOffers)
          .clamp(1, 25)
          .toInt(),
      queueId: queueId ?? this.queueId,
      queueSourceListingId: queueSourceListingId ?? this.queueSourceListingId,
      queueReleaseNumber: queueReleaseNumber ?? this.queueReleaseNumber,
      expiresAt: expiresAt ?? this.expiresAt,
      notes: notes ?? this.notes,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
