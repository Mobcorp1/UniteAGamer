import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_glass_panel.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_status_pill.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcMyHubIntelligenceFeed extends StatelessWidget {
  const ArcMyHubIntelligenceFeed({
    super.key,
    this.missingBlueprints = 0,
    this.duplicateBlueprints = 0,
    this.tradeHooks = 0,
    this.activeIntel = 0,
    this.accent = AppTheme.neonCyan,
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
      padding: const EdgeInsets.all(14),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_alt_rounded, color: accent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'PERSONAL INTELLIGENCE',
                  style: AppTheme.neonTextStyle(fontSize: 16, color: accent),
                ),
              ),
              ArcStatusPill(
                label: 'LIVE',
                accent: AppTheme.neonPink,
                isStrong: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Your hub now acts as the personal layer: tracking progress, trade opportunities, intel and next actions without turning every system into manual admin.',
            style: AppTheme.bodyTextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ArcStatusPill(
                icon: Icons.grid_on_rounded,
                label: 'Blueprints',
                accent: AppTheme.neonCyan,
              ),
              ArcStatusPill(
                icon: Icons.swap_horiz_rounded,
                label: 'Trade hooks',
                accent: AppTheme.neonPink,
              ),
              ArcStatusPill(
                icon: Icons.radar_rounded,
                label: 'Intel',
                accent: Colors.amberAccent,
              ),
              ArcStatusPill(
                icon: Icons.route_rounded,
                label: 'Raid windows',
                accent: Colors.lightGreenAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
