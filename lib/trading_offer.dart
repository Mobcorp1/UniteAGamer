import 'package:cloud_firestore/cloud_firestore.dart';

enum TradingOfferStatus { pending, accepted, declined, cancelled, expired }

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
    required this.note,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

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
      'note': note,
      'status': status.name,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory TradingOffer.fromMap(Map<String, dynamic> map) {
    return TradingOffer(
      id: (map['id'] ?? '') as String,
      listingId: (map['listingId'] ?? '') as String,
      senderUid: (map['senderUid'] ?? '') as String,
      receiverUid: (map['receiverUid'] ?? '') as String,
      senderName: (map['senderName'] ?? '') as String,
      senderGamerTag: (map['senderGamerTag'] ?? '') as String,
      senderPlatform: (map['senderPlatform'] ?? '') as String,
      offeredBlueprintText: (map['offeredBlueprintText'] ?? '') as String,
      smallBundles: (map['smallBundles'] ?? 0) as int,
      mediumBundles: (map['mediumBundles'] ?? 0) as int,
      largeBundles: (map['largeBundles'] ?? 0) as int,
      seedTotal: (map['seedTotal'] ?? 0) as int,
      includesResources: (map['includesResources'] ?? false) as bool,
      resourcesText: (map['resourcesText'] ?? '') as String,
      note: (map['note'] ?? '') as String,
      status: TradingOfferStatus.values.firstWhere(
        (value) => value.name == (map['status'] ?? 'pending'),
        orElse: () => TradingOfferStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
