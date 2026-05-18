import 'package:flutter/material.dart';

import 'package:uag_traders_hub/widgets/theme.dart';

class BlueprintProgressHeader extends StatelessWidget {
  const BlueprintProgressHeader({
    super.key,
    required this.completion,
    required this.ownedCount,
    required this.missingCount,
    required this.dupesCount,
    required this.totalCount,
    required this.landscape,
    this.onClose,
  });

  final double completion;
  final int ownedCount;
  final int missingCount;
  final int dupesCount;
  final int totalCount;
  final bool landscape;
  final VoidCallback? onClose;

  Widget _statCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.tradingCardBackground,
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: AppTheme.tradingHeading(fontSize: 20, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.sectionCardPadding,
      decoration: AppTheme.tradingCardDecoration(
        borderColor: AppTheme.neonPink.withValues(alpha: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ARC Raiders Blueprint Tracker',
                  style: AppTheme.tradingHeading(
                    fontSize: 24,
                    color: AppTheme.neonCyan,
                  ),
                ),
              ),
              if (onClose != null)
                IconButton(
                  tooltip: 'Hide tracker card',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
            ],
          ),
          Text(
            landscape
                ? 'Tap a missing blueprint to mark it owned. You can then choose to add a drop report and duplicates.'
                : 'Tap a missing blueprint to mark it owned, then choose whether to add a report or duplicates.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard('Owned', ownedCount, AppTheme.neonCyan),
              const SizedBox(width: 10),
              _statCard('Missing', missingCount, AppTheme.neonPink),
              const SizedBox(width: 10),
              _statCard('Dupes', dupesCount, Colors.amberAccent),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: completion,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: Colors.white.withValues(alpha: 0.07),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonPink),
          ),
          const SizedBox(height: 8),
          Text(
            '$ownedCount / $totalCount blueprints logged',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
