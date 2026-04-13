import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

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
  late final AnimationController _dropController;
  late final AnimationController _glowController;
  late final Animation<double> _dropAnimation;
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Color?> _glowColorAnimation;

  @override
  void initState() {
    super.initState();

    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _dropAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: -240.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: -48.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -48.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 0.45,
      ),
    ]).animate(_dropController);

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi * 2,
    ).animate(CurvedAnimation(parent: _dropController, curve: Curves.easeOut));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.82,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.02,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 0.5,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.02,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 0.5,
      ),
    ]).animate(_dropController);

    _glowColorAnimation = ColorTween(
      begin: AppTheme.neonCyan,
      end: AppTheme.neonPink,
    ).animate(_glowController);
  }

  @override
  void dispose() {
    _dropController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_dropController, _glowController]),
        builder: (context, child) {
          final glow = _glowColorAnimation.value ?? AppTheme.neonCyan;

          return Transform.translate(
            offset: Offset(0, _dropAnimation.value),
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.size * 0.22),
                    boxShadow: [
                      BoxShadow(
                        color: glow.withValues(alpha: 0.28),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.size * 0.22),
                    child: Image.asset(
                      widget.assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Container(
                        color: AppTheme.cardBackground,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          size: widget.size * 0.48,
                          color: AppTheme.neonCyan,
                        ),
                      ),
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
