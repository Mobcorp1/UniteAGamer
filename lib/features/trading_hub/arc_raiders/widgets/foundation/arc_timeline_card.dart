import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_glass_panel.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcTimelineCard extends StatelessWidget {
  const ArcTimelineCard({
    super.key,
    required this.time,
    required this.title,
    required this.points,
    this.status,
    this.accent = AppTheme.neonCyan,
  });

  final String time;
  final String title;
  final List<String> points;
  final String? status;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Text(
            time,
            style: AppTheme.bodyTextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ),
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            Container(
              width: 1,
              height: 92,
              color: accent.withValues(alpha: 0.35),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ArcGlassPanel(
            accent: accent,
            padding: const EdgeInsets.all(14),
            radius: 16,
            glow: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTheme.bodyTextStyle(
                          fontSize: 14,
                          isBold: true,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (status != null)
                      Text(
                        status!,
                        style: AppTheme.neonTextStyle(
                          fontSize: 12,
                          color: accent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                for (final point in points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '• $point',
                      style: AppTheme.bodyTextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.68),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
