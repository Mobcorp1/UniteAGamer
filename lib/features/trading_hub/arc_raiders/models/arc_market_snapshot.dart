
import 'package:flutter/foundation.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';

@immutable
class ArcMarketSnapshotEntry {
  const ArcMarketSnapshotEntry({
    required this.key,
    required this.label,
    required this.count,
    required this.percentage,
  });

  final String key;
  final String label;
  final int count;
  final double percentage;

  String get percentageLabel => '${percentage.toStringAsFixed(0)}%';
}

@immutable
class ArcMarketSnapshot {
  const ArcMarketSnapshot({
    required this.totalReports,
    required this.uniqueBlueprints,
    required this.uniqueMaps,
    required this.uniqueReporters,
    required this.blueprintBreakdown,
    required this.mapBreakdown,
    required this.conditionBreakdown,
    required this.sourceBreakdown,
    required this.recentReports,
    this.topBlueprintLabel,
    this.topMapLabel,
    this.topConditionLabel,
    this.lastReportedAt,
  });

  final int totalReports;
  final int uniqueBlueprints;
  final int uniqueMaps;
  final int uniqueReporters;
  final List<ArcMarketSnapshotEntry> blueprintBreakdown;
  final List<ArcMarketSnapshotEntry> mapBreakdown;
  final List<ArcMarketSnapshotEntry> conditionBreakdown;
  final List<ArcMarketSnapshotEntry> sourceBreakdown;
  final List<ArcBlueprintDropReport> recentReports;
  final String? topBlueprintLabel;
  final String? topMapLabel;
  final String? topConditionLabel;
  final DateTime? lastReportedAt;

  bool get hasReports => totalReports > 0;

  String get confidenceLabel {
    if (totalReports >= 40) return 'High';
    if (totalReports >= 15) return 'Medium';
    if (totalReports >= 1) return 'Early';
    return 'None';
  }

  factory ArcMarketSnapshot.empty() {
    return const ArcMarketSnapshot(
      totalReports: 0,
      uniqueBlueprints: 0,
      uniqueMaps: 0,
      uniqueReporters: 0,
      blueprintBreakdown: <ArcMarketSnapshotEntry>[],
      mapBreakdown: <ArcMarketSnapshotEntry>[],
      conditionBreakdown: <ArcMarketSnapshotEntry>[],
      sourceBreakdown: <ArcMarketSnapshotEntry>[],
      recentReports: <ArcBlueprintDropReport>[],
    );
  }
}
