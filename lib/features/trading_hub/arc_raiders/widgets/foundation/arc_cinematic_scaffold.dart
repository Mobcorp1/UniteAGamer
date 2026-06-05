import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/static_watermark.dart';
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
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.darkBackground,
            image: backgroundAsset == null
                ? null
                : DecorationImage(
                    image: AssetImage(backgroundAsset!),
                    fit: BoxFit.cover,
                    opacity: 0.24,
                  ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.45),
              radius: 1.25,
              colors: [
                accent.withValues(alpha: 0.18),
                AppTheme.darkBackground.withValues(alpha: 0.84),
                Colors.black.withValues(alpha: 0.96),
              ],
            ),
          ),
        ),
        if (showWatermark)
          const Positioned.fill(
            child: IgnorePointer(
              child: Opacity(opacity: 0.14, child: StaticWatermark()),
            ),
          ),
        SafeArea(
          child: Padding(padding: padding, child: child),
        ),
      ],
    );
  }
}
