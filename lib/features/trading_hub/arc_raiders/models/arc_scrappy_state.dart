import 'package:flutter/foundation.dart';

@immutable
class ArcScrappyState {
  const ArcScrappyState({
    required this.itemId,
    required this.collectedCount,
    this.updatedAt,
  });

  final String itemId;
  final int collectedCount;
  final DateTime? updatedAt;

  factory ArcScrappyState.empty(String itemId) {
    return ArcScrappyState(
      itemId: itemId,
      collectedCount: 0,
      updatedAt: DateTime.now(),
    );
  }

  factory ArcScrappyState.fromJson(Map<String, dynamic> json, {required String itemId}) {
    final rawCollected = json['collectedCount'];
    final rawDupes = json['dupesOwned'];
    final rawOwned = json['owned'];

    int collected = 0;
    if (rawCollected is num) {
      collected = rawCollected.toInt();
    } else if (rawDupes is num) {
      collected = rawDupes.toInt();
      if (rawOwned == true && collected == 0) {
        collected = 1;
      }
    } else if (rawOwned == true) {
      collected = 1;
    }

    final updated = json['updatedAt'];
    return ArcScrappyState(
      itemId: itemId,
      collectedCount: collected < 0 ? 0 : collected,
      updatedAt: updated is DateTime ? updated : null,
    );
  }

  ArcScrappyState copyWith({
    int? collectedCount,
    DateTime? updatedAt,
  }) {
    return ArcScrappyState(
      itemId: itemId,
      collectedCount: collectedCount ?? this.collectedCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson({int? neededCount}) {
    final effectiveNeeded = neededCount ?? 0;
    final owned = effectiveNeeded <= 0 ? collectedCount > 0 : collectedCount >= effectiveNeeded;
    final surplus = effectiveNeeded <= 0
        ? 0
        : (collectedCount - effectiveNeeded).clamp(0, 999999);

    return {
      'itemId': itemId,
      'collectedCount': collectedCount,
      'owned': owned,
      'dupesOwned': surplus,
      'updatedAt': updatedAt ?? DateTime.now(),
    };
  }

  bool ownedFor(int neededCount) => collectedCount >= neededCount;

  int remainingNeededFor(int neededCount) {
    return (neededCount - collectedCount).clamp(0, neededCount);
  }

  int surplusFor(int neededCount) {
    return (collectedCount - neededCount).clamp(0, 999999);
  }

  bool wantedFor(int neededCount) => remainingNeededFor(neededCount) > 0;

  bool availableToTradeFor(int neededCount) => surplusFor(neededCount) > 0;

  bool hasDuplicatesFor(int neededCount) => surplusFor(neededCount) > 0;

  // Backward-compatible getters for existing UI pieces.
  bool get owned => collectedCount > 0;
  int get dupesOwned => collectedCount;
  bool get hasDuplicates => collectedCount > 1;
  bool get wanted => !owned;
  bool get availableToTrade => hasDuplicates;
}
