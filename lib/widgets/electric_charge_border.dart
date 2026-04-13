import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uag_traders_hub/widgets/theme.dart';

class ElectricChargeBorder extends StatefulWidget {
  const ElectricChargeBorder({
    super.key,
    required this.child,
    this.active = false,
    this.radius = 18,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final bool active;
  final double radius;
  final EdgeInsets padding;

  @override
  State<ElectricChargeBorder> createState() => _ElectricChargeBorderState();
}

class _ElectricChargeBorderState extends State<ElectricChargeBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ElectricChargeBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Padding(padding: widget.padding, child: widget.child);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = (math.sin(_controller.value * math.pi * 2) + 1) / 2;
        final borderColor = Color.lerp(
              AppTheme.neonCyan.withValues(alpha: 0.55),
              AppTheme.neonPink.withValues(alpha: 0.85),
              pulse,
            ) ??
            AppTheme.neonCyan;
        final glowColor = Color.lerp(
              AppTheme.neonPink.withValues(alpha: 0.18),
              AppTheme.neonCyan.withValues(alpha: 0.30),
              pulse,
            ) ??
            AppTheme.neonPink;
        return Padding(
          padding: widget.padding,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(color: borderColor, width: 1.35),
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 16 + (pulse * 8),
                  spreadRadius: 0.8 + (pulse * 0.8),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
