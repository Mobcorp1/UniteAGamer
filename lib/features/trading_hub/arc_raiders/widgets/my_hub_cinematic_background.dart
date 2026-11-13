import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class MyHubCinematicBackground extends StatelessWidget {
  const MyHubCinematicBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF050816),
                  AppTheme.neonCyan.withValues(alpha: 0.08),
                  const Color(0xFF02030A),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: IgnorePointer(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.neonPink.withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -140,
          left: -100,
          child: IgnorePointer(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.neonCyan.withValues(alpha: 0.06),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
