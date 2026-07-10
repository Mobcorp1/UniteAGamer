import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum ArcTradeOpportunityType { direct, threeRaiderChain, prepare }

extension ArcTradeOpportunityTypeX on ArcTradeOpportunityType {
  String get label {
    switch (this) {
      case ArcTradeOpportunityType.direct:
        return 'Direct Match';
      case ArcTradeOpportunityType.threeRaiderChain:
        return 'Three-Raider Chain';
      case ArcTradeOpportunityType.prepare:
        return 'Prepare Trade';
    }
  }
}

enum ArcTradePreparationStatus {
  watching,
  farming,
  ready,
  cancelled,
  expired,
  completed,
}

extension ArcTradePreparationStatusX on ArcTradePreparationStatus {
  String get label {
    switch (this) {
      case ArcTradePreparationStatus.watching:
        return 'Watching';
      case ArcTradePreparationStatus.farming:
        return 'Farming';
      case ArcTradePreparationStatus.ready:
        return 'Ready';
      case ArcTradePreparationStatus.cancelled:
        return 'Cancelled';
      case ArcTradePreparationStatus.expired:
        return 'Expired';
      case ArcTradePreparationStatus.completed:
        return 'Completed';
    }
  }

  bool get isTerminal {
    switch (this) {
      case ArcTradePreparationStatus.cancelled:
      case ArcTradePreparationStatus.expired:
      case ArcTradePreparationStatus.completed:
        return true;
      case ArcTradePreparationStatus.watching:
      case ArcTradePreparationStatus.farming:
      case ArcTradePreparationStatus.ready:
        return false;
    }
  }
}

@immutable
class ArcTradeItemQuantity {
  const ArcTradeItemQuantity({
    required this.id,
    required this.label,
    required this.quantity,
  });

  final String id;
  final String label;
  final int quantity;

  bool get isEmpty => id.trim().isEmpty || quantity <= 0;

  ArcTradeItemQuantity copyWith({String? id, String? label, int? quantity}) {
    return ArcTradeItemQuantity(
      id: id ?? this.id,
      label: label ?? this.label,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'id': id, 'label': label, 'quantity': quantity};
  }

  factory ArcTradeItemQuantity.fromMap(Map<String, dynamic> map) {
    return ArcTradeItemQuantity(
      id: (map['id'] ?? '').toString(),
      label: (map['label'] ?? map['name'] ?? map['id'] ?? '').toString(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class ArcTradeBlueprintIntel {
  const ArcTradeBlueprintIntel({
    required this.blueprintId,
    required this.blueprintName,
    required this.summary,
    required this.sourceLabel,
    required this.supportCount,
    this.mapName,
    this.conditionLabel,
    this.reportAgeLabel,
  });

  final String blueprintId;
  final String blueprintName;
  final String summary;
  final String sourceLabel;
  final String? mapName;
  final String? conditionLabel;
  final String? reportAgeLabel;
  final int supportCount;
}

@immutable
class ArcTradeOpportunity {
  const ArcTradeOpportunity({
    required this.id,
    required this.type,
    required this.title,
    required this.reason,
    required this.actionLabel,
    required this.confidence,
    required this.rankScore,
    required this.listingIds,
    required this.participantUids,
    required this.currentUserGives,
    required this.currentUserReceives,
    required this.requiredItems,
    required this.ownedItems,
    required this.remainingItems,
    this.targetListingId,
    this.targetPlayerId,
    this.routeName,
    this.satisfiesTopWanted = false,
    this.progressionHint = '',
    this.isGuaranteed = false,
    this.notes = const <String>[],
    this.blueprintIntel = const <ArcTradeBlueprintIntel>[],
  });

  final String id;
  final ArcTradeOpportunityType type;
  final String title;
  final String reason;
  final String actionLabel;
  final int confidence;
  final int rankScore;
  final List<String> listingIds;
  final List<String> participantUids;
  final List<ArcTradeItemQuantity> currentUserGives;
  final List<ArcTradeItemQuantity> currentUserReceives;
  final List<ArcTradeItemQuantity> requiredItems;
  final List<ArcTradeItemQuantity> ownedItems;
  final List<ArcTradeItemQuantity> remainingItems;
  final String? targetListingId;
  final String? targetPlayerId;
  final String? routeName;
  final bool satisfiesTopWanted;
  final String progressionHint;
  final bool isGuaranteed;
  final List<String> notes;
  final List<ArcTradeBlueprintIntel> blueprintIntel;

  bool get isReady => remainingItems.isEmpty;
  bool get requiresPreparation =>
      type == ArcTradeOpportunityType.prepare && remainingItems.isNotEmpty;
}

@immutable
class ArcTradeNetworkSummary {
  const ArcTradeNetworkSummary({
    required this.directMatches,
    required this.threeRaiderChains,
    required this.preparationOpportunities,
    required this.playersNeedingMyItems,
    required this.playersOfferingWantedItems,
  });

  final List<ArcTradeOpportunity> directMatches;
  final List<ArcTradeOpportunity> threeRaiderChains;
  final List<ArcTradeOpportunity> preparationOpportunities;
  final List<ArcTradeOpportunity> playersNeedingMyItems;
  final List<ArcTradeOpportunity> playersOfferingWantedItems;

  static const empty = ArcTradeNetworkSummary(
    directMatches: <ArcTradeOpportunity>[],
    threeRaiderChains: <ArcTradeOpportunity>[],
    preparationOpportunities: <ArcTradeOpportunity>[],
    playersNeedingMyItems: <ArcTradeOpportunity>[],
    playersOfferingWantedItems: <ArcTradeOpportunity>[],
  );

  List<ArcTradeOpportunity> get rankedOpportunities {
    final items =
        <ArcTradeOpportunity>[
          ...directMatches,
          ...threeRaiderChains,
          ...preparationOpportunities,
        ]..sort((a, b) {
          final rankCompare = b.rankScore.compareTo(a.rankScore);
          if (rankCompare != 0) return rankCompare;
          final confidenceCompare = b.confidence.compareTo(a.confidence);
          if (confidenceCompare != 0) return confidenceCompare;
          return a.id.compareTo(b.id);
        });
    return items.toList(growable: false);
  }

  bool get hasActionableOpportunities => rankedOpportunities.isNotEmpty;
}

@immutable
class ArcTradePreparation {
  const ArcTradePreparation({
    required this.id,
    required this.userId,
    required this.targetListingId,
    required this.targetPlayerId,
    required this.listingTitle,
    required this.requiredItems,
    required this.ownedItems,
    required this.remainingItems,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.note = '',
  });

  final String id;
  final String userId;
  final String targetListingId;
  final String targetPlayerId;
  final String listingTitle;
  final List<ArcTradeItemQuantity> requiredItems;
  final List<ArcTradeItemQuantity> ownedItems;
  final List<ArcTradeItemQuantity> remainingItems;
  final ArcTradePreparationStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String note;

  bool get isReady => remainingItems.isEmpty;

  String get readinessLabel {
    if (status.isTerminal) return status.label;
    if (isReady) return ArcTradePreparationStatus.ready.label;
    final remaining = remainingItems
        .map((item) => '${item.quantity} ${item.label}')
        .join(', ');
    return remaining.isEmpty ? 'Watching' : 'Missing $remaining';
  }

  ArcTradePreparation copyWith({
    String? id,
    String? userId,
    String? targetListingId,
    String? targetPlayerId,
    String? listingTitle,
    List<ArcTradeItemQuantity>? requiredItems,
    List<ArcTradeItemQuantity>? ownedItems,
    List<ArcTradeItemQuantity>? remainingItems,
    ArcTradePreparationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? note,
  }) {
    return ArcTradePreparation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetListingId: targetListingId ?? this.targetListingId,
      targetPlayerId: targetPlayerId ?? this.targetPlayerId,
      listingTitle: listingTitle ?? this.listingTitle,
      requiredItems: requiredItems ?? this.requiredItems,
      ownedItems: ownedItems ?? this.ownedItems,
      remainingItems: remainingItems ?? this.remainingItems,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'targetListingId': targetListingId,
      'targetPlayerId': targetPlayerId,
      'listingTitle': listingTitle,
      'requiredItems': requiredItems.map((item) => item.toMap()).toList(),
      'ownedItems': ownedItems.map((item) => item.toMap()).toList(),
      'remainingItems': remainingItems.map((item) => item.toMap()).toList(),
      'status': status.name,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'note': note,
    };
  }

  factory ArcTradePreparation.fromMap(Map<String, dynamic> map) {
    return ArcTradePreparation(
      id: (map['id'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      targetListingId: (map['targetListingId'] ?? '').toString(),
      targetPlayerId: (map['targetPlayerId'] ?? '').toString(),
      listingTitle: (map['listingTitle'] ?? '').toString(),
      requiredItems: _readItems(map['requiredItems']),
      ownedItems: _readItems(map['ownedItems']),
      remainingItems: _readItems(map['remainingItems']),
      status: ArcTradePreparationStatus.values.firstWhere(
        (item) => item.name == (map['status'] ?? '').toString(),
        orElse: () => ArcTradePreparationStatus.watching,
      ),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
      note: (map['note'] ?? '').toString(),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static List<ArcTradeItemQuantity> _readItems(Object? value) {
    final rawItems = value is List ? value : const <Object?>[];
    return rawItems
        .whereType<Map>()
        .map(
          (item) => ArcTradeItemQuantity.fromMap(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .where((item) => !item.isEmpty)
        .toList(growable: false);
  }
}
