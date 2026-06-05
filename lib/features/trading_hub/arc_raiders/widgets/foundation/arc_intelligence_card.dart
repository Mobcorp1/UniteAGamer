import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_glass_panel.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcIntelligenceCard extends StatelessWidget {
  const ArcIntelligenceCard({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    this.actionLabel,
    this.onAction,
    this.accent = AppTheme.neonCyan,
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
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: accent, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTheme.neonTextStyle(
                            fontSize: 17,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          body,
                          style: AppTheme.bodyTextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
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
