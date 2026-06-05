import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcStatusPill extends StatelessWidget {
  const ArcStatusPill({
    super.key,
    required this.label,
    this.icon,
    this.accent = AppTheme.neonCyan,
    this.isStrong = false,
  });

  final String label;
  final IconData? icon;
  final Color accent;
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isStrong ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTheme.bodyTextStyle(
              fontSize: 11,
              color: isStrong ? Colors.white : accent,
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }
}
