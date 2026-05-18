import 'package:flutter/foundation.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';

@immutable
class ArcStatsBreakdownItem {
  const ArcStatsBreakdownItem({
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

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'label': label,
      'count': count,
      'percentage': percentage,
    };
  }

  factory ArcStatsBreakdownItem.fromMap(Map<String, dynamic> map) {
    return ArcStatsBreakdownItem(
      key: (map['key'] as String?) ?? '',
      label: (map['label'] as String?) ?? '',
      count: (map['count'] as num?)?.toInt() ?? 0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

@immutable
class ArcBlueprintStats {
  const ArcBlueprintStats({
    required this.blueprintId,
    required this.totalReports,
    required this.uniqueReporterCount,
    required this.mapBreakdown,
    required this.areaBreakdown,
    required this.conditionBreakdown,
    required this.sourceBreakdown,
    this.topMapLabel,
    this.topAreaLabel,
    this.topConditionLabel,
    this.topSourceLabel,
    this.lastReportedAt,
    this.updatedAt,
  });

  final String blueprintId;
  final int totalReports;
  final int uniqueReporterCount;
  final List<ArcStatsBreakdownItem> mapBreakdown;
  final List<ArcStatsBreakdownItem> areaBreakdown;
  final List<ArcStatsBreakdownItem> conditionBreakdown;
  final List<ArcStatsBreakdownItem> sourceBreakdown;
  final String? topMapLabel;
  final String? topAreaLabel;
  final String? topConditionLabel;
  final String? topSourceLabel;
  final DateTime? lastReportedAt;
  final DateTime? updatedAt;

  bool get hasReports => totalReports > 0;

  factory ArcBlueprintStats.empty(String blueprintId) {
    return ArcBlueprintStats(
      blueprintId: blueprintId,
      totalReports: 0,
      uniqueReporterCount: 0,
      mapBreakdown: const <ArcStatsBreakdownItem>[],
      areaBreakdown: const <ArcStatsBreakdownItem>[],
      conditionBreakdown: const <ArcStatsBreakdownItem>[],
      sourceBreakdown: const <ArcStatsBreakdownItem>[],
    );
  }

  factory ArcBlueprintStats.fromReports({
    required String blueprintId,
    required List<ArcBlueprintDropReport> reports,
  }) {
    if (reports.isEmpty) {
      return ArcBlueprintStats.empty(blueprintId);
    }

    final mapCounts = <String, int>{};
    final areaCounts = <String, int>{};
    final conditionCounts = <String, int>{};
    final sourceCounts = <String, int>{};
    final reporters = <String>{};
    DateTime? lastReportedAt;

    for (final report in reports) {
      reporters.add(report.userId);
      mapCounts.update(report.mapName, (value) => value + 1, ifAbsent: () => 1);
      areaCounts.update(
        report.areaLabel,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      final conditionLabel = (report.conditionLabel?.trim().isNotEmpty ?? false)
          ? report.conditionLabel!.trim()
          : 'No Special Condition';
      conditionCounts.update(
        conditionLabel,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      final sourceLabel = report.sourceType.label;
      sourceCounts.update(sourceLabel, (value) => value + 1, ifAbsent: () => 1);

      final createdAt = report.createdAt;
      if (createdAt != null &&
          (lastReportedAt == null || createdAt.isAfter(lastReportedAt))) {
        lastReportedAt = createdAt;
      }
    }

    final totalReports = reports.length;

    List<ArcStatsBreakdownItem> buildBreakdown(Map<String, int> counts) {
      final entries = counts.entries.toList()
        ..sort((a, b) {
          final countCompare = b.value.compareTo(a.value);
          if (countCompare != 0) return countCompare;
          return a.key.compareTo(b.key);
        });

      return entries
          .map(
            (entry) => ArcStatsBreakdownItem(
              key: entry.key,
              label: entry.key,
              count: entry.value,
              percentage: totalReports <= 0
                  ? 0
                  : (entry.value / totalReports) * 100,
            ),
          )
          .toList(growable: false);
    }

    final mapBreakdown = buildBreakdown(mapCounts);
    final areaBreakdown = buildBreakdown(areaCounts);
    final conditionBreakdown = buildBreakdown(conditionCounts);
    final sourceBreakdown = buildBreakdown(sourceCounts);

    return ArcBlueprintStats(
      blueprintId: blueprintId,
      totalReports: totalReports,
      uniqueReporterCount: reporters.length,
      mapBreakdown: mapBreakdown,
      areaBreakdown: areaBreakdown,
      conditionBreakdown: conditionBreakdown,
      sourceBreakdown: sourceBreakdown,
      topMapLabel: mapBreakdown.isEmpty ? null : mapBreakdown.first.label,
      topAreaLabel: areaBreakdown.isEmpty ? null : areaBreakdown.first.label,
      topConditionLabel: conditionBreakdown.isEmpty
          ? null
          : conditionBreakdown.first.label,
      topSourceLabel: sourceBreakdown.isEmpty
          ? null
          : sourceBreakdown.first.label,
      lastReportedAt: lastReportedAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blueprintId': blueprintId,
      'totalReports': totalReports,
      'uniqueReporterCount': uniqueReporterCount,
      'mapBreakdown': mapBreakdown
          .map((item) => item.toMap())
          .toList(growable: false),
      'areaBreakdown': areaBreakdown
          .map((item) => item.toMap())
          .toList(growable: false),
      'conditionBreakdown': conditionBreakdown
          .map((item) => item.toMap())
          .toList(growable: false),
      'sourceBreakdown': sourceBreakdown
          .map((item) => item.toMap())
          .toList(growable: false),
      'topMapLabel': topMapLabel,
      'topAreaLabel': topAreaLabel,
      'topConditionLabel': topConditionLabel,
      'topSourceLabel': topSourceLabel,
      'lastReportedAt': lastReportedAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory ArcBlueprintStats.fromMap(Map<String, dynamic> map) {
    List<ArcStatsBreakdownItem> parseList(dynamic raw) {
      if (raw is! List) return const <ArcStatsBreakdownItem>[];
      return raw
          .whereType<Map>()
          .map(
            (item) =>
                ArcStatsBreakdownItem.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    }

    DateTime? fromMillis(dynamic value) {
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is num)
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      return null;
    }

    return ArcBlueprintStats(
      blueprintId: (map['blueprintId'] as String?) ?? '',
      totalReports: (map['totalReports'] as num?)?.toInt() ?? 0,
      uniqueReporterCount: (map['uniqueReporterCount'] as num?)?.toInt() ?? 0,
      mapBreakdown: parseList(map['mapBreakdown']),
      areaBreakdown: parseList(map['areaBreakdown']),
      conditionBreakdown: parseList(map['conditionBreakdown']),
      sourceBreakdown: parseList(map['sourceBreakdown']),
      topMapLabel: map['topMapLabel'] as String?,
      topAreaLabel: map['topAreaLabel'] as String?,
      topConditionLabel: map['topConditionLabel'] as String?,
      topSourceLabel: map['topSourceLabel'] as String?,
      lastReportedAt: fromMillis(map['lastReportedAt']),
      updatedAt: fromMillis(map['updatedAt']),
    );
  }
}
