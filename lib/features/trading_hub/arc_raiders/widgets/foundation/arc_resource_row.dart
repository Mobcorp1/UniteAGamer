import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_glass_panel.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcResourceRow extends StatelessWidget {
  const ArcResourceRow({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    this.icon,
    this.accent = AppTheme.neonCyan,
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
      padding: const EdgeInsets.all(12),
      radius: 16,
      glow: false,
      child: Row(
        children: [
          Icon(icon ?? Icons.inventory_2_rounded, color: accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 13,
                    isBold: true,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 7),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  color: accent,
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$current / $target',
            style: AppTheme.bodyTextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}
