import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_market_snapshot.dart';

class ArcMarketSnapshotService {
  const ArcMarketSnapshotService();

  ArcMarketSnapshot build(List<ArcBlueprintDropReport> reports) {
    if (reports.isEmpty) return ArcMarketSnapshot.empty();

    final blueprintCounts = <String, int>{};
    final mapCounts = <String, int>{};
    final conditionCounts = <String, int>{};
    final sourceCounts = <String, int>{};
    final reporters = <String>{};

    DateTime? lastReportedAt;

    for (final report in reports) {
      final blueprintLabel = _blueprintNameForId(report.blueprintId);
      blueprintCounts.update(
        blueprintLabel,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      final mapLabel = report.mapName.trim().isEmpty
          ? 'Unknown Map'
          : report.mapName.trim();
      mapCounts.update(mapLabel, (value) => value + 1, ifAbsent: () => 1);

      final conditionLabel = (report.conditionLabel?.trim().isNotEmpty ?? false)
          ? report.conditionLabel!.trim()
          : 'No Special Condition';
      conditionCounts.update(
        conditionLabel,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      final sourceLabel = _sourceTypeLabel(report.sourceType);
      sourceCounts.update(sourceLabel, (value) => value + 1, ifAbsent: () => 1);

      reporters.add(report.userId);

      final createdAt = report.createdAt ?? report.foundAt;
      if (createdAt != null &&
          (lastReportedAt == null || createdAt.isAfter(lastReportedAt))) {
        lastReportedAt = createdAt;
      }
    }

    final sortedReports = List<ArcBlueprintDropReport>.from(reports)
      ..sort((a, b) {
        final aTime =
            a.createdAt ?? a.foundAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.createdAt ?? b.foundAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    final blueprintBreakdown = _buildBreakdown(blueprintCounts, reports.length);
    final mapBreakdown = _buildBreakdown(mapCounts, reports.length);
    final conditionBreakdown = _buildBreakdown(conditionCounts, reports.length);
    final sourceBreakdown = _buildBreakdown(sourceCounts, reports.length);

    return ArcMarketSnapshot(
      totalReports: reports.length,
      uniqueBlueprints: blueprintCounts.length,
      uniqueMaps: mapCounts.length,
      uniqueReporters: reporters.length,
      blueprintBreakdown: blueprintBreakdown,
      mapBreakdown: mapBreakdown,
      conditionBreakdown: conditionBreakdown,
      sourceBreakdown: sourceBreakdown,
      recentReports: sortedReports.take(10).toList(growable: false),
      topBlueprintLabel: blueprintBreakdown.isEmpty
          ? null
          : blueprintBreakdown.first.label,
      topMapLabel: mapBreakdown.isEmpty ? null : mapBreakdown.first.label,
      topConditionLabel: conditionBreakdown.isEmpty
          ? null
          : conditionBreakdown.first.label,
      lastReportedAt: lastReportedAt,
    );
  }

  List<ArcMarketSnapshotEntry> _buildBreakdown(
    Map<String, int> counts,
    int totalReports,
  ) {
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        if (countCompare != 0) return countCompare;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    return entries
        .map(
          (entry) => ArcMarketSnapshotEntry(
            key: entry.key,
            label: entry.key,
            count: entry.value,
            percentage: totalReports == 0
                ? 0
                : (entry.value / totalReports) * 100,
          ),
        )
        .toList(growable: false);
  }

  String _blueprintNameForId(String blueprintId) {
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (blueprint.id == blueprintId) return blueprint.name;
    }
    return blueprintId;
  }

  String _sourceTypeLabel(dynamic sourceType) {
    final raw = sourceType.toString().split('.').last;
    switch (raw) {
      case 'poi':
        return 'POI';
      case 'enemy':
        return 'Enemy';
      case 'other':
        return 'Other';
      default:
        return raw.isEmpty ? 'Unknown' : raw;
    }
  }
}
