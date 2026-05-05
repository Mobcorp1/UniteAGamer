import 'package:cloud_firestore/cloud_firestore.dart';

enum TradingOfferStatus {
  pending,
  accepted,
  declined,
  cancelled,
  expired,
}

class TradingOffer {
  final String id;
  final String listingId;
  final String senderUid;
  final String receiverUid;
  final String senderName;
  final String senderGamerTag;
  final String senderPlatform;
  final String offeredBlueprintText;
  final int smallBundles;
  final int mediumBundles;
  final int largeBundles;
  final int seedTotal;
  final bool includesResources;
  final String resourcesText;
  final List<String> offeredTradeItemIds;
  final List<String> offeredTradeItemNames;
  final bool isGiveawayClaim;
  final String note;
  final TradingOfferStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TradingOffer({
    required this.id,
    required this.listingId,
    required this.senderUid,
    required this.receiverUid,
    required this.senderName,
    required this.senderGamerTag,
    required this.senderPlatform,
    required this.offeredBlueprintText,
    required this.smallBundles,
    required this.mediumBundles,
    required this.largeBundles,
    required this.seedTotal,
    required this.includesResources,
    required this.resourcesText,
    this.offeredTradeItemIds = const <String>[],
    this.offeredTradeItemNames = const <String>[],
    this.isGiveawayClaim = false,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

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

  String get offerSummary {
    if (isGiveawayClaim) return 'Free giveaway claim';
    final parts = <String>[];
    if (offeredBlueprintText.trim().isNotEmpty) parts.add(offeredBlueprintText.trim());
    parts.addAll(offeredTradeItemNames);
    if (seedTotal > 0) parts.add('$seedTotal seeds');
    if (includesResources && resourcesText.trim().isNotEmpty) {
      parts.add(resourcesText.trim());
    }
    return parts.isEmpty ? 'No return offered' : parts.join(', ');
  }

  String get statusLabel {
    switch (status) {
      case TradingOfferStatus.pending:
        return 'Pending';
      case TradingOfferStatus.accepted:
        return 'Accepted';
      case TradingOfferStatus.declined:
        return 'Declined';
      case TradingOfferStatus.cancelled:
        return 'Cancelled';
      case TradingOfferStatus.expired:
        return 'Expired';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listingId': listingId,
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'senderName': senderName,
      'senderGamerTag': senderGamerTag,
      'senderPlatform': senderPlatform,
      'offeredBlueprintText': offeredBlueprintText,
      'smallBundles': smallBundles,
      'mediumBundles': mediumBundles,
      'largeBundles': largeBundles,
      'seedTotal': seedTotal,
      'includesResources': includesResources,
      'resourcesText': resourcesText,
      'offeredTradeItemIds': offeredTradeItemIds,
      'offeredTradeItemNames': offeredTradeItemNames,
      'isGiveawayClaim': isGiveawayClaim,
      'note': note,
      'status': status.name,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory TradingOffer.fromMap(Map<String, dynamic> map) {
    return TradingOffer(
      id: _readString(map['id']),
      listingId: _readString(map['listingId']),
      senderUid: _readString(map['senderUid']),
      receiverUid: _readString(map['receiverUid']),
      senderName: _readString(map['senderName']),
      senderGamerTag: _readString(map['senderGamerTag']),
      senderPlatform: _readString(map['senderPlatform']),
      offeredBlueprintText: _readString(map['offeredBlueprintText']),
      smallBundles: _readInt(map['smallBundles']),
      mediumBundles: _readInt(map['mediumBundles']),
      largeBundles: _readInt(map['largeBundles']),
      seedTotal: _readInt(map['seedTotal']),
      includesResources: _readBool(map['includesResources']),
      resourcesText: _readString(map['resourcesText']),
      offeredTradeItemIds: _readStringList(map['offeredTradeItemIds']),
      offeredTradeItemNames: _readStringList(map['offeredTradeItemNames']),
      isGiveawayClaim: _readBool(map['isGiveawayClaim']),
      note: _readString(map['note']),
      status: TradingOfferStatus.values.firstWhere(
        (value) => value.name == (map['status'] ?? 'pending'),
        orElse: () => TradingOfferStatus.pending,
      ),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }
}
