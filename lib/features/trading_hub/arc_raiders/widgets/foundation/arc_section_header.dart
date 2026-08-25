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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
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
          ),
        ),
        ?trailing,
      ],
    );
  }
}
