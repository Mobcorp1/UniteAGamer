import 'package:flutter/material.dart';

import '../../../../widgets/theme.dart';

class ArcScrappyStatusBanner extends StatelessWidget {
  const ArcScrappyStatusBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.tradingCardDecoration(
        radius: 24,
        borderColor: color.withValues(alpha: 0.28),
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.92),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: AppTheme.tradingPillDecoration(color: color),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: AppTheme.tradingHeading(fontSize: 15, color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    isBold: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
