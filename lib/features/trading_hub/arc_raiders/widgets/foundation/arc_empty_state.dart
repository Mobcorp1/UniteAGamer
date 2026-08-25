import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_glass_panel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcEmptyState extends StatelessWidget {
  const ArcEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.radar_rounded,
    this.accent = ArcUiTokens.primaryAccent,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ArcGlassPanel(
      accent: accent,
      role: ArcSurfaceRole.raised,
      padding: const EdgeInsets.all(ArcUiTokens.gapXXL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 38),
          const SizedBox(height: ArcUiTokens.gapM),
          Text(
            title,
            style: ArcUiTokens.sectionTitle(fontSize: 18, color: accent),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ArcUiTokens.gapS),
          Text(
            message,
            style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
