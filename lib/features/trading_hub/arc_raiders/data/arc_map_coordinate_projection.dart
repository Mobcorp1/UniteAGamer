import 'package:flutter/widgets.dart';

import '../models/arc_raid_intelligence_models.dart';

/// Shared map projection used by both Admin Map Editor and player-facing
/// Raid Intelligence. Marker data remains canonical normalized coordinates;
/// calibration only affects how that canonical point is drawn on the image.
class ArcMapCoordinateProjection {
  const ArcMapCoordinateProjection._();

  static Size containSize({
    required Size viewport,
    double? sourceWidth,
    double? sourceHeight,
    double fallbackAspectRatio = 1.25,
  }) {
    final safeWidth = viewport.width.isFinite && viewport.width > 0
        ? viewport.width
        : 1.0;
    final safeHeight = viewport.height.isFinite && viewport.height > 0
        ? viewport.height
        : 1.0;
    final aspectRatio =
        sourceWidth != null &&
            sourceWidth > 0 &&
            sourceHeight != null &&
            sourceHeight > 0
        ? sourceWidth / sourceHeight
        : fallbackAspectRatio;
    final viewportRatio = safeWidth / safeHeight;
    if (viewportRatio > aspectRatio) {
      return Size(safeHeight * aspectRatio, safeHeight);
    }
    return Size(safeWidth, safeWidth / aspectRatio);
  }

  static Offset canonicalToCanvas({
    required ArcNormalizedPoint point,
    required Size mapSize,
    ArcRaidMapCalibration? calibration,
  }) {
    final imagePoint = calibration?.canonicalToImage(point) ?? point.clamp();
    return Offset(imagePoint.x * mapSize.width, imagePoint.y * mapSize.height);
  }

  static ArcNormalizedPoint canvasToCanonical({
    required Offset localPosition,
    required Size mapSize,
    ArcRaidMapCalibration? calibration,
  }) {
    if (mapSize.width <= 0 || mapSize.height <= 0) {
      return const ArcNormalizedPoint(x: 0, y: 0);
    }
    final imagePoint = ArcNormalizedPoint(
      x: localPosition.dx / mapSize.width,
      y: localPosition.dy / mapSize.height,
    ).clamp();
    return (calibration?.imageToCanonical(imagePoint) ?? imagePoint).clamp();
  }
}
