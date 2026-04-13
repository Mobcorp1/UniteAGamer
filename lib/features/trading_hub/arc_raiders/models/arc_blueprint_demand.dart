class ArcBlueprintDemand {
  final String blueprintId;
  final int wantedCount;
  final int tradeableCount;
  final String? lastReportedMap;
  final String? lastReportedLocation;
  final String? lastReportedCondition;
  final DateTime? updatedAt;

  const ArcBlueprintDemand({
    required this.blueprintId,
    required this.wantedCount,
    required this.tradeableCount,
    this.lastReportedMap,
    this.lastReportedLocation,
    this.lastReportedCondition,
    this.updatedAt,
  });

  factory ArcBlueprintDemand.empty(String blueprintId) {
    return ArcBlueprintDemand(
      blueprintId: blueprintId,
      wantedCount: 0,
      tradeableCount: 0,
    );
  }

  double get demandRatio => tradeableCount <= 0 ? wantedCount.toDouble() : wantedCount / tradeableCount;

  String get demandLevel {
    final ratio = demandRatio;
    if (wantedCount == 0 && tradeableCount == 0) return 'Unknown';
    if (ratio < 1.5) return 'Balanced';
    if (ratio < 3) return 'Warm';
    if (ratio < 6) return 'High';
    return 'Very High';
  }

  Map<String, dynamic> toMap() {
    return {
      'blueprintId': blueprintId,
      'wantedCount': wantedCount,
      'tradeableCount': tradeableCount,
      'lastReportedMap': lastReportedMap,
      'lastReportedLocation': lastReportedLocation,
      'lastReportedCondition': lastReportedCondition,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory ArcBlueprintDemand.fromMap(Map<String, dynamic> map) {
    return ArcBlueprintDemand(
      blueprintId: (map['blueprintId'] ?? '') as String,
      wantedCount: (map['wantedCount'] ?? 0) as int,
      tradeableCount: (map['tradeableCount'] ?? 0) as int,
      lastReportedMap: map['lastReportedMap'] as String?,
      lastReportedLocation: map['lastReportedLocation'] as String?,
      lastReportedCondition: map['lastReportedCondition'] as String?,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
    );
  }

  ArcBlueprintDemand copyWith({
    String? blueprintId,
    int? wantedCount,
    int? tradeableCount,
    String? lastReportedMap,
    String? lastReportedLocation,
    String? lastReportedCondition,
    DateTime? updatedAt,
  }) {
    return ArcBlueprintDemand(
      blueprintId: blueprintId ?? this.blueprintId,
      wantedCount: wantedCount ?? this.wantedCount,
      tradeableCount: tradeableCount ?? this.tradeableCount,
      lastReportedMap: lastReportedMap ?? this.lastReportedMap,
      lastReportedLocation: lastReportedLocation ?? this.lastReportedLocation,
      lastReportedCondition: lastReportedCondition ?? this.lastReportedCondition,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
