import 'package:flutter/material.dart';
import 'dart:math';
import 'package:uag_traders_hub/build/logo_particle_explosion.dart';

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({
    super.key,
    this.size = 150,
    this.assetPath = 'assets/icon/uag_traders_icon_transparent.webp',
  });

  final double size;
  final String assetPath;

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  static const _neonCyan = Color.fromARGB(255, 0, 255, 255);
  static const _neonPink = Color.fromARGB(255, 255, 20, 147);

  late final AnimationController _animationController;
  late final AnimationController _glowController;
  late final AnimationController _explosionController;

  late final Animation<double> _fallAndBounceAnimation;
  late final Animation<double> _rotationAnimation;
  late final Animation<Color?> _glowColorAnimation;

  bool _showLogo = false;

  @override
  void initState() {
    super.initState();

    // ✅ Explosion first
    _explosionController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1400),
          )
          ..forward().whenComplete(() {
            if (!mounted) return;
            setState(() => _showLogo = true);
            _animationController.forward();
          });

    // ✅ Bounce + spin timing
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    );

    _fallAndBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: -420.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: -140.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 0.55,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -140.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 0.70,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: -10.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.18,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -10.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.18,
      ),
    ]).animate(_animationController);

    // ✅ Spin like before (3 full rotations)
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi * 3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    // ✅ Glow colour animation (cyan ↔ pink)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _glowColorAnimation = ColorTween(
      begin: _neonCyan,
      end: _neonPink,
    ).animate(_glowController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    _explosionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showLogo) {
      return LogoParticleExplosion(controller: _explosionController);
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_animationController, _glowController]),
        builder: (context, child) {
          final glowColor = (_glowColorAnimation.value ?? _neonCyan);

          // ✅ Key settings for “thin edge glow”
          // - spreadRadius NEGATIVE pulls glow tight to the edge
          // - blurRadius small keeps it subtle
          // - alpha moderate so it reads but doesn’t halo
          final thinGlow = BoxShadow(
            color: glowColor.withValues(alpha: 0.45),
            blurRadius: 6, // small, soft
            spreadRadius: -6, // ✅ tight to edge (prevents bubble look)
          );

          return Transform.translate(
            offset: Offset(0, _fallAndBounceAnimation.value),
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: SizedBox(
                height: widget.size,
                width: widget.size,
                child: DecoratedBox(
                  // ✅ Glow is OUTSIDE the clip now (no clipped ring)
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [thinGlow],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      widget.assetPath,
                      height: widget.size,
                      width: widget.size,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
