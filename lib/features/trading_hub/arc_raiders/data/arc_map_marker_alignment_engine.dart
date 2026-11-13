import 'dart:math' as math;

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_map_marker_import_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

class ArcMapMarkerAlignmentEngine {
  const ArcMapMarkerAlignmentEngine();

  ArcMapMarkerAlignmentCalibration identity({
    required String mapId,
    required ArcRaidMapLayer layer,
    required String sourceId,
  }) {
    return ArcMapMarkerAlignmentCalibration(
      mapId: mapId,
      layer: layer,
      sourceId: sourceId,
      confidence: 0.92,
    );
  }

  ArcMapMarkerAlignmentCalibration calibrate({
    required String mapId,
    required ArcRaidMapLayer layer,
    required String sourceId,
    required List<ArcMapMarkerAlignmentAnchor> anchors,
  }) {
    if (anchors.length < 2) {
      return identity(mapId: mapId, layer: layer, sourceId: sourceId);
    }

    final xFit = _linearFit(
      anchors.map((anchor) => (anchor.sourcePoint.x, anchor.canonicalPoint.x)),
    );
    final yFit = _linearFit(
      anchors.map((anchor) => (anchor.sourcePoint.y, anchor.canonicalPoint.y)),
    );
    final residual =
        anchors.fold<double>(0, (total, anchor) {
          final transformed = ArcNormalizedPoint(
            x: (anchor.sourcePoint.x * xFit.scale) + xFit.offset,
            y: (anchor.sourcePoint.y * yFit.scale) + yFit.offset,
          );
          return total + _distance(transformed, anchor.canonicalPoint);
        }) /
        anchors.length;
    final confidence = (1 - (residual * 8)).clamp(0.35, 0.98).toDouble();

    return ArcMapMarkerAlignmentCalibration(
      mapId: mapId,
      layer: layer,
      sourceId: sourceId,
      scaleX: xFit.scale,
      scaleY: yFit.scale,
      offsetX: xFit.offset,
      offsetY: yFit.offset,
      residual: residual,
      confidence: confidence,
      anchorCount: anchors.length,
    );
  }

  ArcNormalizedPoint normalizeRecordPoint(
    ArcExternalMapMarkerRecord record, {
    ArcRaidMapAsset? mapAsset,
  }) {
    final point = record.point;
    return switch (record.coordinateSpace) {
      ArcMapMarkerCoordinateSpace.normalized => point.clamp(),
      ArcMapMarkerCoordinateSpace.sourcePercent => ArcNormalizedPoint(
        x: point.x / 100,
        y: point.y / 100,
      ).clamp(),
      ArcMapMarkerCoordinateSpace.imagePixel => _pixelPoint(
        point,
        width: record.sourceWidth ?? mapAsset?.width?.toDouble(),
        height: record.sourceHeight ?? mapAsset?.height?.toDouble(),
      ),
    };
  }

  ArcNormalizedPoint alignRecord(
    ArcExternalMapMarkerRecord record, {
    required ArcMapMarkerAlignmentCalibration calibration,
    ArcRaidMapAsset? mapAsset,
  }) {
    final normalized = normalizeRecordPoint(record, mapAsset: mapAsset);
    return calibration.transform(normalized);
  }

  static ArcNormalizedPoint _pixelPoint(
    ArcNormalizedPoint point, {
    required double? width,
    required double? height,
  }) {
    if (width == null || height == null || width <= 0 || height <= 0) {
      return point.clamp();
    }
    return ArcNormalizedPoint(x: point.x / width, y: point.y / height).clamp();
  }

  static _LinearFit _linearFit(Iterable<(double, double)> pairs) {
    final values = pairs.toList(growable: false);
    final count = values.length;
    final sourceMean =
        values.fold<double>(0, (total, value) => total + value.$1) / count;
    final targetMean =
        values.fold<double>(0, (total, value) => total + value.$2) / count;
    var numerator = 0.0;
    var denominator = 0.0;
    for (final value in values) {
      final sourceDelta = value.$1 - sourceMean;
      numerator += sourceDelta * (value.$2 - targetMean);
      denominator += sourceDelta * sourceDelta;
    }
    if (denominator.abs() < 0.000001) {
      return _LinearFit(scale: 1, offset: targetMean - sourceMean);
    }
    final scale = numerator / denominator;
    return _LinearFit(scale: scale, offset: targetMean - (scale * sourceMean));
  }

  static double _distance(ArcNormalizedPoint a, ArcNormalizedPoint b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt((dx * dx) + (dy * dy));
  }
}

class _LinearFit {
  const _LinearFit({required this.scale, required this.offset});

  final double scale;
  final double offset;
}
