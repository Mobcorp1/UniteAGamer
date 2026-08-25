import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';

class ArcGlassPanel extends StatelessWidget {
  const ArcGlassPanel({
    super.key,
    required this.child,
    this.accent = ArcUiTokens.primaryAccent,
    this.padding = ArcUiTokens.panelPadding,
    this.radius = ArcUiTokens.radiusL,
    this.borderOpacity = 0.16,
    this.glow = false,
    this.selected = false,
    this.role = ArcSurfaceRole.panel,
  });

  final Widget child;
  final Color accent;
  final EdgeInsets padding;
  final double radius;
  final double borderOpacity;
  final bool glow;
  final bool selected;
  final ArcSurfaceRole role;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: padding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: role,
        accent: accent,
        radius: radius,
        borderOpacity: borderOpacity,
        selected: selected,
        glow: glow || selected,
      ),
      child: child,
    );
  }
}
