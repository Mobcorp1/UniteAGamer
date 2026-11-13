import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_glass_panel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcIntelligenceCard extends StatelessWidget {
  const ArcIntelligenceCard({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    this.actionLabel,
    this.onAction,
    this.accent = ArcUiTokens.primaryAccent,
    this.backgroundAsset,
  });

  final String title;
  final String body;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accent;
  final String? backgroundAsset;

  @override
  Widget build(BuildContext context) {
    return ArcGlassPanel(
      accent: accent,
      role: ArcSurfaceRole.interactive,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ArcUiTokens.radiusL),
        child: Stack(
          children: [
            if (backgroundAsset != null)
              Positioned.fill(
                child: Image.asset(
                  backgroundAsset!,
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.24),
                ),
              ),
            Padding(
              padding: ArcUiTokens.panelPadding,
              child: Row(
                children: [
                  Icon(icon, color: accent, size: 30),
                  const SizedBox(width: ArcUiTokens.gapM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: ArcUiTokens.cardTitle(color: accent),
                        ),
                        const SizedBox(height: ArcUiTokens.gapXS),
                        Text(
                          body,
                          style: ArcUiTokens.bodySmall(
                            color: ArcUiTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (actionLabel != null && onAction != null)
                    IconButton(
                      onPressed: onAction,
                      icon: Icon(Icons.chevron_right_rounded, color: accent),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
