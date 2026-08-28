import 'package:flutter/material.dart';

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
        const ColoredBox(color: Color(0xFF020508)),
        const UagCinematicBackground(
          backgroundAsset: UagVisualAssets.arcBackground,
          backgroundOpacity: 0.26,
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
                  AppTheme.neonCyan.withValues(alpha: 0.105),
                  Colors.transparent,
                  AppTheme.neonPink.withValues(alpha: 0.082),
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
                  AppTheme.neonCyan.withValues(alpha: 0.13),
                  AppTheme.neonCyan.withValues(alpha: 0.025),
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
                  const Color(0xFF020508).withValues(alpha: 0.28),
                  const Color(0xFF020508).withValues(alpha: 0.74),
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
    this.radius = AppTheme.cardRadius,
    this.accent = AppTheme.neonCyan,
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
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: accent.withValues(alpha: selected ? 0.92 : 0.42),
          width: selected ? AppTheme.cardOuterBorderWidth : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: selected ? 0.24 : 0.08),
            blurRadius: selected ? AppTheme.glowMedium : 12,
            spreadRadius: selected ? 0.5 : 0,
          ),
        ],
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
    this.radius = AppTheme.cardRadius,
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
