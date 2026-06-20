import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_cinematic_background.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcCinematicScaffold extends StatelessWidget {
  const ArcCinematicScaffold({
    super.key,
    required this.child,
    this.accent = AppTheme.neonCyan,
    this.backgroundAsset,
    this.showWatermark = true,
    this.padding = ArcUiTokens.screenPadding,
  });

  final Widget child;
  final Color accent;
  final String? backgroundAsset;
  final bool showWatermark;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        UagCinematicBackground(
          accent: accent,
          backgroundAsset: backgroundAsset ?? UagVisualAssets.arcBackground,
          showWatermark: showWatermark,
          showGrid: false,
        ),
        SafeArea(
          child: Padding(padding: padding, child: child),
        ),
      ],
    );
  }
}
