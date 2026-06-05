import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_glass_panel.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcEmptyState extends StatelessWidget {
  const ArcEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.radar_rounded,
    this.accent = AppTheme.neonCyan,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ArcGlassPanel(
      accent: accent,
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 38),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTheme.neonTextStyle(fontSize: 18, color: accent),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTheme.bodyTextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.70),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
