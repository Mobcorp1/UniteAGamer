import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_edge_calibration.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

class ManualAlignmentController {
  ManualAlignmentController({ArcBlueprintEdgeCalibration? calibration})
    : _calibration =
          calibration ?? const ArcBlueprintEdgeCalibration.defaults();

  static const double defaultTopWidthFraction = 0.60;
  static const double defaultTopHorizontalCenter = 0.56;
  static const double defaultTopVerticalCenter = 0.50;
  static const double defaultGridPixelAspectRatio = 2.0;
  static const double fallbackLandscapeAspectRatio = 2.20;

  ArcBlueprintEdgeCalibration _calibration;

  ArcBlueprintEdgeCalibration get calibration => _calibration;

  /// Fallback reset used before the real camera viewport is known.
  ///
  /// The live scanner replaces this with [resetToTopDefaultForViewport] as
  /// soon as it receives the actual landscape viewport dimensions.
  void resetToTopDefault() {
    resetToTopDefaultForViewport(
      viewportAspectRatio: fallbackLandscapeAspectRatio,
    );
  }

  /// Resets the starting frame to the real 10 x 5 Blueprint-board geometry.
  ///
  /// Normalized X and Y units are not physically equal on a landscape phone.
  /// The old `height = width / 2` calculation therefore produced a frame that
  /// was far too short on-screen. This method preserves a 2:1 *rendered pixel*
  /// rectangle instead.
  void resetToTopDefaultForViewport({required double viewportAspectRatio}) {
    final safeViewportAspect =
        viewportAspectRatio.isFinite && viewportAspectRatio > 0
        ? viewportAspectRatio
        : fallbackLandscapeAspectRatio;

    const width = defaultTopWidthFraction;
    final requestedHeight =
        (width * safeViewportAspect / defaultGridPixelAspectRatio)
            .clamp(ArcBlueprintEdgeCalibration.minimumHeight, 0.82)
            .toDouble();

    final halfWidth = width / 2;
    final halfHeight = requestedHeight / 2;
    final centreX = defaultTopHorizontalCenter
        .clamp(halfWidth, 1.0 - halfWidth)
        .toDouble();
    final centreY = defaultTopVerticalCenter
        .clamp(halfHeight, 1.0 - halfHeight)
        .toDouble();

    _calibration = ArcBlueprintEdgeCalibration(
      left: centreX - halfWidth,
      top: centreY - halfHeight,
      right: centreX + halfWidth,
      bottom: centreY + halfHeight,
    );
  }

  /// The second photo deliberately reuses the first photo's perimeter.
  /// This fallback exists for callers outside the locked two-shot flow only.
  void resetToBottomDefault() {
    resetToTopDefault();
  }

  void resetToDefaults({bool bottomCapture = false}) {
    if (bottomCapture) {
      resetToBottomDefault();
    } else {
      resetToTopDefault();
    }
  }

  void setCalibration(ArcBlueprintEdgeCalibration calibration) {
    if (!calibration.isValid) return;
    _calibration = calibration;
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

  /// Legacy helper retained for compatibility. The locked two-shot scanner
  /// intentionally never calls this because photo 2 must reuse photo 1's
  /// exact perimeter.
  void prepareForBottomCapture() {
    final width = _calibration.right - _calibration.left;
    final centreY = (_calibration.top + _calibration.bottom) / 2;
    final requestedHeight = (width / 2.5).clamp(
      ArcBlueprintEdgeCalibration.minimumHeight,
      1.0,
    );
    final maximumHalfHeight = math.min(centreY, 1 - centreY);
    final halfHeight = math.min(requestedHeight / 2, maximumHalfHeight);

    _calibration = ArcBlueprintEdgeCalibration(
      left: _calibration.left,
      top: centreY - halfHeight,
      right: _calibration.right,
      bottom: centreY + halfHeight,
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
