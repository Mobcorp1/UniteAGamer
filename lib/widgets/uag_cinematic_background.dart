import 'package:flutter/material.dart';

import 'package:uag_arc_raiders_hub/widgets/static_watermark.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class UagVisualAssets {
  const UagVisualAssets._();

  static const arcBackground =
      'assets/images/arc_raiders/hub/auth_bg_landscape.webp';
}

class UagCinematicBackground extends StatelessWidget {
  const UagCinematicBackground({
    super.key,
    this.accent = AppTheme.neonCyan,
    this.secondaryAccent = AppTheme.neonPink,
    this.backgroundAsset = UagVisualAssets.arcBackground,
    this.backgroundOpacity = 0.28,
    this.showWatermark = true,
    this.watermarkOpacity = 0.16,
    this.showGrid = true,
  });

  final Color accent;
  final Color secondaryAccent;
  final String? backgroundAsset;
  final double backgroundOpacity;
  final bool showWatermark;
  final double watermarkOpacity;
  final bool showGrid;

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
                    opacity: backgroundOpacity,
                  ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.42),
              radius: 1.18,
              colors: [
                accent.withValues(alpha: 0.22),
                secondaryAccent.withValues(alpha: 0.08),
                AppTheme.darkBackground.withValues(alpha: 0.90),
                Colors.black.withValues(alpha: 0.98),
              ],
              stops: const [0, 0.36, 0.76, 1],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.12),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.55),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        if (showWatermark)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: watermarkOpacity,
                child: const StaticWatermark(),
              ),
            ),
          ),
        if (showGrid)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _UagCommandGridPainter(
                  accent: accent.withValues(alpha: 0.075),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UagCommandGridPainter extends CustomPainter {
  const _UagCommandGridPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent
      ..strokeWidth = 0.55;

    const step = 34.0;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final glowPaint = Paint()
      ..color = accent.withValues(alpha: 0.42)
      ..strokeWidth = 1.2;

    canvas.drawLine(
      Offset(0, size.height * 0.16),
      Offset(size.width, size.height * 0.16),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _UagCommandGridPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}
