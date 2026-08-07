import 'package:flutter/material.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_edge_calibration.dart';
import 'package:uag_arc_raiders_hub/widgets/theme.dart';

class ArcBlueprintEdgeCropOverlay extends StatefulWidget {
  const ArcBlueprintEdgeCropOverlay({
    required this.calibration,
    required this.onChanged,
    super.key,
  });

  final ArcBlueprintEdgeCalibration calibration;
  final ValueChanged<ArcBlueprintEdgeCalibration> onChanged;

  @override
  State<ArcBlueprintEdgeCropOverlay> createState() =>
      _ArcBlueprintEdgeCropOverlayState();
}

class _ArcBlueprintEdgeCropOverlayState
    extends State<ArcBlueprintEdgeCropOverlay> {
  ArcBlueprintCropEdge? _activeEdge;

  void _setActive(ArcBlueprintCropEdge? edge) {
    if (_activeEdge == edge) return;
    setState(() => _activeEdge = edge);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final rect = Rect.fromLTRB(
          widget.calibration.left * size.width,
          widget.calibration.top * size.height,
          widget.calibration.right * size.width,
          widget.calibration.bottom * size.height,
        );

        return Stack(
          key: const Key('blueprint-edge-crop-overlay'),
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: CustomPaint(
                painter: _EdgeCropPainter(
                  cropRect: rect,
                  activeEdge: _activeEdge,
                ),
              ),
            ),
            _verticalHandle(
              key: const Key('blueprint-crop-edge-left'),
              edge: ArcBlueprintCropEdge.left,
              left: rect.left - 24,
              top: rect.top,
              height: rect.height,
              viewportWidth: size.width,
            ),
            _verticalHandle(
              key: const Key('blueprint-crop-edge-right'),
              edge: ArcBlueprintCropEdge.right,
              left: rect.right - 24,
              top: rect.top,
              height: rect.height,
              viewportWidth: size.width,
            ),
            _horizontalHandle(
              key: const Key('blueprint-crop-edge-top'),
              edge: ArcBlueprintCropEdge.top,
              left: rect.left,
              top: rect.top - 24,
              width: rect.width,
              viewportHeight: size.height,
            ),
            _horizontalHandle(
              key: const Key('blueprint-crop-edge-bottom'),
              edge: ArcBlueprintCropEdge.bottom,
              left: rect.left,
              top: rect.bottom - 24,
              width: rect.width,
              viewportHeight: size.height,
            ),
          ],
        );
      },
    );
  }

  Widget _verticalHandle({
    required Key key,
    required ArcBlueprintCropEdge edge,
    required double left,
    required double top,
    required double height,
    required double viewportWidth,
  }) {
    return Positioned(
      key: key,
      left: left,
      top: top,
      width: 48,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) => _setActive(edge),
        onPanCancel: () => _setActive(null),
        onPanEnd: (_) => _setActive(null),
        onPanUpdate: (details) {
          final current = edge == ArcBlueprintCropEdge.left
              ? widget.calibration.left
              : widget.calibration.right;
          widget.onChanged(
            widget.calibration.moveEdge(
              edge,
              current + (details.delta.dx / viewportWidth),
            ),
          );
        },
        child: Center(
          child: _EdgeHandle(active: _activeEdge == edge, quarterTurns: 1),
        ),
      ),
    );
  }

  Widget _horizontalHandle({
    required Key key,
    required ArcBlueprintCropEdge edge,
    required double left,
    required double top,
    required double width,
    required double viewportHeight,
  }) {
    return Positioned(
      key: key,
      left: left,
      top: top,
      width: width,
      height: 48,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) => _setActive(edge),
        onPanCancel: () => _setActive(null),
        onPanEnd: (_) => _setActive(null),
        onPanUpdate: (details) {
          final current = edge == ArcBlueprintCropEdge.top
              ? widget.calibration.top
              : widget.calibration.bottom;
          widget.onChanged(
            widget.calibration.moveEdge(
              edge,
              current + (details.delta.dy / viewportHeight),
            ),
          );
        },
        child: Center(child: _EdgeHandle(active: _activeEdge == edge)),
      ),
    );
  }
}

class _EdgeHandle extends StatelessWidget {
  const _EdgeHandle({required this.active, this.quarterTurns = 0});

  final bool active;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    final colour = active ? Colors.white : AppTheme.neonCyan;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: active ? 54 : 46,
      height: active ? 30 : 26,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colour, width: active ? 3 : 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: active ? 0.75 : 0.4),
            blurRadius: active ? 16 : 10,
          ),
        ],
      ),
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: Icon(Icons.drag_handle_rounded, color: colour, size: 24),
      ),
    );
  }
}

class _EdgeCropPainter extends CustomPainter {
  const _EdgeCropPainter({required this.cropRect, required this.activeEdge});

  final Rect cropRect;
  final ArcBlueprintCropEdge? activeEdge;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.58),
    );
    canvas.drawRect(
      cropRect,
      Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.fill,
    );
    canvas.restore();

    canvas.drawRect(
      cropRect,
      Paint()
        ..color = AppTheme.neonCyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    if (activeEdge == null) return;
    final active = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    switch (activeEdge!) {
      case ArcBlueprintCropEdge.top:
        canvas.drawLine(cropRect.topLeft, cropRect.topRight, active);
      case ArcBlueprintCropEdge.bottom:
        canvas.drawLine(cropRect.bottomLeft, cropRect.bottomRight, active);
      case ArcBlueprintCropEdge.left:
        canvas.drawLine(cropRect.topLeft, cropRect.bottomLeft, active);
      case ArcBlueprintCropEdge.right:
        canvas.drawLine(cropRect.topRight, cropRect.bottomRight, active);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgeCropPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect || oldDelegate.activeEdge != activeEdge;
}
