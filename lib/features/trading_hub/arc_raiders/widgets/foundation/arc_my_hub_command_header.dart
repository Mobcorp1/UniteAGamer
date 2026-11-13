import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_glass_panel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_status_pill.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcMyHubCommandHeader extends StatelessWidget {
  const ArcMyHubCommandHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.accent = ArcUiTokens.primaryAccent,
  });

  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ArcGlassPanel(
      accent: accent,
      role: ArcSurfaceRole.interactive,
      selected: true,
      radius: ArcUiTokens.radiusXXL,
      padding: ArcUiTokens.panelPadding,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.10),
              border: Border.all(color: accent.withValues(alpha: 0.48)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.10),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Icon(Icons.radar_rounded, color: accent, size: 26),
          ),
          const SizedBox(width: ArcUiTokens.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.sectionTitle(fontSize: 20, color: accent),
                ),
                const SizedBox(height: ArcUiTokens.gapXS),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.bodySmall(
                    color: ArcUiTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const ArcStatusPill(
            label: 'PERSONAL',
            icon: Icons.person_pin_circle_rounded,
            tone: ArcSemanticTone.secondary,
            isStrong: true,
          ),
        ],
      ),
    );
  }
}
