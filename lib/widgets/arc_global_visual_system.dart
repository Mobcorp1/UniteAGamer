import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/widgets/electric_charge_border.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';
import 'package:uag_arc_raiders_hub/widgets/uag_cinematic_background.dart';

/// Canonical full-screen visual foundation for every user and admin route.
///
/// This deliberately mirrors the Blueprint Grid backdrop so the application
/// has one visual source of truth instead of screen-owned backgrounds.
class ArcBlueprintGridBackground extends StatelessWidget {
  const ArcBlueprintGridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const UagCinematicBackground(
          backgroundAsset: UagVisualAssets.arcBackground,
          backgroundOpacity: 0.34,
          watermarkOpacity: 0.10,
          showGrid: false,
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.neonCyan.withValues(alpha: 0.045),
                  Colors.transparent,
                  AppTheme.neonPink.withValues(alpha: 0.055),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
        color: AppTheme.cardBackgroundDeep.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: accent.withValues(alpha: selected ? 0.90 : 0.34),
          width: selected ? AppTheme.cardOuterBorderWidth : 1.0,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: AppTheme.glowMedium,
                ),
              ]
            : const [],
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
