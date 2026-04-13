import 'package:flutter/material.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_intel_hotspot.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcBlueprintHotspotsCard extends StatelessWidget {
  const ArcBlueprintHotspotsCard({
    super.key,
    required this.hotspots,
    this.maxItems = 10,
  });

  final List<ArcIntelHotspot> hotspots;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
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
            'Hotspot Breakdown',
            style: AppTheme.tradingHeading(
              fontSize: 20,
              color: AppTheme.neonPink,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          const Text(
            'Best current combinations of map, POI and container based on the reports visible in this view.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: AppTheme.spaceM),
          if (hotspots.isEmpty)
            const Text(
              'No hotspot data yet for the selected filters.',
              style: TextStyle(color: Colors.white60),
            )
          else
            ...hotspots.take(maxItems).map(
              (hotspot) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  decoration: AppTheme.tradingCardDecoration(
                    radius: 16,
                    borderColor: AppTheme.neonCyan.withValues(alpha: 0.12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${hotspot.mapName} • ${hotspot.areaLabel}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${hotspot.count} reports',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${hotspot.containerLabel} • ${hotspot.percentageLabel}',
                        style: TextStyle(
                          color: AppTheme.neonCyan.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hotspot.locationPreview?.trim().isNotEmpty ?? false) ...[
                        const SizedBox(height: 6),
                        Text(
                          hotspot.locationPreview!.trim(),
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
