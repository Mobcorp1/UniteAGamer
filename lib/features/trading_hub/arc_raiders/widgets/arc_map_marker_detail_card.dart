import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/arc_map_filter_icon.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcMapMarkerDetailCard extends StatelessWidget {
  const ArcMapMarkerDetailCard({required this.marker, this.footer, super.key});

  final ArcRaidMapMarker marker;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: marker.semanticLabel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spaceM),
        decoration: AppTheme.tradingCardDecoration(
          borderColor: _color.withValues(alpha: 0.34),
          backgroundColor: Colors.black.withValues(alpha: 0.24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _color.withValues(alpha: 0.14),
                    border: Border.all(color: _color.withValues(alpha: 0.44)),
                  ),
                  child: ArcMapFilterIcon(
                    iconKey: marker.iconKey,
                    category: marker.category,
                    color: _color,
                    size: 22,
                    semanticLabel: marker.category.label,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marker.label,
                        style: AppTheme.tradingHeading(
                          fontSize: 18,
                          color: _color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${marker.category.label} • ${marker.layer.label}',
                        style: AppTheme.bodyTextStyle(
                          fontSize: 12,
                          color: AppTheme.tradingMutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceM),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill(
                  marker.confidence.label,
                  marker.confidence.score >= 70
                      ? Colors.lightGreenAccent
                      : AppTheme.neonCyan,
                ),
                _pill(
                  marker.approximate ? 'Approximate' : 'Calibrated',
                  marker.approximate
                      ? Colors.amberAccent
                      : Colors.lightGreenAccent,
                ),
                if (marker.isCluster)
                  _pill('${marker.count} grouped', AppTheme.neonPink),
                _pill(
                  '${(marker.point.x * 100).toStringAsFixed(1)}, ${(marker.point.y * 100).toStringAsFixed(1)}',
                  Colors.white70,
                ),
              ],
            ),
            if (marker.detail.trim().isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceM),
              Text(
                marker.detail,
                style: AppTheme.bodyTextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
            if (marker.tags.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceM),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in marker.tags.take(6))
                    _pill(tag, AppTheme.neonCyan),
                ],
              ),
            ],
            if (footer != null) ...[
              const SizedBox(height: AppTheme.spaceM),
              footer!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: AppTheme.bodyTextStyle(fontSize: 11, color: color, isBold: true),
      ),
    );
  }

  Color get _color {
    switch (marker.category.filteringGroup) {
      case 'My Objectives':
        return AppTheme.neonPink;
      case 'Loot Sources':
        return Colors.amberAccent;
      case 'Intel Quality':
        return marker.confidence.score >= 70
            ? Colors.lightGreenAccent
            : AppTheme.neonCyan;
      default:
        return AppTheme.neonCyan;
    }
  }
}
