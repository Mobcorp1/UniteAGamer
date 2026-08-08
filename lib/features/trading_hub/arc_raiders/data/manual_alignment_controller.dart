import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_edge_calibration.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

class ManualAlignmentController {
  ManualAlignmentController({ArcBlueprintEdgeCalibration? calibration})
    : _calibration =
          calibration ?? const ArcBlueprintEdgeCalibration.defaults();

  ArcBlueprintEdgeCalibration _calibration;

  ArcBlueprintEdgeCalibration get calibration => _calibration;

  /// Reset to a centred 2:1 aspect ratio rectangle occupying ~72% of width.
  void resetToTopDefault() {
    const width = 0.72;
    const left = (1.0 - width) / 2.0; // 0.14
    final right = left + width; // 0.86
    final height = width / 2.0; // 0.36
    final top = (1.0 - height) / 2.0;
    final bottom = top + height;
    _calibration = ArcBlueprintEdgeCalibration(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }

  /// Reset to a sensible lower-capture default rectangle.
  void resetToBottomDefault() {
    const width = 0.72;
    const left = (1.0 - width) / 2.0;
    final right = left + width;
    // choose a lower vertical placement capturing rows 6-9 area
    final height = width / 2.0;
    final top = 0.52;
    final bottom = (top + height).clamp(0.0, 1.0);
    _calibration = ArcBlueprintEdgeCalibration(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }

  void resetToDefaults({bool bottomCapture = false}) {
    if (bottomCapture) {
      resetToBottomDefault();
    } else {
      resetToTopDefault();
    }
  }

  /// Move an edge (left/right/top/bottom) to a normalized position while
  /// preserving the opposing side and keeping minimum sizes.
  void moveEdge(ArcBlueprintCropEdge edge, double normalizedPosition) {
    _calibration = _calibration.moveEdge(edge, normalizedPosition);
  }

  /// Translate the whole rectangle by delta in normalized coordinates.
  void translate(double dx, double dy) {
    final left = (_calibration.left + dx).clamp(0.0, 1.0);
    final right = (_calibration.right + dx).clamp(0.0, 1.0);
    final top = (_calibration.top + dy).clamp(0.0, 1.0);
    final bottom = (_calibration.bottom + dy).clamp(0.0, 1.0);

    // Ensure min width/height
    final width = right - left;
    final height = bottom - top;
    if (width < ArcBlueprintEdgeCalibration.minimumWidth ||
        height < ArcBlueprintEdgeCalibration.minimumHeight) {
      // clamp back to previous if translation would violate
      return;
    }

    _calibration = ArcBlueprintEdgeCalibration(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }

  /// Initialise the manual rectangle from a detector result.
  /// If detection is invalid, do nothing.
  void autoAlignFromDetection(ArcBlueprintGridDetection detection) {
    if (!detection.isValid) return;
    _calibration = ArcBlueprintEdgeCalibration(
      left: detection.topLeft.dx.clamp(0.0, 1.0),
      top: detection.topLeft.dy.clamp(0.0, 1.0),
      right: detection.topRight.dx.clamp(0.0, 1.0),
      bottom: detection.bottomLeft.dy.clamp(0.0, 1.0),
    );
  }
}
