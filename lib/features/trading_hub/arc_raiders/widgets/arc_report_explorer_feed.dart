import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/utils/arc_labels.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcReportExplorerFeed extends StatelessWidget {
  const ArcReportExplorerFeed({
    super.key,
    required this.reports,
  });

  final List<ArcBlueprintDropReport> reports;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: AppTheme.tradingCardDecoration(
        radius: 18,
        borderColor: AppTheme.neonCyan.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtered Reports',
            style: AppTheme.tradingHeading(
              fontSize: 20,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            '${reports.length} report${reports.length == 1 ? '' : 's'} match the current filters.',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: AppTheme.spaceM),
          if (reports.isEmpty)
            const Text(
              'No reports match these filters yet.',
              style: TextStyle(color: Colors.white60),
            )
          else
            ...reports.map((report) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
                  child: _ReportCard(report: report),
                )),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final ArcBlueprintDropReport report;

  @override
  Widget build(BuildContext context) {
    final blueprintName = _blueprintNameForId(report.blueprintId);
    final condition = (report.conditionLabel?.trim().isNotEmpty ?? false)
        ? report.conditionLabel!.trim()
        : 'No Special Condition';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: AppTheme.tradingCardDecoration(
        radius: 16,
        borderColor: AppTheme.neonPink.withValues(alpha: 0.12),
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
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _InfoPill(label: ArcLabels.sourceType(report.sourceType)),
              _InfoPill(label: report.resolvedContainerLabel),
              _InfoPill(label: report.raidType.label),
              _InfoPill(label: report.timeOfDay.label),
              _InfoPill(label: condition),
            ],
          ),
          if (report.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              report.notes.trim(),
              style: const TextStyle(
                color: Colors.white70,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _blueprintNameForId(String blueprintId) {
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (blueprint.id == blueprintId) return blueprint.name;
    }
    return blueprintId;
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: AppTheme.tradingPillDecoration(
        color: AppTheme.neonPink.withValues(alpha: 0.9),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
