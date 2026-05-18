import 'package:flutter/foundation.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_stats.dart';

@immutable
class ArcPoiDropStats {
  const ArcPoiDropStats({
    required this.id,
    required this.mapName,
    required this.poiId,
    required this.poiName,
    required this.totalReports,
    required this.blueprintBreakdown,
    required this.conditionBreakdown,
    required this.sourceBreakdown,
    this.topBlueprintId,
    this.topBlueprintLabel,
    this.topConditionLabel,
    this.lastReportedAt,
    this.updatedAt,
  });

  final String id;
  final String mapName;
  final String poiId;
  final String poiName;
  final int totalReports;
  final List<ArcStatsBreakdownItem> blueprintBreakdown;
  final List<ArcStatsBreakdownItem> conditionBreakdown;
  final List<ArcStatsBreakdownItem> sourceBreakdown;
  final String? topBlueprintId;
  final String? topBlueprintLabel;
  final String? topConditionLabel;
  final DateTime? lastReportedAt;
  final DateTime? updatedAt;

  bool get hasReports => totalReports > 0;

  factory ArcPoiDropStats.empty({
    required String mapName,
    required String poiId,
    required String poiName,
  }) {
    return ArcPoiDropStats(
      id: '${_slugify(mapName)}__$poiId',
      mapName: mapName,
      poiId: poiId,
      poiName: poiName,
      totalReports: 0,
      blueprintBreakdown: const <ArcStatsBreakdownItem>[],
      conditionBreakdown: const <ArcStatsBreakdownItem>[],
      sourceBreakdown: const <ArcStatsBreakdownItem>[],
    );
  }

  factory ArcPoiDropStats.fromReports({
    required String mapName,
    required String poiId,
    required String poiName,
    required List<ArcBlueprintDropReport> reports,
  }) {
    if (reports.isEmpty) {
      return ArcPoiDropStats.empty(
        mapName: mapName,
        poiId: poiId,
        poiName: poiName,
      );
    }

    final blueprintCounts = <String, int>{};
    final conditionCounts = <String, int>{};
    final sourceCounts = <String, int>{};
    final blueprintLabels = <String, String>{};
    DateTime? lastReportedAt;

    for (final report in reports) {
      blueprintCounts.update(
        report.blueprintId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      blueprintLabels[report.blueprintId] = report.blueprintId;

      final conditionLabel = (report.conditionLabel?.trim().isNotEmpty ?? false)
          ? report.conditionLabel!.trim()
          : 'No Special Condition';
      conditionCounts.update(
        conditionLabel,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      sourceCounts.update(
        report.sourceType.label,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      final createdAt = report.createdAt;
      if (createdAt != null &&
          (lastReportedAt == null || createdAt.isAfter(lastReportedAt))) {
        lastReportedAt = createdAt;
      }
    }

    final totalReports = reports.length;

    List<ArcStatsBreakdownItem> buildBreakdown(
      Map<String, int> counts, {
      Map<String, String>? labels,
    }) {
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
              label: labels?[entry.key] ?? entry.key,
              count: entry.value,
              percentage: totalReports <= 0
                  ? 0
                  : (entry.value / totalReports) * 100,
            ),
          )
          .toList(growable: false);
    }

    final blueprintBreakdown = buildBreakdown(
      blueprintCounts,
      labels: blueprintLabels,
    );
    final conditionBreakdown = buildBreakdown(conditionCounts);
    final sourceBreakdown = buildBreakdown(sourceCounts);

    return ArcPoiDropStats(
      id: '${_slugify(mapName)}__$poiId',
      mapName: mapName,
      poiId: poiId,
      poiName: poiName,
      totalReports: totalReports,
      blueprintBreakdown: blueprintBreakdown,
      conditionBreakdown: conditionBreakdown,
      sourceBreakdown: sourceBreakdown,
      topBlueprintId: blueprintBreakdown.isEmpty
          ? null
          : blueprintBreakdown.first.key,
      topBlueprintLabel: blueprintBreakdown.isEmpty
          ? null
          : blueprintBreakdown.first.label,
      topConditionLabel: conditionBreakdown.isEmpty
          ? null
          : conditionBreakdown.first.label,
      lastReportedAt: lastReportedAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mapName': mapName,
      'poiId': poiId,
      'poiName': poiName,
      'totalReports': totalReports,
      'blueprintBreakdown': blueprintBreakdown
          .map((item) => item.toMap())
          .toList(growable: false),
      'conditionBreakdown': conditionBreakdown
          .map((item) => item.toMap())
          .toList(growable: false),
      'sourceBreakdown': sourceBreakdown
          .map((item) => item.toMap())
          .toList(growable: false),
      'topBlueprintId': topBlueprintId,
      'topBlueprintLabel': topBlueprintLabel,
      'topConditionLabel': topConditionLabel,
      'lastReportedAt': lastReportedAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory ArcPoiDropStats.fromMap(Map<String, dynamic> map) {
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
      if (value is num) {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      }
      return null;
    }

    return ArcPoiDropStats(
      id: (map['id'] as String?) ?? '',
      mapName: (map['mapName'] as String?) ?? '',
      poiId: (map['poiId'] as String?) ?? '',
      poiName: (map['poiName'] as String?) ?? '',
      totalReports: (map['totalReports'] as num?)?.toInt() ?? 0,
      blueprintBreakdown: parseList(map['blueprintBreakdown']),
      conditionBreakdown: parseList(map['conditionBreakdown']),
      sourceBreakdown: parseList(map['sourceBreakdown']),
      topBlueprintId: map['topBlueprintId'] as String?,
      topBlueprintLabel: map['topBlueprintLabel'] as String?,
      topConditionLabel: map['topConditionLabel'] as String?,
      lastReportedAt: fromMillis(map['lastReportedAt']),
      updatedAt: fromMillis(map['updatedAt']),
    );
  }
}

String _slugify(String input) {
  return input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
