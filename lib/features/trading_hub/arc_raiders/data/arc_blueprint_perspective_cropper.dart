import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_edge_calibration.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

class ArcBlueprintPerspectiveCropper {
  const ArcBlueprintPerspectiveCropper({
    this.outputWidth = 1000,
    this.outputHeight = 500,
  });

  final int outputWidth;
  final int outputHeight;

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
    return _rectify(decoded, corners);
  }

  Uint8List rectifyDetection({
    required Uint8List imageBytes,
    required ArcBlueprintGridDetection detection,
  }) {
    final decoded = _decode(imageBytes);
    if (!detection.isValid) {
      throw const FormatException('The detected Blueprint grid is invalid.');
    }
    final width = decoded.width.toDouble();
    final height = decoded.height.toDouble();
    final corners = detection.corners
        .map((point) => Offset(point.dx * width, point.dy * height))
        .toList(growable: false);
    return _rectify(decoded, corners);
  }

  img.Image _decode(Uint8List imageBytes) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw const FormatException('The captured image could not be decoded.');
    }
    return img.bakeOrientation(decoded);
  }

  Uint8List _rectify(img.Image source, List<Offset> corners) {
    final output = img.Image(width: outputWidth, height: outputHeight);
    for (var y = 0; y < outputHeight; y++) {
      final v = outputHeight <= 1 ? 0.0 : y / (outputHeight - 1);
      for (var x = 0; x < outputWidth; x++) {
        final u = outputWidth <= 1 ? 0.0 : x / (outputWidth - 1);
        final point = _bilinear(corners, u, v);
        final sx = point.dx.round().clamp(0, source.width - 1);
        final sy = point.dy.round().clamp(0, source.height - 1);
        output.setPixel(x, y, source.getPixel(sx, sy));
      }
    }
    return Uint8List.fromList(img.encodeJpg(output, quality: 95));
  }

  Offset _bilinear(List<Offset> corners, double u, double v) {
    final top = Offset.lerp(corners[0], corners[1], u)!;
    final bottom = Offset.lerp(corners[2], corners[3], u)!;
    return Offset.lerp(top, bottom, v)!;
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
    final scale =
        (viewport.width / source.width) > (viewport.height / source.height)
        ? viewport.width / source.width
        : viewport.height / source.height;
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
