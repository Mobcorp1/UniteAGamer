import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_glass_panel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcTimelineCard extends StatelessWidget {
  const ArcTimelineCard({
    super.key,
    required this.time,
    required this.title,
    required this.points,
    this.status,
    this.accent = ArcUiTokens.primaryAccent,
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
            style: ArcUiTokens.metadata(color: ArcUiTokens.textSecondary),
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
            role: ArcSurfaceRole.raised,
            padding: ArcUiTokens.compactPanelPadding,
            radius: ArcUiTokens.radiusL,
            glow: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: ArcUiTokens.body(
                          fontSize: 14,
                          weight: FontWeight.w700,
                          color: ArcUiTokens.textPrimary,
                        ),
                      ),
                    ),
                    if (status != null)
                      Text(status!, style: ArcUiTokens.label(color: accent)),
                  ],
                ),
                const SizedBox(height: ArcUiTokens.gapS),
                for (final point in points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text('• $point', style: ArcUiTokens.bodySmall()),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
