import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_sighting_aggregator.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcBlueprintSightingActivity extends StatelessWidget {
  const ArcBlueprintSightingActivity({required this.activity, super.key});

  final ArcBlueprintLocationActivity activity;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'LIVE SIGHTING ACTIVITY',
                style: AppTheme.bodyTextStyle(
                  fontSize: 10,
                  color: AppTheme.neonCyan,
                  isBold: true,
                ),
              ),
            ),
            _trendPill(activity.trend),
          ],
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _metric(
              '${activity.findsLast24Hours}',
              'Last 24h',
              Icons.bolt_rounded,
            ),
            _metric(
              '${activity.findsLast7Days}',
              'Last 7 days',
              Icons.calendar_view_week_rounded,
            ),
            _metric(
              '${activity.totalFinds}',
              'Total finds',
              Icons.inventory_2_rounded,
            ),
            _metric(
              '${activity.contributorCount}',
              'Contributors',
              Icons.groups_rounded,
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final sighting in activity.sightings) _sightingRow(sighting, now),
      ],
    );
  }

  Widget _sightingRow(ArcBlueprintSightingSummary sighting, DateTime now) {
    final blueprint = _blueprint(sighting.blueprintId);
    final imagePath = blueprint?.imageAssetPath;
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.cardBackgroundDeep,
              border: Border.all(
                color: _trendColor(sighting.trend).withValues(alpha: 0.6),
              ),
            ),
            child: imagePath == null || imagePath.trim().isEmpty
                ? Icon(
                    blueprint?.icon ?? Icons.extension_rounded,
                    size: 19,
                    color: Colors.white70,
                  )
                : Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      blueprint?.icon ?? Icons.extension_rounded,
                      size: 19,
                      color: Colors.white70,
                    ),
                  ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blueprint?.name ?? sighting.blueprintId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sighting.recencyLabel(now),
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${sighting.totalFinds} ${sighting.totalFinds == 1 ? 'find' : 'finds'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${sighting.findsLast7Days} this week',
                style: TextStyle(
                  color: _trendColor(sighting.trend),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label, IconData icon) {
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.neonCyan.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppTheme.neonCyan),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _trendPill(ArcBlueprintSightingTrend trend) {
    final color = _trendColor(trend);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        trend.label.toUpperCase(),
        style: AppTheme.bodyTextStyle(fontSize: 9, color: color, isBold: true),
      ),
    );
  }

  ArcBlueprint? _blueprint(String id) {
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      if (blueprint.id == id) return blueprint;
    }
    return null;
  }

  Color _trendColor(ArcBlueprintSightingTrend trend) {
    switch (trend) {
      case ArcBlueprintSightingTrend.surging:
        return AppTheme.neonPink;
      case ArcBlueprintSightingTrend.active:
        return Colors.lightGreenAccent;
      case ArcBlueprintSightingTrend.steady:
        return AppTheme.neonCyan;
      case ArcBlueprintSightingTrend.cooling:
        return Colors.amberAccent;
      case ArcBlueprintSightingTrend.seeded:
        return Colors.white54;
    }
  }
}
