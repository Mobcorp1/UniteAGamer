import 'package:flutter/material.dart';

import '../../../../widgets/theme.dart';

class ArcMarketPulseCard extends StatelessWidget {
  const ArcMarketPulseCard({
    super.key,
    required this.title,
    required this.status,
    required this.color,
    required this.icon,
  });

  final String title;
  final String status;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.tradingCardDecoration(
        radius: 24,
        borderColor: color.withValues(alpha: 0.28),
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.90),
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
                  status,
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
