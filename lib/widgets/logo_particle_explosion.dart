import 'package:flutter/material.dart';

class LogoParticleExplosion extends StatelessWidget {
  final AnimationController controller;

  const LogoParticleExplosion({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Opacity(
          opacity: 1 - controller.value, // ✅ Fade out effect
          child: Transform.scale(
            scale: 1 + (controller.value * 2), // ✅ Expand outward
            child: Image.asset(
              'assets/icon/uag_traders_icon_transparent.webp',
              height: 150,
              width: 150,
            ),
          ),
        );
      },
    );
  }
}
