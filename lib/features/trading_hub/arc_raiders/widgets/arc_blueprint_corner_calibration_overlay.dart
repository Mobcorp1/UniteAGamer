import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_corner_calibration.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcBlueprintCornerCalibrationOverlay extends StatelessWidget {
  const ArcBlueprintCornerCalibrationOverlay({
    required this.calibration,
    required this.onChanged,
    super.key,
  });

  final ArcBlueprintCornerCalibration calibration;
  final ValueChanged<ArcBlueprintCornerCalibration> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final points = calibration.corners
            .map(
              (point) => Offset(point.dx * size.width, point.dy * size.height),
            )
            .toList(growable: false);
        return Stack(
          key: const Key('blueprint-corner-calibration-overlay'),
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: CustomPaint(painter: _CalibrationPainter(points: points)),
            ),
            for (var index = 0; index < points.length; index++)
              Positioned(
                left: points[index].dx - 22,
                top: points[index].dy - 22,
                width: 44,
                height: 44,
                child: GestureDetector(
                  key: Key('blueprint-calibration-corner-$index'),
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    final current = points[index] + details.delta;
                    onChanged(
                      calibration.moveCorner(
                        index,
                        Offset(
                          current.dx / size.width,
                          current.dy / size.height,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.75),
                      border: Border.all(color: AppTheme.neonCyan, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonCyan.withValues(alpha: 0.55),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.open_with_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CalibrationPainter extends CustomPainter {
  const _CalibrationPainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length != 4) return;
    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..close();

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.58),
    );
    canvas.drawPath(
      path,
      Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.fill,
    );
    canvas.restore();

    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.neonCyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _CalibrationPainter oldDelegate) =>
      oldDelegate.points != points;
}
