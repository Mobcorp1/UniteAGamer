import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

@immutable
class ArcBlueprintCellEvidence {
  const ArcBlueprintCellEvidence({
    required this.occupancyScore,
    required this.confidence,
    required this.texture,
    required this.edgeDensity,
    required this.saturation,
    required this.foregroundCoverage,
    required this.luminanceRange,
    required this.blueprintBlueCoverage,
    required this.brightFeatureCoverage,
    required this.windowAgreement,
  });

  const ArcBlueprintCellEvidence.empty()
    : occupancyScore = 0,
      confidence = 1,
      texture = 0,
      edgeDensity = 0,
      saturation = 0,
      foregroundCoverage = 0,
      luminanceRange = 0,
      blueprintBlueCoverage = 0,
      brightFeatureCoverage = 0,
      windowAgreement = 1;

  final double occupancyScore;
  final double confidence;
  final double texture;
  final double edgeDensity;
  final double saturation;
  final double foregroundCoverage;
  final double luminanceRange;
  final double blueprintBlueCoverage;
  final double brightFeatureCoverage;
  final double windowAgreement;
}

class ArcBlueprintCellAnalyzer {
  const ArcBlueprintCellAnalyzer({
    required this.columns,
    required this.rows,
    this.validColumnCountsByRow = const <int>[],
  });

  final int columns;
  final int rows;
  final List<int> validColumnCountsByRow;

  List<ArcBlueprintCellEvidence> analyze(img.Image image) {
    return <ArcBlueprintCellEvidence>[
      for (var row = 0; row < rows; row++)
        for (var column = 0; column < _validColumnsForRow(row); column++)
          _analyzeCell(
            image,
            row,
            column,
            rowColumnCount: _validColumnsForRow(row),
          ),
    ];
  }

  int _validColumnsForRow(int row) {
    if (validColumnCountsByRow.isEmpty ||
        row < 0 ||
        row >= validColumnCountsByRow.length) {
      return columns;
    }
    return validColumnCountsByRow[row].clamp(0, columns);
  }

  ArcBlueprintCellEvidence _analyzeCell(
    img.Image image,
    int row,
    int column, {
    required int rowColumnCount,
  }) {
    final cellWidth = image.width / columns;
    final cellHeight = image.height / rows;

    final windows = <_Window>[
      const _Window(left: 0.10, top: 0.10, right: 0.90, bottom: 0.90),
      const _Window(left: 0.05, top: 0.07, right: 0.95, bottom: 0.93),
      const _Window(left: 0.16, top: 0.14, right: 0.84, bottom: 0.86),
    ];

    // Edge cells receive one additional inward-shifted window. This protects
    // first/last-column Blueprints when the detected crop clips a few pixels.
    if (column == 0) {
      windows.add(
        const _Window(left: 0.00, top: 0.09, right: 0.94, bottom: 0.91),
      );
    } else if (column == rowColumnCount - 1) {
      windows.add(
        const _Window(left: 0.06, top: 0.09, right: 1.00, bottom: 0.91),
      );
    }

    final measurements = windows
        .map(
          (window) => _measureWindow(
            image: image,
            row: row,
            column: column,
            cellWidth: cellWidth,
            cellHeight: cellHeight,
            window: window,
          ),
        )
        .toList(growable: false);

    if (measurements.isEmpty) {
      return const ArcBlueprintCellEvidence.empty();
    }

    final scores =
        measurements
            .map((measurement) => measurement.occupancyScore)
            .toList(growable: false)
          ..sort();

    final median = scores[scores.length ~/ 2];
    final maximum = scores.last;
    final minimum = scores.first;
    final spread = maximum - minimum;
    final agreement = (1 - (spread / 0.62)).clamp(0.0, 1.0);

    // Median prevents one noisy window creating a false positive. A limited
    // contribution from the strongest window recovers partially clipped art.
    var occupancy = ((median * 0.78) + (maximum * 0.22)).clamp(0.0, 1.0);

    final averageTexture = _average(
      measurements.map((measurement) => measurement.texture),
    );
    final averageEdges = _average(
      measurements.map((measurement) => measurement.edgeDensity),
    );
    final averageSaturation = _average(
      measurements.map((measurement) => measurement.saturation),
    );
    final averageCoverage = _average(
      measurements.map((measurement) => measurement.foregroundCoverage),
    );
    final averageRange = _average(
      measurements.map((measurement) => measurement.luminanceRange),
    );
    final averageBlueprintBlue = _average(
      measurements.map((measurement) => measurement.blueprintBlueCoverage),
    );
    final averageBrightFeature = _average(
      measurements.map((measurement) => measurement.brightFeatureCoverage),
    );

    // Uniform dark/grey panels must remain empty regardless of relative
    // brightness differences across the captured screen.
    final clearlyEmpty =
        averageTexture < 0.09 &&
        averageEdges < 0.09 &&
        averageSaturation < 0.10 &&
        averageCoverage < 0.08 &&
        averageRange < 0.12;
    if (clearlyEmpty) {
      occupancy = math.min(occupancy, 0.16);
    }

    // Artwork normally provides several independent signals. This rule keeps
    // a real Blueprint occupied even when glare suppresses one signal.
    final clearlyOccupied =
        averageCoverage >= 0.18 &&
        ((averageTexture >= 0.15 && averageEdges >= 0.14) ||
            (averageSaturation >= 0.18 && averageRange >= 0.18));
    if (clearlyOccupied) {
      occupancy = math.max(occupancy, 0.70);
    }

    final distanceFromUncertainBand = ((occupancy - 0.50).abs() * 2).clamp(
      0.0,
      1.0,
    );
    final confidence = ((agreement * 0.42) + (distanceFromUncertainBand * 0.58))
        .clamp(0.0, 1.0);

    return ArcBlueprintCellEvidence(
      occupancyScore: occupancy.toDouble(),
      confidence: confidence.toDouble(),
      texture: averageTexture,
      edgeDensity: averageEdges,
      saturation: averageSaturation,
      foregroundCoverage: averageCoverage,
      luminanceRange: averageRange,
      blueprintBlueCoverage: averageBlueprintBlue,
      brightFeatureCoverage: averageBrightFeature,
      windowAgreement: agreement.toDouble(),
    );
  }

  _WindowMeasurement _measureWindow({
    required img.Image image,
    required int row,
    required int column,
    required double cellWidth,
    required double cellHeight,
    required _Window window,
  }) {
    final cellLeft = column * cellWidth;
    final cellTop = row * cellHeight;

    final left = (cellLeft + (cellWidth * window.left)).round().clamp(
      0,
      image.width - 2,
    );
    final right = (cellLeft + (cellWidth * window.right)).round().clamp(
      left + 1,
      image.width - 1,
    );
    final top = (cellTop + (cellHeight * window.top)).round().clamp(
      0,
      image.height - 2,
    );
    final bottom = (cellTop + (cellHeight * window.bottom)).round().clamp(
      top + 1,
      image.height - 1,
    );

    final stride = math.max(
      1,
      math.min(
        math.max(1, (right - left) ~/ 24),
        math.max(1, (bottom - top) ~/ 20),
      ),
    );

    final luminanceValues = <double>[];
    var saturationSum = 0.0;
    var edgeSum = 0.0;
    var foregroundPixels = 0;
    var blueprintBluePixels = 0;
    var brightFeaturePixels = 0;
    var count = 0;

    for (var y = top; y < bottom; y += stride) {
      for (var x = left; x < right; x += stride) {
        final pixel = image.getPixelSafe(x, y);
        final luminance = _luma(pixel);
        final saturation = _saturation(pixel);

        luminanceValues.add(luminance);
        saturationSum += saturation;

        final nextX = math.min(right - 1, x + stride);
        final nextY = math.min(bottom - 1, y + stride);
        final horizontalDifference =
            (luminance - _luma(image.getPixelSafe(nextX, y))).abs();
        final verticalDifference =
            (luminance - _luma(image.getPixelSafe(x, nextY))).abs();

        edgeSum += horizontalDifference + verticalDifference;

        if ((saturation >= 0.15 && luminance >= 20) ||
            horizontalDifference >= 22 ||
            verticalDifference >= 22) {
          foregroundPixels++;
        }

        final red = pixel.r.toDouble();
        final green = pixel.g.toDouble();
        final blue = pixel.b.toDouble();
        if (blue >= 92 &&
            blue >= (red * 1.30) &&
            blue >= (green * 1.04) &&
            saturation >= 0.34 &&
            luminance >= 32) {
          blueprintBluePixels++;
        }

        if (luminance >= 128 || (red >= 118 && green >= 118 && blue >= 118)) {
          brightFeaturePixels++;
        }

        count++;
      }
    }

    if (count == 0 || luminanceValues.isEmpty) {
      return const _WindowMeasurement.empty();
    }

    luminanceValues.sort();
    final mean = luminanceValues.reduce((a, b) => a + b) / count;

    var varianceSum = 0.0;
    for (final value in luminanceValues) {
      final delta = value - mean;
      varianceSum += delta * delta;
    }

    final texture = (math.sqrt(varianceSum / count) / 70.0).clamp(0.0, 1.0);
    final edgeDensity = ((edgeSum / (count * 2)) / 68.0).clamp(0.0, 1.0);
    final saturation = (saturationSum / count).clamp(0.0, 1.0);
    final foregroundCoverage = (foregroundPixels / count).clamp(0.0, 1.0);
    final blueprintBlueCoverage = (blueprintBluePixels / count).clamp(0.0, 1.0);
    final brightFeatureCoverage = (brightFeaturePixels / count).clamp(0.0, 1.0);
    final luminanceRange =
        ((_percentile(luminanceValues, 0.90) -
                    _percentile(luminanceValues, 0.10)) /
                145.0)
            .clamp(0.0, 1.0);

    final combined =
        ((blueprintBlueCoverage * 0.42) +
                (brightFeatureCoverage * 0.24) +
                (texture * 0.12) +
                (edgeDensity * 0.10) +
                (foregroundCoverage * 0.06) +
                (luminanceRange * 0.06))
            .clamp(0.0, 1.0);

    var occupancy = _sigmoid((combined - 0.205) * 13.5);

    final strongBlueprintSignature =
        blueprintBlueCoverage >= 0.135 &&
        brightFeatureCoverage >= 0.035 &&
        (texture >= 0.13 || edgeDensity >= 0.11) &&
        luminanceRange >= 0.10;

    final obviousEmptySignature =
        blueprintBlueCoverage < 0.065 &&
        brightFeatureCoverage < 0.035 &&
        texture < 0.16 &&
        edgeDensity < 0.15;

    if (strongBlueprintSignature) {
      occupancy = math.max(occupancy, 0.86);
    } else {
      occupancy = math.min(occupancy, 0.79);
    }

    if (obviousEmptySignature) {
      occupancy = math.min(occupancy, 0.16);
    }

    return _WindowMeasurement(
      occupancyScore: occupancy,
      texture: texture,
      edgeDensity: edgeDensity,
      saturation: saturation,
      foregroundCoverage: foregroundCoverage,
      luminanceRange: luminanceRange,
      blueprintBlueCoverage: blueprintBlueCoverage,
      brightFeatureCoverage: brightFeatureCoverage,
    );
  }

  double _average(Iterable<double> values) {
    var total = 0.0;
    var count = 0;
    for (final value in values) {
      total += value;
      count++;
    }
    return count == 0 ? 0 : total / count;
  }

  double _luma(img.Pixel pixel) =>
      (pixel.r.toDouble() * 0.2126) +
      (pixel.g.toDouble() * 0.7152) +
      (pixel.b.toDouble() * 0.0722);

  double _saturation(img.Pixel pixel) {
    final red = pixel.r.toDouble();
    final green = pixel.g.toDouble();
    final blue = pixel.b.toDouble();
    final maximum = math.max(red, math.max(green, blue));
    final minimum = math.min(red, math.min(green, blue));
    return maximum <= 0 ? 0 : (maximum - minimum) / maximum;
  }

  double _percentile(List<double> sorted, double percentile) {
    if (sorted.isEmpty) return 0;
    final position = ((sorted.length - 1) * percentile).round();
    return sorted[position.clamp(0, sorted.length - 1).toInt()];
  }

  double _sigmoid(double value) => 1 / (1 + math.exp(-value));
}

@immutable
class _Window {
  const _Window({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;
}

@immutable
class _WindowMeasurement {
  const _WindowMeasurement({
    required this.occupancyScore,
    required this.texture,
    required this.edgeDensity,
    required this.saturation,
    required this.foregroundCoverage,
    required this.luminanceRange,
    required this.blueprintBlueCoverage,
    required this.brightFeatureCoverage,
  });

  const _WindowMeasurement.empty()
    : occupancyScore = 0,
      texture = 0,
      edgeDensity = 0,
      saturation = 0,
      foregroundCoverage = 0,
      luminanceRange = 0,
      blueprintBlueCoverage = 0,
      brightFeatureCoverage = 0;

  final double occupancyScore;
  final double texture;
  final double edgeDensity;
  final double saturation;
  final double foregroundCoverage;
  final double luminanceRange;
  final double blueprintBlueCoverage;
  final double brightFeatureCoverage;
}
