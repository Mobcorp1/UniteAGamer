import 'package:flutter/material.dart';

import '../../../../widgets/theme.dart';

class ArcLoadoutProgressCard extends StatelessWidget {
  const ArcLoadoutProgressCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.tradingCardDecoration(
          radius: 20,
          borderColor: color.withValues(alpha: 0.25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: AppTheme.tradingHeading(fontSize: 11, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTheme.tradingHeading(fontSize: 22, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
