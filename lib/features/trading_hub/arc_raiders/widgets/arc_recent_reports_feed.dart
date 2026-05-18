import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/utils/arc_labels.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcRecentReportsFeed extends StatelessWidget {
  const ArcRecentReportsFeed({
    super.key,
    required this.reports,
    this.maxItems = 8,
  });

  final List<ArcBlueprintDropReport> reports;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spaceL),
        decoration: AppTheme.tradingCardDecoration(
          radius: 18,
          borderColor: AppTheme.neonCyan.withValues(alpha: 0.18),
        ),
        child: const Text(
          'No recent reports yet. Once players start logging blueprint finds, they will appear here.',
          style: TextStyle(color: Colors.white70, height: 1.35),
        ),
      );
    }

    final visibleReports = reports.take(maxItems).toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(
        radius: 18,
        borderColor: AppTheme.neonPink.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Community Reports',
            style: AppTheme.tradingHeading(
              fontSize: 20,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          ...visibleReports.map(
            (report) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
              child: _ReportRow(report: report),
            ),
          ),
        ],
      ),
    );
  }

  static String blueprintNameForId(String blueprintId) {
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (blueprint.id == blueprintId) return blueprint.name;
    }
    return blueprintId;
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report});

  final ArcBlueprintDropReport report;

  @override
  Widget build(BuildContext context) {
    final blueprintName = ArcRecentReportsFeed.blueprintNameForId(
      report.blueprintId,
    );
    final weather = ArcLabels.fallbackWeather(report.weatherConditionLabel);
    final mapEvent = ArcLabels.fallbackMapEvent(report.mapEventLabel);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        radius: 16,
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            blueprintName,
            style: AppTheme.neonTextStyle(
              fontSize: 16,
              color: AppTheme.neonCyan,
              isBold: true,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${report.mapName} • ${report.areaLabel}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${ArcLabels.sourceType(report.sourceType)} • ${report.resolvedContainerLabel} • ${report.raidType.label} • ${report.timeOfDay.label}',
            style: const TextStyle(color: Colors.white60, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            '$weather • $mapEvent',
            style: const TextStyle(color: Colors.white60, height: 1.3),
          ),
          if (report.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              report.notes.trim(),
              style: const TextStyle(color: Colors.white70, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}
