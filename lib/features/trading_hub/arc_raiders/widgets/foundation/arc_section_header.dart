import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcSectionHeader extends StatelessWidget {
  const ArcSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.accent = AppTheme.neonCyan,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: AppTheme.neonTextStyle(fontSize: 17, color: accent),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: AppTheme.bodyTextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
