import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/widgets/foundation/arc_ui_tokens.dart';
import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_cinematic_background.dart';

/// Canonical full-screen visual foundation for every route.
///
/// This widget is mounted once above the Navigator in [MaterialApp.builder].
/// Individual screens must not add a second copy of this backdrop. That keeps
/// cinematic imagery, lighting and background policy consistent across mobile,
/// web and desktop and prevents the old double-background/watermark effect.
class ArcBlueprintGridBackground extends StatelessWidget {
  const ArcBlueprintGridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: ArcUiTokens.background),
        const UagCinematicBackground(
          backgroundAsset: UagVisualAssets.arcBackground,
          backgroundOpacity: 0.20,
          // Static UAG watermarking is deliberately disabled. Cinematic art is
          // allowed to breathe and the brand is carried by the app chrome.
          watermarkOpacity: 0.0,
          showGrid: false,
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ArcUiTokens.primaryAccent.withValues(alpha: 0.055),
                  Colors.transparent,
                  ArcUiTokens.secondaryAccent.withValues(alpha: 0.040),
                ],
                stops: const [0.0, 0.48, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.72, -0.86),
                radius: 1.08,
                colors: [
                  ArcUiTokens.primaryAccent.withValues(alpha: 0.065),
                  ArcUiTokens.primaryAccent.withValues(alpha: 0.015),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.42, 1.0],
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  ArcUiTokens.background.withValues(alpha: 0.34),
                  ArcUiTokens.background.withValues(alpha: 0.82),
                ],
                stops: const [0.0, 0.62, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Applied once above the Navigator so every route inherits the same backdrop.
class ArcGlobalVisualSystem extends StatelessWidget {
  const ArcGlobalVisualSystem({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(child: ArcBlueprintGridBackground()),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// Canonical translucent surface for cards, carousel pages and grouped content.
class ArcVisualSurface extends StatelessWidget {
  const ArcVisualSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spaceL),
    this.radius = ArcUiTokens.radiusXL,
    this.accent = ArcUiTokens.primaryAccent,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color accent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppTheme.fastAnimation,
      padding: padding,
      decoration: ArcUiTokens.surfaceDecoration(
        role: ArcSurfaceRole.panel,
        radius: radius,
        accent: accent,
        borderOpacity: 0.16,
        selected: selected,
        glow: selected,
      ),
      child: child,
    );
  }
}

/// Shared perimeter-current treatment for the single next actionable element.
class ArcElectricActionBorder extends StatelessWidget {
  const ArcElectricActionBorder({
    super.key,
    required this.child,
    required this.active,
    this.radius = ArcUiTokens.radiusXL,
  });

  final Widget child;
  final bool active;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return ElectricChargeBorder(
      active: active && !disableAnimations,
      radius: radius,
      child: child,
    );
  }
}
