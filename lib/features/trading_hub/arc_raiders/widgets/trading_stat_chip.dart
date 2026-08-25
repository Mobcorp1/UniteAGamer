import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class TradingStatChip extends StatelessWidget {
  const TradingStatChip({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color = AppTheme.neonCyan,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 7 : 9,
      ),
      decoration: AppTheme.tradingPillDecoration(color: color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 14 : 16, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            value,
            style: AppTheme.tradingHeading(
              fontSize: compact ? 13 : 15,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.bodyTextStyle(
              fontSize: compact ? 10 : 11,
              color: AppTheme.tradingMutedText,
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }
}
