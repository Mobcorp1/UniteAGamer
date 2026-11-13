import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

class ArcBlueprintGridDetectionOverlay extends StatelessWidget {
  const ArcBlueprintGridDetectionOverlay({
    required this.imageBytes,
    required this.detection,
    super.key,
  });

  final Uint8List imageBytes;
  final ArcBlueprintGridDetection detection;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        key: const Key('blueprint-grid-detection-overlay'),
        fit: StackFit.expand,
        children: [
          Image.memory(imageBytes, fit: BoxFit.contain),
          CustomPaint(painter: _GridDetectionPainter(detection)),
        ],
      ),
    );
  }
}

class _GridDetectionPainter extends CustomPainter {
  const _GridDetectionPainter(this.detection);

  final ArcBlueprintGridDetection detection;

  @override
  void paint(Canvas canvas, Size size) {
    if (!detection.isValid) return;

    final panel = Path()
      ..moveTo(
        detection.topLeft.dx * size.width,
        detection.topLeft.dy * size.height,
      )
      ..lineTo(
        detection.topRight.dx * size.width,
        detection.topRight.dy * size.height,
      )
      ..lineTo(
        detection.bottomRight.dx * size.width,
        detection.bottomRight.dy * size.height,
      )
      ..lineTo(
        detection.bottomLeft.dx * size.width,
        detection.bottomLeft.dy * size.height,
      )
      ..close();

    canvas.drawPath(
      panel,
      Paint()
        ..color = Colors.greenAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final dividerPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final x in detection.verticalDividers) {
      canvas.drawLine(
        Offset(x * size.width, detection.topLeft.dy * size.height),
        Offset(x * size.width, detection.bottomLeft.dy * size.height),
        dividerPaint,
      );
    }
    for (final y in detection.horizontalDividers) {
      canvas.drawLine(
        Offset(detection.topLeft.dx * size.width, y * size.height),
        Offset(detection.topRight.dx * size.width, y * size.height),
        dividerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridDetectionPainter oldDelegate) =>
      oldDelegate.detection != detection;
}
