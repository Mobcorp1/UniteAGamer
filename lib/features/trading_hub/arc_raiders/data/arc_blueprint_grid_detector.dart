import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

class ArcBlueprintGridDetector {
  const ArcBlueprintGridDetector({
    this.analysisWidth = 720,
    this.minimumConfidence = 0.58,
    this.columns = 10,
    this.rows = 5,
  });

  final int analysisWidth;
  final double minimumConfidence;
  final int columns;
  final int rows;

  ArcBlueprintGridDetection detect(Uint8List bytes) {
    final decoded = _decode(bytes);
    if (decoded == null) {
      return ArcBlueprintGridDetection.notFound(
        message: 'Captured image could not be decoded.',
        columns: columns,
        rows: rows,
      );
    }

    final oriented = img.bakeOrientation(decoded);
    final scale = oriented.width > analysisWidth
        ? analysisWidth / oriented.width
        : 1.0;
    final image = scale < 1
        ? img.copyResize(
            oriented,
            width: analysisWidth,
            interpolation: img.Interpolation.average,
          )
        : oriented;

    if (image.width < 220 || image.height < 120) {
      return ArcBlueprintGridDetection.notFound(
        message: 'Captured image is too small for grid detection.',
        columns: columns,
        rows: rows,
      );
    }

    final vertical = _findRegularGrid(
      profile: _verticalEdgeProfile(image),
      expectedLines: columns + 1,
      minimumSpanFraction: 0.44,
    );
    final horizontal = _findRegularGrid(
      profile: _horizontalEdgeProfile(image),
      expectedLines: rows + 1,
      minimumSpanFraction: rows >= 5 ? 0.32 : 0.20,
    );

    if (vertical == null || horizontal == null) {
      return ArcBlueprintGridDetection.notFound(
        message: 'The Blueprint grid divider lines could not be isolated.',
        columns: columns,
        rows: rows,
      );
    }

    final width = image.width.toDouble();
    final height = image.height.toDouble();
    final verticalDividers = vertical.positions
        .map((position) => position / width)
        .toList(growable: false);
    final horizontalDividers = horizontal.positions
        .map((position) => position / height)
        .toList(growable: false);

    final confidence = _combinedConfidence(
      vertical.confidence,
      horizontal.confidence,
    );

    final detection = ArcBlueprintGridDetection(
      topLeft: Offset(verticalDividers.first, horizontalDividers.first),
      topRight: Offset(verticalDividers.last, horizontalDividers.first),
      bottomLeft: Offset(verticalDividers.first, horizontalDividers.last),
      bottomRight: Offset(verticalDividers.last, horizontalDividers.last),
      confidence: confidence,
      message: confidence >= minimumConfidence
          ? 'Grid locked'
          : 'Grid detected with low confidence',
      columns: columns,
      rows: rows,
      verticalDividers: verticalDividers,
      horizontalDividers: horizontalDividers,
    );

    if (!detection.isValid || !detection.hasSegmentedGrid) {
      return ArcBlueprintGridDetection.notFound(
        message: 'The detected Blueprint panel is not a valid grid.',
        columns: columns,
        rows: rows,
      );
    }

    return detection;
  }

  img.Image? _decode(Uint8List bytes) {
    try {
      return img.decodeImage(bytes);
    } on Object {
      return null;
    }
  }

  List<double> _verticalEdgeProfile(img.Image image) {
    final startY = (image.height * 0.05).round();
    final endY = (image.height * 0.95).round();
    final profile = List<double>.filled(image.width, 0);

    for (var x = 1; x < image.width - 1; x++) {
      var gradient = 0.0;
      var contrast = 0.0;
      var count = 0;

      for (var y = startY; y < endY; y += 2) {
        final left = _luma(image.getPixelSafe(x - 1, y));
        final right = _luma(image.getPixelSafe(x + 1, y));
        final centre = _luma(image.getPixelSafe(x, y));

        gradient += (right - left).abs();
        contrast += ((centre - left).abs() + (centre - right).abs()) * 0.5;
        count++;
      }

      profile[x] = count == 0
          ? 0
          : ((gradient * 0.72) + (contrast * 0.28)) / count;
    }

    return _smooth(profile, radius: 2);
  }

  List<double> _horizontalEdgeProfile(img.Image image) {
    final startX = (image.width * 0.04).round();
    final endX = (image.width * 0.96).round();
    final profile = List<double>.filled(image.height, 0);

    for (var y = 1; y < image.height - 1; y++) {
      var gradient = 0.0;
      var contrast = 0.0;
      var count = 0;

      for (var x = startX; x < endX; x += 2) {
        final above = _luma(image.getPixelSafe(x, y - 1));
        final below = _luma(image.getPixelSafe(x, y + 1));
        final centre = _luma(image.getPixelSafe(x, y));

        gradient += (below - above).abs();
        contrast += ((centre - above).abs() + (centre - below).abs()) * 0.5;
        count++;
      }

      profile[y] = count == 0
          ? 0
          : ((gradient * 0.72) + (contrast * 0.28)) / count;
    }

    return _smooth(profile, radius: 2);
  }

  _AxisSegmentation? _findRegularGrid({
    required List<double> profile,
    required int expectedLines,
    required double minimumSpanFraction,
  }) {
    if (expectedLines < 2 || profile.length < expectedLines * 7) {
      return null;
    }

    final peaks = _candidatePeaks(profile);
    if (peaks.length < expectedLines) return null;

    final strongest = List<int>.from(peaks)
      ..sort((a, b) => profile[b].compareTo(profile[a]));
    final anchors = strongest.take(math.min(30, strongest.length)).toList();

    final minimumStep = math.max(6.0, profile.length * 0.025);
    final maximumStep = profile.length / (expectedLines - 1);

    _AxisSegmentation? best;

    for (final first in anchors) {
      for (final last in anchors) {
        if (last <= first) continue;

        final span = last - first;
        if (span < profile.length * minimumSpanFraction) continue;

        final step = span / (expectedLines - 1);
        if (step < minimumStep || step > maximumStep) continue;

        final radius = math.max(2, (step * 0.22).round());
        final positions = <int>[];
        final strengths = <double>[];

        var previous = -1;
        var valid = true;

        for (var line = 0; line < expectedLines; line++) {
          final expected = (first + (step * line)).round();
          final snapped = _nearestStrongPeak(profile, expected, radius);

          if (snapped == null || snapped <= previous) {
            valid = false;
            break;
          }

          positions.add(snapped);
          strengths.add(profile[snapped]);
          previous = snapped;
        }

        if (!valid || positions.toSet().length != expectedLines) continue;

        final spacingScore = _spacingRegularity(positions);
        final strengthScore = _relativeStrength(profile, strengths);
        final alignmentScore = _expectedAlignmentScore(
          positions,
          first: first,
          last: last,
        );
        final coverageScore =
            ((positions.last - positions.first) / profile.length).clamp(
              0.0,
              1.0,
            );

        final score =
            (spacingScore * 0.38) +
            (strengthScore * 0.34) +
            (alignmentScore * 0.20) +
            (coverageScore * 0.08);

        if (best == null || score > best.confidence) {
          best = _AxisSegmentation(
            positions: positions,
            confidence: score.clamp(0.0, 1.0),
          );
        }
      }
    }

    if (best == null || best.confidence < 0.42) return null;
    return best;
  }

  List<int> _candidatePeaks(List<double> profile) {
    final sorted = List<double>.from(profile)..sort();
    final median = sorted[sorted.length ~/ 2];
    final high = sorted[(sorted.length * 0.82).floor()];
    final threshold = median + ((high - median) * 0.42);

    final candidates = <int>[];

    for (var index = 2; index < profile.length - 2; index++) {
      final value = profile[index];
      if (value < threshold) continue;

      if (value >= profile[index - 1] &&
          value >= profile[index + 1] &&
          value >= profile[index - 2] &&
          value >= profile[index + 2]) {
        candidates.add(index);
      }
    }

    final collapsed = <int>[];
    for (final candidate in candidates) {
      if (collapsed.isEmpty || candidate - collapsed.last > 4) {
        collapsed.add(candidate);
      } else if (profile[candidate] > profile[collapsed.last]) {
        collapsed[collapsed.length - 1] = candidate;
      }
    }

    return collapsed;
  }

  int? _nearestStrongPeak(List<double> profile, int centre, int radius) {
    final start = (centre - radius).clamp(1, profile.length - 2);
    final end = (centre + radius).clamp(start + 1, profile.length - 1);

    var bestIndex = -1;
    var bestValue = -1.0;

    for (var index = start; index < end; index++) {
      if (profile[index] > bestValue) {
        bestValue = profile[index];
        bestIndex = index;
      }
    }

    if (bestIndex < 0) return null;

    final sorted = List<double>.from(profile)..sort();
    final median = sorted[sorted.length ~/ 2];
    final high = sorted[(sorted.length * 0.82).floor()];
    final minimum = median + ((high - median) * 0.28);

    return bestValue >= minimum ? bestIndex : null;
  }

  double _spacingRegularity(List<int> positions) {
    if (positions.length < 3) return 0;

    final gaps = <double>[
      for (var index = 1; index < positions.length; index++)
        (positions[index] - positions[index - 1]).toDouble(),
    ];

    final mean = gaps.reduce((a, b) => a + b) / gaps.length;
    if (mean <= 0) return 0;

    final variance =
        gaps
            .map((gap) => math.pow(gap - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        gaps.length;

    final coefficient = math.sqrt(variance) / mean;
    return (1 - (coefficient / 0.22)).clamp(0.0, 1.0);
  }

  double _expectedAlignmentScore(
    List<int> positions, {
    required int first,
    required int last,
  }) {
    final step = (last - first) / (positions.length - 1);
    if (step <= 0) return 0;

    var error = 0.0;
    for (var index = 0; index < positions.length; index++) {
      final expected = first + (step * index);
      error += (positions[index] - expected).abs() / step;
    }

    return (1 - ((error / positions.length) / 0.20)).clamp(0.0, 1.0);
  }

  double _relativeStrength(List<double> profile, List<double> strengths) {
    final sorted = List<double>.from(profile)..sort();
    final baseline = sorted[(sorted.length * 0.60).floor()];
    final upper = sorted[(sorted.length * 0.95).floor()];

    if (upper <= baseline) return 0;

    final average = strengths.reduce((a, b) => a + b) / strengths.length;

    return ((average - baseline) / (upper - baseline)).clamp(0.0, 1.0);
  }

  List<double> _smooth(List<double> source, {required int radius}) {
    final result = List<double>.filled(source.length, 0);

    for (var index = 0; index < source.length; index++) {
      var weighted = 0.0;
      var weights = 0.0;

      final start = math.max(0, index - radius);
      final end = math.min(source.length - 1, index + radius);

      for (var sample = start; sample <= end; sample++) {
        final distance = (sample - index).abs();
        final weight = (radius + 1 - distance).toDouble();
        weighted += source[sample] * weight;
        weights += weight;
      }

      result[index] = weights == 0 ? source[index] : weighted / weights;
    }

    return result;
  }

  double _combinedConfidence(double vertical, double horizontal) {
    final weaker = math.min(vertical, horizontal);
    final stronger = math.max(vertical, horizontal);
    return ((weaker * 0.76) + (stronger * 0.24)).clamp(0.0, 1.0);
  }

  double _luma(img.Pixel pixel) =>
      (pixel.r.toDouble() * 0.2126) +
      (pixel.g.toDouble() * 0.7152) +
      (pixel.b.toDouble() * 0.0722);
}

class _AxisSegmentation {
  const _AxisSegmentation({required this.positions, required this.confidence});

  final List<int> positions;
  final double confidence;
}
