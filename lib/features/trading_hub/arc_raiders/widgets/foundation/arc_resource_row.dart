import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_glass_panel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcResourceRow extends StatelessWidget {
  const ArcResourceRow({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    this.icon,
    this.accent = ArcUiTokens.primaryAccent,
  });

  final String label;
  final int current;
  final int target;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

    return ArcGlassPanel(
      accent: accent,
      role: ArcSurfaceRole.raised,
      padding: ArcUiTokens.compactPanelPadding,
      radius: ArcUiTokens.radiusL,
      glow: false,
      child: Row(
        children: [
          Icon(icon ?? Icons.inventory_2_rounded, color: accent, size: 22),
          const SizedBox(width: ArcUiTokens.gapM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ArcUiTokens.body(
                    fontSize: 13,
                    color: ArcUiTokens.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: ArcUiTokens.gapS),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  color: accent,
                  backgroundColor: ArcUiTokens.borderMedium,
                  borderRadius: BorderRadius.circular(999),
                ),
              ],
            ),
          ),
          const SizedBox(width: ArcUiTokens.gapM),
          Text(
            '$current / $target',
            style: ArcUiTokens.metadata(color: ArcUiTokens.textSecondary),
          ),
        ],
      ),
    );
  }
}
