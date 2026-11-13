import 'package:flutter/material.dart';

import '../../../../widgets/theme.dart';

class ArcReadinessStatusBanner extends StatelessWidget {
  const ArcReadinessStatusBanner({
    super.key,
    required this.readinessPercent,
    required this.status,
  });

  final int readinessPercent;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = readinessPercent >= 85
        ? Colors.greenAccent
        : readinessPercent >= 60
        ? Colors.orangeAccent
        : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.tradingCardDecoration(
        radius: 24,
        borderColor: color.withValues(alpha: 0.30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RAID READINESS',
            style: AppTheme.tradingHeading(fontSize: 14, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            '$readinessPercent%',
            style: AppTheme.tradingHeading(fontSize: 32, color: Colors.white),
          ),
          const SizedBox(height: 4),
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
    );
  }
}
