import 'package:flutter/material.dart';

import '../../../../widgets/theme.dart';

class ArcProfileStatusCard extends StatelessWidget {
  const ArcProfileStatusCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.tradingCardDecoration(
        radius: 20,
        borderColor: color.withValues(alpha: 0.28),
        backgroundColor: AppTheme.cardBackgroundDeep.withValues(alpha: 0.88),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: AppTheme.tradingPillDecoration(color: color),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: AppTheme.bodyTextStyle(
                    fontSize: 10,
                    color: color,
                    isBold: true,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTheme.tradingHeading(
                    fontSize: 15,
                    color: Colors.white,
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
