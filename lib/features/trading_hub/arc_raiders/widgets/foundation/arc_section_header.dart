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
    final heading = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: subtitle == null ? 22 : 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accent, accent.withValues(alpha: 0.18)],
            ),
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 10),
            ],
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: ArcUiTokens.sectionTitle(
                  color: accent,
                ).copyWith(letterSpacing: 0.45),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: ArcUiTokens.gapXS),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ArcUiTokens.bodySmall(),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
