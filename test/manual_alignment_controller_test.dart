import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/manual_alignment_controller.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_edge_calibration.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_blueprint_live_scanner_screen.dart';

void main() {
  group('ManualAlignmentController', () {
    test('default top frame has 2:1 aspect ratio', () {
      final c = ManualAlignmentController();
      c.resetToTopDefault();
      final rect = c.calibration.normalizedRect;
      final width = rect.width;
      final height = rect.height;
      expect((width / height).toStringAsFixed(2), equals('2.00'));
    });

    test('left edge moves both left corners', () {
      final c = ManualAlignmentController();
      c.resetToTopDefault();
      final before = c.calibration;
      final newLeft = (before.left + 0.05).clamp(0.0, 1.0);
      c.moveEdge(ArcBlueprintCropEdge.left, newLeft);
      expect(c.calibration.left, equals(newLeft));
      expect(c.calibration.top, equals(before.top));
      expect(c.calibration.bottom, equals(before.bottom));
    });

    test('right edge moves both right corners', () {
      final c = ManualAlignmentController();
      c.resetToTopDefault();
      final before = c.calibration;
      final newRight = (before.right - 0.05).clamp(0.0, 1.0);
      c.moveEdge(ArcBlueprintCropEdge.right, newRight);
      expect(c.calibration.right, equals(newRight));
      expect(c.calibration.top, equals(before.top));
      expect(c.calibration.bottom, equals(before.bottom));
    });

    test('top edge moves both top corners', () {
      final c = ManualAlignmentController();
      c.resetToTopDefault();
      final before = c.calibration;
      final newTop = (before.top - 0.03).clamp(0.0, 1.0);
      c.moveEdge(ArcBlueprintCropEdge.top, newTop);
      expect(c.calibration.top, equals(newTop));
      expect(c.calibration.left, equals(before.left));
      expect(c.calibration.right, equals(before.right));
    });

    test('bottom edge moves both bottom corners', () {
      final c = ManualAlignmentController();
      c.resetToTopDefault();
      final before = c.calibration;
      final newBottom = (before.bottom + 0.02).clamp(0.0, 1.0);
      c.moveEdge(ArcBlueprintCropEdge.bottom, newBottom);
      expect(c.calibration.bottom, equals(newBottom));
      expect(c.calibration.left, equals(before.left));
      expect(c.calibration.right, equals(before.right));
    });

    test('dragging centre translates whole rectangle', () {
      final c = ManualAlignmentController();
      c.resetToTopDefault();
      final before = c.calibration;
      const dx = 0.03;
      const dy = -0.02;
      c.translate(dx, dy);
      expect((c.calibration.left - before.left), closeTo(dx, 1e-6));
      expect((c.calibration.top - before.top), closeTo(dy, 1e-6));
    });

    test('reset returns correct default rectangle', () {
      final c = ManualAlignmentController();
      c.resetToTopDefault();
      final rect = c.calibration.normalizedRect;
      expect(rect.width, closeTo(0.72, 0.001));
      expect((rect.width / rect.height), closeTo(2.0, 0.01));
    });

    test('auto-align can consume valid detection bounds', () {
      final c = ManualAlignmentController();
      final detection = ArcBlueprintGridDetection(
        topLeft: const Offset(0.10, 0.12),
        topRight: const Offset(0.90, 0.12),
        bottomLeft: const Offset(0.10, 0.62),
        bottomRight: const Offset(0.90, 0.62),
        confidence: 0.9,
        message: 'ok',
        columns: 10,
        rows: 5,
      );
      c.autoAlignFromDetection(detection);
      expect(c.calibration.left, closeTo(0.10, 1e-6));
      expect(c.calibration.top, closeTo(0.12, 1e-6));
      expect(c.calibration.right, closeTo(0.90, 1e-6));
      expect(c.calibration.bottom, closeTo(0.62, 1e-6));
    });
  });

  test('shutter is available without gridLocked', () {
    final enabled = canStartCapture(
      controllerInitialized: true,
      capturing: false,
      isPortrait: false,
    );
    expect(enabled, isTrue);
  });
}
