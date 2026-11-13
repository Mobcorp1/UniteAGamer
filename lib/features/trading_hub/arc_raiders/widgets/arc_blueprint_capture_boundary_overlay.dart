import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

enum ArcBlueprintBoundarySize {
  small(0.72, 0.58, 'Small'),
  medium(0.82, 0.72, 'Medium'),
  large(0.92, 0.86, 'Large'),
  extraLarge(1.0, 1.0, 'Extra Large');

  const ArcBlueprintBoundarySize(
    this.widthFraction,
    this.heightFraction,
    this.label,
  );

  final double widthFraction;
  final double heightFraction;
  final String label;
}

class ArcBlueprintCaptureBoundaryOverlay extends StatelessWidget {
  const ArcBlueprintCaptureBoundaryOverlay({
    required this.isAligned,
    this.boundarySize = ArcBlueprintBoundarySize.extraLarge,
    this.verticalOffset = 0,
    this.dimOutside = true,
    super.key,
  });

  final bool isAligned;
  final ArcBlueprintBoundarySize boundarySize;
  final double verticalOffset;
  final bool dimOutside;

  static Rect frameRectFor(
    Size size, {
    ArcBlueprintBoundarySize boundarySize = ArcBlueprintBoundarySize.extraLarge,
    double verticalOffset = 0,
  }) {
    const minimumEdgeMargin = 0.0;
    final availableWidth = (size.width - minimumEdgeMargin * 2)
        .clamp(120.0, double.infinity)
        .toDouble();
    final availableHeight = (size.height - minimumEdgeMargin * 2)
        .clamp(80.0, double.infinity)
        .toDouble();

    // The in-game Blueprint panel already contains its own visible grid.
    // Width and height therefore scale independently so the user can fit
    // the real outer edges instead of being forced into an artificial ratio.
    final width = availableWidth * boundarySize.widthFraction;
    final height = availableHeight * boundarySize.heightFraction;

    final maximumShift = ((size.height - height) / 2 - minimumEdgeMargin)
        .clamp(0.0, size.height * 0.22)
        .toDouble();
    final resolvedOffset = verticalOffset.clamp(-1.0, 1.0) * maximumShift;

    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 + resolvedOffset),
      width: width,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        key: const Key('blueprint-capture-boundary-overlay'),
        painter: _BoundaryPainter(
          isAligned: isAligned,
          boundarySize: boundarySize,
          verticalOffset: verticalOffset,
          dimOutside: dimOutside,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BoundaryPainter extends CustomPainter {
  const _BoundaryPainter({
    required this.isAligned,
    required this.boundarySize,
    required this.verticalOffset,
    required this.dimOutside,
  });

  final bool isAligned;
  final ArcBlueprintBoundarySize boundarySize;
  final double verticalOffset;
  final bool dimOutside;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = ArcBlueprintCaptureBoundaryOverlay.frameRectFor(
      size,
      boundarySize: boundarySize,
      verticalOffset: verticalOffset,
    );
    final colour = isAligned ? Colors.lightGreenAccent : AppTheme.neonCyan;

    if (dimOutside) {
      final outside = Path()
        ..addRect(Offset.zero & size)
        ..addRRect(RRect.fromRectAndRadius(frame, const Radius.circular(12)))
        ..fillType = PathFillType.evenOdd;
      canvas.drawPath(
        outside,
        Paint()..color = Colors.black.withValues(alpha: 0.48),
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(12)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = colour.withValues(alpha: 0.9),
    );

    final corner = (frame.shortestSide * 0.13).clamp(30.0, 58.0).toDouble();
    const stroke = 7.0;
    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square
      ..color = colour;

    void drawCorner(
      Offset point,
      double horizontalDirection,
      double verticalDirection,
    ) {
      canvas.drawLine(
        point,
        point.translate(corner * horizontalDirection, 0),
        cornerPaint,
      );
      canvas.drawLine(
        point,
        point.translate(0, corner * verticalDirection),
        cornerPaint,
      );
    }

    drawCorner(frame.topLeft, 1, 1);
    drawCorner(frame.topRight, -1, 1);
    drawCorner(frame.bottomLeft, 1, -1);
    drawCorner(frame.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(covariant _BoundaryPainter oldDelegate) {
    return oldDelegate.isAligned != isAligned ||
        oldDelegate.boundarySize != boundarySize ||
        oldDelegate.verticalOffset != verticalOffset ||
        oldDelegate.dimOutside != dimOutside;
  }
}
