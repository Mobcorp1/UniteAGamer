import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcSectionHeader extends StatelessWidget {
  const ArcSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.accent = ArcUiTokens.primaryAccent,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: ArcUiTokens.sectionTitle(color: accent),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: ArcUiTokens.gapXS),
          Text(subtitle!, style: ArcUiTokens.bodySmall()),
        ],
      ],
    );
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use the panel's width, including when it is inside a desktop grid.
          final stacked =
              constraints.maxWidth < 480 ||
              MediaQuery.textScalerOf(context).scale(16) > 24;
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                if (trailing != null) ...[
                  const SizedBox(height: ArcUiTokens.gapS),
                  trailing!,
                ],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: heading),
              if (trailing != null) ...[
                const SizedBox(width: ArcUiTokens.gapM),
                trailing!,
              ],
            ],
          );
        },
      ),
    );
  }
}
