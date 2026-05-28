import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/static_watermark.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ArcRaidersScreenBackdrop extends StatelessWidget {
  const ArcRaidersScreenBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF040514),
                  Color.lerp(AppTheme.neonCyan, const Color(0xFF050612), 0.86)!,
                  const Color(0xFF020208),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.neonCyan.withValues(alpha: 0.18),
                    AppTheme.neonPink.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  center: const Alignment(0.0, -0.36),
                  radius: 0.92,
                ),
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: Opacity(opacity: 0.30, child: StaticWatermark()),
          ),
        ),
      ],
    );
  }
}

class ArcRaidersScreenShell extends StatelessWidget {
  final Widget child;
  final bool useSafeArea;

  const ArcRaidersScreenShell({
    super.key,
    required this.child,
    this.useSafeArea = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = useSafeArea ? SafeArea(child: child) : child;

    return Stack(
      children: [
        const Positioned.fill(child: ArcRaidersScreenBackdrop()),
        content,
      ],
    );
  }
}
