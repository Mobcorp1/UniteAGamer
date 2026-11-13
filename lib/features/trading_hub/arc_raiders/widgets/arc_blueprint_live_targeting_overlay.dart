import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

class ArcBlueprintLiveTargetingOverlay extends StatelessWidget {
  const ArcBlueprintLiveTargetingOverlay({
    super.key,
    required this.detection,
    required this.isLocked,
    required this.isBottomCapture,
  });

  final ArcBlueprintGridDetection? detection;
  final bool isLocked;
  final bool isBottomCapture;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ArcBlueprintLiveTargetingPainter(
          detection: detection,
          isLocked: isLocked,
          isBottomCapture: isBottomCapture,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ArcBlueprintLiveTargetingPainter extends CustomPainter {
  const _ArcBlueprintLiveTargetingPainter({
    required this.detection,
    required this.isLocked,
    required this.isBottomCapture,
  });

  final ArcBlueprintGridDetection? detection;
  final bool isLocked;
  final bool isBottomCapture;

  @override
  void paint(Canvas canvas, Size size) {
    final activeColor = isLocked ? Colors.greenAccent : const Color(0xFF45E6FF);
    final guideRect = _guideRect(size);

    _drawCornerBrackets(canvas, guideRect, activeColor);

    final current = detection;
    if (current != null && current.isValid && current.hasSegmentedGrid) {
      _drawDetectedGrid(canvas, size, current, activeColor);
    } else {
      _drawGuideHints(
        canvas,
        size,
        guideRect,
        activeColor.withValues(alpha: 0.30),
      );
    }
  }

  Rect _guideRect(Size size) {
    final horizontalMargin = size.width * 0.07;
    final width = size.width - (horizontalMargin * 2);
    final ratio = isBottomCapture ? (10 / 3.35) : (10 / 5.0);
    final desiredHeight = width / ratio;
    final height = desiredHeight.clamp(size.height * 0.30, size.height * 0.70);

    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: width,
      height: height,
    );
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect, Color color) {
    final bracket = rect.shortestSide * 0.15;
    final strokeWidth = (rect.shortestSide * 0.008).clamp(2.5, 5.0);

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(rect.left, rect.top + bracket)
      ..lineTo(rect.left, rect.top)
      ..lineTo(rect.left + bracket, rect.top)
      ..moveTo(rect.right - bracket, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.top + bracket)
      ..moveTo(rect.right, rect.bottom - bracket)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right - bracket, rect.bottom)
      ..moveTo(rect.left + bracket, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.bottom - bracket);

    canvas.drawPath(path, paint);
  }

  void _drawGuideHints(Canvas canvas, Size size, Rect rect, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var column = 1; column < 10; column++) {
      final x = rect.left + (rect.width * column / 10);
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), paint);
    }

    final completeRows = isBottomCapture ? 3 : 5;
    for (var row = 1; row < completeRows; row++) {
      final y = rect.top + (rect.height * row / completeRows);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    }

    if (isBottomCapture) {
      final rowHeight = rect.height / 3;
      final partialTop = rect.bottom;
      final partialBottom = (partialTop + (rowHeight * 0.55)).clamp(
        0.0,
        size.height,
      );

      final partialPaint = Paint()
        ..color = color.withValues(alpha: 0.60)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      final right = rect.left + (rect.width * 0.30);
      canvas.drawRect(
        Rect.fromLTRB(rect.left, partialTop, right, partialBottom),
        partialPaint,
      );

      for (var column = 1; column < 3; column++) {
        final x = rect.left + (rect.width * column / 10);
        canvas.drawLine(
          Offset(x, partialTop),
          Offset(x, partialBottom),
          partialPaint,
        );
      }
    }
  }

  void _drawDetectedGrid(
    Canvas canvas,
    Size size,
    ArcBlueprintGridDetection detection,
    Color color,
  ) {
    final outerPaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.62)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    Offset map(Offset point) =>
        Offset(point.dx * size.width, point.dy * size.height);

    final tl = map(detection.topLeft);
    final tr = map(detection.topRight);
    final bl = map(detection.bottomLeft);
    final br = map(detection.bottomRight);

    canvas.drawPath(
      Path()
        ..moveTo(tl.dx, tl.dy)
        ..lineTo(tr.dx, tr.dy)
        ..lineTo(br.dx, br.dy)
        ..lineTo(bl.dx, bl.dy)
        ..close(),
      outerPaint,
    );

    _drawVerticalDividers(canvas, detection, tl, tr, bl, br, innerPaint);
    _drawHorizontalDividers(canvas, detection, tl, tr, bl, br, innerPaint);
  }

  void _drawVerticalDividers(
    Canvas canvas,
    ArcBlueprintGridDetection detection,
    Offset tl,
    Offset tr,
    Offset bl,
    Offset br,
    Paint paint,
  ) {
    if (detection.verticalDividers.length < 3) return;

    final first = detection.verticalDividers.first;
    final last = detection.verticalDividers.last;
    final span = last - first;
    if (span <= 0) return;

    for (
      var index = 1;
      index < detection.verticalDividers.length - 1;
      index++
    ) {
      final divider = detection.verticalDividers[index];
      final t = ((divider - first) / span).clamp(0.0, 1.0);
      canvas.drawLine(
        ui.Offset.lerp(tl, tr, t)!,
        ui.Offset.lerp(bl, br, t)!,
        paint,
      );
    }
  }

  void _drawHorizontalDividers(
    Canvas canvas,
    ArcBlueprintGridDetection detection,
    Offset tl,
    Offset tr,
    Offset bl,
    Offset br,
    Paint paint,
  ) {
    if (detection.horizontalDividers.length < 3) return;

    final first = detection.horizontalDividers.first;
    final last = detection.horizontalDividers.last;
    final span = last - first;
    if (span <= 0) return;

    for (
      var index = 1;
      index < detection.horizontalDividers.length - 1;
      index++
    ) {
      final divider = detection.horizontalDividers[index];
      final t = ((divider - first) / span).clamp(0.0, 1.0);
      canvas.drawLine(
        ui.Offset.lerp(tl, bl, t)!,
        ui.Offset.lerp(tr, br, t)!,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcBlueprintLiveTargetingPainter oldDelegate) {
    return oldDelegate.detection != detection ||
        oldDelegate.isLocked != isLocked ||
        oldDelegate.isBottomCapture != isBottomCapture;
  }
}
