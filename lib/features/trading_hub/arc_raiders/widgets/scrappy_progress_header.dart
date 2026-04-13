import 'package:flutter/material.dart';

import 'package:uag_traders_hub/widgets/theme.dart';

class ScrappyProgressHeader extends StatelessWidget {
  const ScrappyProgressHeader({
    super.key,
    required this.completion,
    required this.ownedCount,
    required this.totalCount,
    required this.landscape,
  });

  final double completion;
  final int ownedCount;
  final int totalCount;
  final bool landscape;

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
          Text(
            'ARC Raiders Scrappy Tracker',
            style: AppTheme.tradingHeading(
              fontSize: 26,
              color: AppTheme.neonCyan,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            landscape
                ? 'Track your scrappy materials the same way as the blueprint grid. Tap a missing item for the requirement, tap or hold an owned item to edit dupes.'
                : 'Portrait is supported, but landscape gives you a roomier tracker view for quick updates.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use this to log collection progress and extras you could trade later once the wider resource system is added.',
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: AppTheme.spaceM),
          LinearProgressIndicator(
            value: completion,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: Colors.white.withValues(alpha: 0.07),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonPink),
          ),
          const SizedBox(height: 8),
          Text(
            '$ownedCount / $totalCount scrappy items logged',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
