import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcStatusPill extends StatelessWidget {
  const ArcStatusPill({
    super.key,
    required this.label,
    this.icon,
    this.accent = ArcUiTokens.primaryAccent,
    this.tone,
    this.isStrong = false,
  });

  final String label;
  final IconData? icon;
  final Color accent;
  final ArcSemanticTone? tone;
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    final color = tone == null ? accent : ArcUiTokens.tone(tone!);

    return Container(
      padding: ArcUiTokens.chipPadding,
      decoration: ArcUiTokens.chipDecoration(color: color, selected: isStrong),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: isStrong ? ArcUiTokens.textPrimary : color,
            ),
            const SizedBox(width: ArcUiTokens.gapS),
          ],
          Text(
            label,
            style: ArcUiTokens.label(
              color: isStrong ? ArcUiTokens.textPrimary : color,
            ),
          ),
        ],
      ),
    );
  }
}
