import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';

class ArcBlueprintPhotoPixelAnalysis {
  const ArcBlueprintPhotoPixelAnalysis({
    required this.samples,
    required this.error,
  });

  final List<ArcBlueprintPhotoOccupancySample> samples;
  final String error;

  bool get succeeded => error.isEmpty && samples.isNotEmpty;
}

class ArcBlueprintPhotoPixelAnalyzer {
  const ArcBlueprintPhotoPixelAnalyzer({this.columns = 10, this.rows = 5});

  final int columns;
  final int rows;

  ArcBlueprintPhotoPixelAnalysis analyze({
    required Uint8List bytes,
    required String captureId,
  }) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } on Object {
      return const ArcBlueprintPhotoPixelAnalysis(
        samples: <ArcBlueprintPhotoOccupancySample>[],
        error: 'The selected image could not be decoded.',
      );
    }
    if (decoded == null) {
      return const ArcBlueprintPhotoPixelAnalysis(
        samples: <ArcBlueprintPhotoOccupancySample>[],
        error: 'The selected image could not be decoded.',
      );
    }
    if (decoded.width < columns * 12 || decoded.height < rows * 12) {
      return const ArcBlueprintPhotoPixelAnalysis(
        samples: <ArcBlueprintPhotoOccupancySample>[],
        error: 'The image is too small to analyse the Blueprint grid.',
      );
    }

    final rawFeatures = <double>[];
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        rawFeatures.add(_cellFeature(decoded, row, column));
      }
    }

    final sorted = List<double>.from(rawFeatures)..sort();
    final low = _percentile(sorted, 0.12);
    final high = _percentile(sorted, 0.88);
    final span = math.max(0.0001, high - low);

    final samples = <ArcBlueprintPhotoOccupancySample>[];
    for (var index = 0; index < rawFeatures.length; index++) {
      final normalized = ((rawFeatures[index] - low) / span).clamp(0.0, 1.0);
      samples.add(
        ArcBlueprintPhotoOccupancySample(
          captureId: captureId,
          rowIndex: index ~/ columns,
          columnIndex: index % columns,
          occupancyScore: normalized.toDouble(),
        ),
      );
    }

    return ArcBlueprintPhotoPixelAnalysis(samples: samples, error: '');
  }

  double _cellFeature(img.Image image, int row, int column) {
    final cellWidth = image.width / columns;
    final cellHeight = image.height / rows;
    final left = ((column + 0.12) * cellWidth).round();
    final right = ((column + 0.88) * cellWidth).round();
    final top = ((row + 0.14) * cellHeight).round();
    final bottom = ((row + 0.86) * cellHeight).round();
    final stride = math.max(
      1,
      math.min((right - left) ~/ 18, (bottom - top) ~/ 14),
    );

    var count = 0;
    var luminanceSum = 0.0;
    var luminanceSquaredSum = 0.0;
    var saturationSum = 0.0;
    var edgeSum = 0.0;

    for (var y = top; y < bottom; y += stride) {
      for (var x = left; x < right; x += stride) {
        final pixel = image.getPixelSafe(x, y);
        final red = pixel.r.toDouble();
        final green = pixel.g.toDouble();
        final blue = pixel.b.toDouble();
        final maxChannel = math.max(red, math.max(green, blue));
        final minChannel = math.min(red, math.min(green, blue));
        final luminance = (red * 0.2126) + (green * 0.7152) + (blue * 0.0722);
        final saturation = maxChannel <= 0
            ? 0.0
            : (maxChannel - minChannel) / maxChannel;

        luminanceSum += luminance;
        luminanceSquaredSum += luminance * luminance;
        saturationSum += saturation;

        final nextX = math.min(right - 1, x + stride);
        final nextY = math.min(bottom - 1, y + stride);
        final horizontal = image.getPixelSafe(nextX, y);
        final vertical = image.getPixelSafe(x, nextY);
        final horizontalLuminance =
            (horizontal.r.toDouble() * 0.2126) +
            (horizontal.g.toDouble() * 0.7152) +
            (horizontal.b.toDouble() * 0.0722);
        final verticalLuminance =
            (vertical.r.toDouble() * 0.2126) +
            (vertical.g.toDouble() * 0.7152) +
            (vertical.b.toDouble() * 0.0722);
        edgeSum += (luminance - horizontalLuminance).abs();
        edgeSum += (luminance - verticalLuminance).abs();
        count++;
      }
    }

    if (count == 0) return 0;
    final mean = luminanceSum / count;
    final variance = math.max(
      0.0,
      (luminanceSquaredSum / count) - (mean * mean),
    );
    final texture = math.sqrt(variance) / 96.0;
    final saturation = saturationSum / count;
    final edges = (edgeSum / (count * 2)) / 96.0;
    return (texture * 0.48) + (saturation * 0.22) + (edges * 0.30);
  }

  double _percentile(List<double> sorted, double percentile) {
    if (sorted.isEmpty) return 0;
    final position = ((sorted.length - 1) * percentile).round();
    return sorted[position.clamp(0, sorted.length - 1).toInt()];
  }
}
