import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_glass_panel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_status_pill.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcMyHubIntelligenceFeed extends StatelessWidget {
  const ArcMyHubIntelligenceFeed({
    super.key,
    this.missingBlueprints = 0,
    this.duplicateBlueprints = 0,
    this.tradeHooks = 0,
    this.activeIntel = 0,
    this.accent = ArcUiTokens.primaryAccent,
  });

  final int missingBlueprints;
  final int duplicateBlueprints;
  final int tradeHooks;
  final int activeIntel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ArcGlassPanel(
      accent: accent,
      role: ArcSurfaceRole.raised,
      padding: ArcUiTokens.panelPadding,
      radius: ArcUiTokens.radiusXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_alt_rounded, color: accent, size: 24),
              const SizedBox(width: ArcUiTokens.gapM),
              Expanded(
                child: Text(
                  'PERSONAL INTELLIGENCE',
                  style: ArcUiTokens.cardTitle(color: accent),
                ),
              ),
              const ArcStatusPill(
                label: 'LIVE',
                tone: ArcSemanticTone.secondary,
                isStrong: true,
              ),
            ],
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          Text(
            'Your hub now acts as the personal layer: tracking progress, trade opportunities, intel and next actions without turning every system into manual admin.',
            style: ArcUiTokens.bodySmall(color: ArcUiTokens.textSecondary),
          ),
          const SizedBox(height: ArcUiTokens.gapM),
          Wrap(
            spacing: ArcUiTokens.gapS,
            runSpacing: ArcUiTokens.gapS,
            children: const [
              ArcStatusPill(
                icon: Icons.grid_on_rounded,
                label: 'Blueprints',
                tone: ArcSemanticTone.primary,
              ),
              ArcStatusPill(
                icon: Icons.swap_horiz_rounded,
                label: 'Trade hooks',
                tone: ArcSemanticTone.secondary,
              ),
              ArcStatusPill(
                icon: Icons.radar_rounded,
                label: 'Intel',
                tone: ArcSemanticTone.warning,
              ),
              ArcStatusPill(
                icon: Icons.route_rounded,
                label: 'Raid windows',
                tone: ArcSemanticTone.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
