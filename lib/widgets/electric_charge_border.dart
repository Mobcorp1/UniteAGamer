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
      duration: const Duration(milliseconds: 1900),
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
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: widget.padding,
      child: widget.child,
    );

    if (!widget.active) {
      return child;
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            foregroundPainter: _ElectricChargeBorderPainter(
              progress: _controller.value,
              radius: widget.radius,
            ),
            child: child,
          );
        },
      ),
    );
  }
}

class _ElectricChargeBorderPainter extends CustomPainter {
  const _ElectricChargeBorderPainter({
    required this.progress,
    required this.radius,
  });

  final double progress;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.8),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    final metrics = path.computeMetrics().toList(growable: false);
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final length = metric.length;

    const segmentFraction = 0.16;
    const trailFraction = 0.28;

    final headLength = length * segmentFraction;
    final trailLength = length * trailFraction;
    final center = progress * length;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..color = AppTheme.neonCyan.withValues(alpha: 0.18);

    canvas.drawRRect(rrect, basePaint);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final surgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    void drawSegment({
      required double start,
      required double end,
      required Color color,
      required Paint paint,
    }) {
      final clampedStart = start;
      final clampedEnd = end;

      if (clampedEnd <= clampedStart) return;

      if (clampedStart >= 0 && clampedEnd <= length) {
        final segment = metric.extractPath(clampedStart, clampedEnd);
        paint.color = color;
        canvas.drawPath(segment, paint);
        return;
      }

      if (clampedStart < 0) {
        final first = metric.extractPath(length + clampedStart, length);
        final second = metric.extractPath(0, clampedEnd);
        paint.color = color;
        canvas.drawPath(first, paint);
        canvas.drawPath(second, paint);
        return;
      }

      if (clampedEnd > length) {
        final first = metric.extractPath(clampedStart, length);
        final second = metric.extractPath(0, clampedEnd - length);
        paint.color = color;
        canvas.drawPath(first, paint);
        canvas.drawPath(second, paint);
      }
    }

    final trailStart = center - trailLength;
    final headStart = center - headLength;
    final headEnd = center;

    drawSegment(
      start: trailStart,
      end: headEnd,
      color: AppTheme.neonCyan.withValues(alpha: 0.18),
      paint: glowPaint,
    );

    drawSegment(
      start: headStart,
      end: headEnd,
      color: AppTheme.neonPink.withValues(alpha: 0.92),
      paint: glowPaint,
    );

    drawSegment(
      start: center - (headLength * 1.25),
      end: headEnd,
      color: AppTheme.neonCyan.withValues(alpha: 0.36),
      paint: surgePaint,
    );

    drawSegment(
      start: headStart,
      end: headEnd,
      color: Color.lerp(
            AppTheme.neonCyan,
            AppTheme.neonPink,
            0.65 + (0.1 * math.sin(progress * math.pi * 2)),
          ) ??
          AppTheme.neonPink,
      paint: surgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ElectricChargeBorderPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.radius != radius;
  }
}
