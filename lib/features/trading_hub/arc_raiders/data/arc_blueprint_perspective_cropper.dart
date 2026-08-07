import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_edge_calibration.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

class ArcBlueprintPerspectiveCropper {
  const ArcBlueprintPerspectiveCropper({
    this.outputWidth = 1000,
    this.cellHeight = 100,
  });

  final int outputWidth;
  final int cellHeight;

  Uint8List rectify({
    required Uint8List imageBytes,
    required Size viewportSize,
    required ArcBlueprintEdgeCalibration calibration,
  }) {
    final decoded = _decode(imageBytes);
    if (!calibration.isValid || viewportSize.isEmpty) {
      throw const FormatException('The Blueprint crop area is invalid.');
    }

    final sourceSize = Size(
      decoded.width.toDouble(),
      decoded.height.toDouble(),
    );
    final rect = calibration.normalizedRect;
    final corners = <Offset>[
      _viewportPointToSource(
        point: rect.topLeft,
        viewport: viewportSize,
        source: sourceSize,
      ),
      _viewportPointToSource(
        point: rect.topRight,
        viewport: viewportSize,
        source: sourceSize,
      ),
      _viewportPointToSource(
        point: rect.bottomLeft,
        viewport: viewportSize,
        source: sourceSize,
      ),
      _viewportPointToSource(
        point: rect.bottomRight,
        viewport: viewportSize,
        source: sourceSize,
      ),
    ];

    return _rectify(decoded, corners, outputHeight: cellHeight * 5);
  }

  Uint8List rectifyDetection({
    required Uint8List imageBytes,
    required ArcBlueprintGridDetection detection,
  }) {
    final decoded = _decode(imageBytes);

    if (!detection.isValid || !detection.hasSegmentedGrid) {
      throw const FormatException('The detected Blueprint grid is invalid.');
    }

    final width = decoded.width.toDouble();
    final height = decoded.height.toDouble();

    final corners = detection.corners
        .map((point) => Offset(point.dx * width, point.dy * height))
        .toList(growable: false);

    final outputHeight = math.max(cellHeight, detection.rows * cellHeight);

    return _rectify(decoded, corners, outputHeight: outputHeight);
  }

  img.Image _decode(Uint8List imageBytes) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw const FormatException('The captured image could not be decoded.');
    }
    return img.bakeOrientation(decoded);
  }

  Uint8List _rectify(
    img.Image source,
    List<Offset> corners, {
    required int outputHeight,
  }) {
    final output = img.Image(width: outputWidth, height: outputHeight);

    for (var y = 0; y < outputHeight; y++) {
      final v = outputHeight <= 1 ? 0.0 : y / (outputHeight - 1);

      final left = Offset.lerp(corners[0], corners[2], v)!;
      final right = Offset.lerp(corners[1], corners[3], v)!;

      for (var x = 0; x < outputWidth; x++) {
        final u = outputWidth <= 1 ? 0.0 : x / (outputWidth - 1);

        final point = Offset.lerp(left, right, u)!;
        output.setPixel(x, y, _sampleBilinear(source, point.dx, point.dy));
      }
    }

    return Uint8List.fromList(img.encodeJpg(output, quality: 96));
  }

  img.ColorRgba8 _sampleBilinear(img.Image source, double x, double y) {
    final clampedX = x.clamp(0.0, source.width - 1.0);
    final clampedY = y.clamp(0.0, source.height - 1.0);

    final x0 = clampedX.floor();
    final y0 = clampedY.floor();
    final x1 = math.min(source.width - 1, x0 + 1);
    final y1 = math.min(source.height - 1, y0 + 1);

    final tx = clampedX - x0;
    final ty = clampedY - y0;

    final p00 = source.getPixel(x0, y0);
    final p10 = source.getPixel(x1, y0);
    final p01 = source.getPixel(x0, y1);
    final p11 = source.getPixel(x1, y1);

    int channel(num a, num b, num c, num d) {
      final top = a + ((b - a) * tx);
      final bottom = c + ((d - c) * tx);
      return (top + ((bottom - top) * ty)).round().clamp(0, 255);
    }

    return img.ColorRgba8(
      channel(p00.r, p10.r, p01.r, p11.r),
      channel(p00.g, p10.g, p01.g, p11.g),
      channel(p00.b, p10.b, p01.b, p11.b),
      channel(p00.a, p10.a, p01.a, p11.a),
    );
  }

  Offset _viewportPointToSource({
    required Offset point,
    required Size viewport,
    required Size source,
  }) {
    final absolute = Offset(
      point.dx * viewport.width,
      point.dy * viewport.height,
    );

    final scale = math.max(
      viewport.width / source.width,
      viewport.height / source.height,
    );

    final renderedWidth = source.width * scale;
    final renderedHeight = source.height * scale;
    final overflowX = (renderedWidth - viewport.width) / 2;
    final overflowY = (renderedHeight - viewport.height) / 2;

    return Offset(
      (absolute.dx + overflowX) / scale,
      (absolute.dy + overflowY) / scale,
    );
  }
}
