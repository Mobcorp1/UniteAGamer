import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcGlassPanel extends StatelessWidget {
  const ArcGlassPanel({
    super.key,
    required this.child,
    this.accent = AppTheme.neonCyan,
    this.padding = ArcUiTokens.panelPadding,
    this.radius = ArcUiTokens.radiusL,
    this.borderOpacity = 0.36,
    this.glow = true,
  });

  final Widget child;
  final Color accent;
  final EdgeInsets padding;
  final double radius;
  final double borderOpacity;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: ArcUiTokens.darkGlassGradient(accent: accent),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: accent.withValues(alpha: borderOpacity),
          width: 1.1,
        ),
        boxShadow: glow ? ArcUiTokens.glow(accent) : null,
      ),
      child: child,
    );
  }
}
