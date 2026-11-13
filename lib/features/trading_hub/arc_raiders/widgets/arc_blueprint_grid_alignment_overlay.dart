import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcBlueprintGridAlignmentOverlay extends StatelessWidget {
  const ArcBlueprintGridAlignmentOverlay({
    super.key,
    this.columns = 10,
    this.rows = 5,
    this.isAligned = false,
  });

  final int columns;
  final int rows;
  final bool isAligned;

  @override
  Widget build(BuildContext context) {
    final color = isAligned ? Colors.lightGreenAccent : AppTheme.neonCyan;
    return IgnorePointer(
      child: CustomPaint(
        key: const Key('blueprint-grid-alignment-overlay'),
        painter: _BlueprintGridOverlayPainter(
          columns: columns,
          rows: rows,
          color: color,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BlueprintGridOverlayPainter extends CustomPainter {
  const _BlueprintGridOverlayPainter({
    required this.columns,
    required this.rows,
    required this.color,
  });

  final int columns;
  final int rows;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final border = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    canvas.drawRRect(border, paint..strokeWidth = 2.2);
    paint.strokeWidth = 1.0;
    for (var column = 1; column < columns; column++) {
      final x = size.width * column / columns;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var row = 1; row < rows; row++) {
      final y = size.height * row / rows;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlueprintGridOverlayPainter oldDelegate) {
    return columns != oldDelegate.columns ||
        rows != oldDelegate.rows ||
        color != oldDelegate.color;
  }
}
