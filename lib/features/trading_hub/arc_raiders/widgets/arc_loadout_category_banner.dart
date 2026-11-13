import 'package:flutter/material.dart';

import '../../../../widgets/theme.dart';

class ArcLoadoutCategoryBanner extends StatelessWidget {
  const ArcLoadoutCategoryBanner({
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
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.tradingCardDecoration(
        radius: 26,
        borderColor: color.withValues(alpha: 0.30),
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.92),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.tradingPillDecoration(color: color),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: AppTheme.tradingHeading(fontSize: 16, color: color),
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
