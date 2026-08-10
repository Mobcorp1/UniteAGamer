import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class ArcBlueprintCameraFrameAdapter {
  const ArcBlueprintCameraFrameAdapter({this.maximumWidth = 480});

  final int maximumWidth;

  img.Image convert(CameraImage frame, {int rotationDegrees = 0}) {
    final scale = frame.width > maximumWidth ? maximumWidth / frame.width : 1.0;

    final outputWidth = math.max(1, (frame.width * scale).round());
    final outputHeight = math.max(1, (frame.height * scale).round());
    final output = img.Image(width: outputWidth, height: outputHeight);

    switch (frame.format.group) {
      case ImageFormatGroup.bgra8888:
        _copyBgra(frame, output);
        break;
      case ImageFormatGroup.yuv420:
      case ImageFormatGroup.nv21:
        _copyLuma(frame, output);
        break;
      default:
        _copyLuma(frame, output);
        break;
    }

    final normalizedRotation = rotationDegrees % 360;
    if (normalizedRotation == 90 ||
        normalizedRotation == 180 ||
        normalizedRotation == 270) {
      return img.copyRotate(output, angle: normalizedRotation.toDouble());
    }

    return output;
  }

  void _copyLuma(CameraImage frame, img.Image output) {
    if (frame.planes.isEmpty) return;

    final plane = frame.planes.first;
    final bytes = plane.bytes;
    final bytesPerRow = plane.bytesPerRow;
    final bytesPerPixel = plane.bytesPerPixel ?? 1;

    for (var y = 0; y < output.height; y++) {
      final sourceY = math.min(
        frame.height - 1,
        ((y / output.height) * frame.height).floor(),
      );

      for (var x = 0; x < output.width; x++) {
        final sourceX = math.min(
          frame.width - 1,
          ((x / output.width) * frame.width).floor(),
        );

        final index = (sourceY * bytesPerRow) + (sourceX * bytesPerPixel);

        if (index < 0 || index >= bytes.length) continue;

        final luminance = bytes[index];
        output.setPixel(x, y, img.ColorRgb8(luminance, luminance, luminance));
      }
    }
  }

  void _copyBgra(CameraImage frame, img.Image output) {
    if (frame.planes.isEmpty) return;

    final plane = frame.planes.first;
    final bytes = plane.bytes;
    final bytesPerRow = plane.bytesPerRow;
    final bytesPerPixel = plane.bytesPerPixel ?? 4;

    for (var y = 0; y < output.height; y++) {
      final sourceY = math.min(
        frame.height - 1,
        ((y / output.height) * frame.height).floor(),
      );

      for (var x = 0; x < output.width; x++) {
        final sourceX = math.min(
          frame.width - 1,
          ((x / output.width) * frame.width).floor(),
        );

        final index = (sourceY * bytesPerRow) + (sourceX * bytesPerPixel);

        if (index < 0 || index + 2 >= bytes.length) continue;

        final blue = bytes[index];
        final green = bytes[index + 1];
        final red = bytes[index + 2];

        final luminance = ((red * 0.2126) + (green * 0.7152) + (blue * 0.0722))
            .round()
            .clamp(0, 255);

        output.setPixel(x, y, img.ColorRgb8(luminance, luminance, luminance));
      }
    }
  }
}
