import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_glass_panel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcKanbanColumn extends StatelessWidget {
  const ArcKanbanColumn({
    super.key,
    required this.title,
    required this.children,
    this.accent = ArcUiTokens.primaryAccent,
  });

  final String title;
  final List<Widget> children;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ArcGlassPanel(
      accent: accent,
      role: ArcSurfaceRole.raised,
      padding: ArcUiTokens.compactPanelPadding,
      radius: ArcUiTokens.radiusL,
      glow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: ArcUiTokens.label(color: accent)),
          const SizedBox(height: ArcUiTokens.gapM),
          ...children,
        ],
      ),
    );
  }
}
