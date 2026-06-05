import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcActionButton extends StatelessWidget {
  const ArcActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.accent = AppTheme.neonPink,
    this.expand = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color accent;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = TextButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: accent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        textStyle: AppTheme.bodyTextStyle(
          fontSize: 12,
          isBold: true,
          color: accent,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: accent.withValues(alpha: 0.58)),
        ),
        backgroundColor: accent.withValues(alpha: 0.08),
      ),
    );

    return expand ? Expanded(child: child) : child;
  }
}
