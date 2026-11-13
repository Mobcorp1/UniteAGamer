import 'package:flutter/foundation.dart';

enum ArcCollectionType {
  blueprints,
  stencils,
  designs;

  String get label => switch (this) {
    ArcCollectionType.blueprints => 'BLUEPRINTS',
    ArcCollectionType.stencils => 'STENCILS',
    ArcCollectionType.designs => 'DESIGNS',
  };
}

enum ArcCollectionSlotConfidence {
  verifiedInGame,
  confirmedItemUnknownSlot,
  unverified,
}

enum ArcCollectionEconomyStatus { supported, unsupported, unknown }

@immutable
class ArcCollectionGridSpec {
  const ArcCollectionGridSpec({
    required this.type,
    required this.totalSlots,
    required this.rowColumnCounts,
  });

  final ArcCollectionType type;
  final int totalSlots;
  final List<int> rowColumnCounts;

  int get rowCount => rowColumnCounts.length;

  int get maxColumns => rowColumnCounts.fold<int>(
    0,
    (current, value) => value > current ? value : current,
  );

  int? absoluteSlotFor({required int row, required int column}) {
    if (row < 1 || row > rowColumnCounts.length) return null;
    final columns = rowColumnCounts[row - 1];
    if (column < 1 || column > columns) return null;

    var offset = 0;
    for (var index = 0; index < row - 1; index++) {
      offset += rowColumnCounts[index];
    }
    return offset + column;
  }

  ({int row, int column})? positionForSlot(int slot) {
    if (slot < 1 || slot > totalSlots) return null;

    var remaining = slot;
    for (var row = 0; row < rowColumnCounts.length; row++) {
      final columns = rowColumnCounts[row];
      if (remaining <= columns) {
        return (row: row + 1, column: remaining);
      }
      remaining -= columns;
    }
    return null;
  }
}

@immutable
class ArcCollectionEntry {
  const ArcCollectionEntry({
    required this.id,
    required this.name,
    required this.type,
    required this.confidence,
    this.slot,
    this.sourceLabel,
    this.duplicateStatus = ArcCollectionEconomyStatus.unknown,
    this.tradeStatus = ArcCollectionEconomyStatus.unknown,
  });

  final String id;
  final String name;
  final ArcCollectionType type;
  final int? slot;
  final ArcCollectionSlotConfidence confidence;
  final String? sourceLabel;
  final ArcCollectionEconomyStatus duplicateStatus;
  final ArcCollectionEconomyStatus tradeStatus;
}
