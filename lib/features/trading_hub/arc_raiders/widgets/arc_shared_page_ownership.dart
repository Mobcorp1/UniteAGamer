import 'package:flutter/material.dart';

import '../../../../widgets/static_watermark.dart';
import '../../../../widgets/theme.dart';

class ArcSharedPageOwnership extends StatelessWidget {
  const ArcSharedPageOwnership({super.key, required this.child, this.accent});

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.darkBackground,
                (accent ?? AppTheme.neonCyan).withValues(alpha: 0.08),
                AppTheme.darkBackground,
              ],
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: Opacity(opacity: 0.22, child: StaticWatermark()),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}
