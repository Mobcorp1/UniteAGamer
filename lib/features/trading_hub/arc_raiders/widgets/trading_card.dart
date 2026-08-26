import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class TradingCard extends StatelessWidget {
  const TradingCard({
    super.key,
    required this.child,
    this.onTap,
    this.trailing,
    this.accent,
    this.padding = ArcUiTokens.compactPanelPadding,
    this.margin,
    this.radius = ArcUiTokens.radiusM,
    this.selected = false,
    this.compact = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      margin: margin,
      padding: compact ? ArcUiTokens.densePanelPadding : padding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: selected ? ArcSurfaceRole.interactive : ArcSurfaceRole.panel,
        accent: accent,
        radius: radius,
        borderOpacity: accent == null ? 0.10 : 0.24,
        selected: selected,
        glow: selected && accent != null,
      ),
      child: trailing == null
          ? child
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: child),
                const SizedBox(width: AppTheme.spaceM),
                trailing!,
              ],
            ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
