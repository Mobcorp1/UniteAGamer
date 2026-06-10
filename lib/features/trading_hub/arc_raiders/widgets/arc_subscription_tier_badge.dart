import 'package:flutter/material.dart';

import '../../../../widgets/theme.dart';

class ArcSubscriptionTierBadge extends StatelessWidget {
  const ArcSubscriptionTierBadge({
    super.key,
    required this.label,
    required this.color,
    required this.description,
  });

  final String label;
  final Color color;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.tradingCardDecoration(
        radius: 22,
        borderColor: color.withValues(alpha: 0.30),
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.92),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTheme.tradingHeading(fontSize: 15, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: AppTheme.bodyTextStyle(
              fontSize: 12,
              color: Colors.white70,
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }
}
