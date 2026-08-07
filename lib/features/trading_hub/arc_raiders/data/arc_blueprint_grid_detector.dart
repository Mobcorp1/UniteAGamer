import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

class ArcBlueprintGridDetector {
  const ArcBlueprintGridDetector({
    this.analysisWidth = 720,
    this.minimumConfidence = 0.62,
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
      return const ArcBlueprintGridDetection.notFound(
        message: 'Captured image could not be decoded.',
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

    if (image.width < 220 || image.height < 130) {
      return const ArcBlueprintGridDetection.notFound(
        message: 'Captured image is too small for grid detection.',
      );
    }

    final verticalProfile = _verticalEdgeProfile(image);
    final horizontalProfile = _horizontalEdgeProfile(image);

    final vertical = _segmentAxis(
      profile: verticalProfile,
      expectedLines: columns + 1,
      minimumSpanFraction: 0.48,
      outerSearchFraction: 0.34,
    );
    final horizontal = _segmentAxis(
      profile: horizontalProfile,
      expectedLines: rows + 1,
      minimumSpanFraction: 0.38,
      outerSearchFraction: 0.38,
    );

    if (vertical == null || horizontal == null) {
      return const ArcBlueprintGridDetection.notFound(
        message: 'The Blueprint grid divider lines could not be isolated.',
      );
    }

    final width = image.width.toDouble();
    final height = image.height.toDouble();
    final normalizedVertical = vertical.positions
        .map((position) => position / width)
        .toList(growable: false);
    final normalizedHorizontal = horizontal.positions
        .map((position) => position / height)
        .toList(growable: false);

    final confidence = _combinedConfidence(
      vertical.confidence,
      horizontal.confidence,
    );
    final detection = ArcBlueprintGridDetection(
      topLeft: Offset(normalizedVertical.first, normalizedHorizontal.first),
      topRight: Offset(normalizedVertical.last, normalizedHorizontal.first),
      bottomLeft: Offset(normalizedVertical.first, normalizedHorizontal.last),
      bottomRight: Offset(normalizedVertical.last, normalizedHorizontal.last),
      confidence: confidence,
      message: confidence >= minimumConfidence
          ? 'Grid locked'
          : 'Grid detected with low confidence',
      verticalDividers: normalizedVertical,
      horizontalDividers: normalizedHorizontal,
    );

    if (!detection.isValid) {
      return const ArcBlueprintGridDetection.notFound(
        message: 'The detected Blueprint panel is not a valid rectangle.',
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
    final startY = (image.height * 0.08).round();
    final endY = (image.height * 0.92).round();
    final profile = List<double>.filled(image.width, 0);

    for (var x = 1; x < image.width - 1; x++) {
      var value = 0.0;
      var count = 0;
      for (var y = startY; y < endY; y += 2) {
        value +=
            (_luma(image.getPixelSafe(x + 1, y)) -
                    _luma(image.getPixelSafe(x - 1, y)))
                .abs();
        count++;
      }
      profile[x] = count == 0 ? 0 : value / count;
    }
    return _smooth(profile, radius: 2);
  }

  List<double> _horizontalEdgeProfile(img.Image image) {
    final startX = (image.width * 0.06).round();
    final endX = (image.width * 0.94).round();
    final profile = List<double>.filled(image.height, 0);

    for (var y = 1; y < image.height - 1; y++) {
      var value = 0.0;
      var count = 0;
      for (var x = startX; x < endX; x += 2) {
        value +=
            (_luma(image.getPixelSafe(x, y + 1)) -
                    _luma(image.getPixelSafe(x, y - 1)))
                .abs();
        count++;
      }
      profile[y] = count == 0 ? 0 : value / count;
    }
    return _smooth(profile, radius: 2);
  }

  _AxisSegmentation? _segmentAxis({
    required List<double> profile,
    required int expectedLines,
    required double minimumSpanFraction,
    required double outerSearchFraction,
  }) {
    if (profile.length < expectedLines * 8) return null;

    final leftEnd = (profile.length * outerSearchFraction).round();
    final rightStart = (profile.length * (1 - outerSearchFraction)).round();
    final leftCandidates = _strongestPeaks(profile, 1, leftEnd, maximum: 12);
    final rightCandidates = _strongestPeaks(
      profile,
      rightStart,
      profile.length - 1,
      maximum: 12,
    );

    _AxisSegmentation? best;
    for (final first in leftCandidates) {
      for (final last in rightCandidates) {
        final span = last - first;
        if (span < profile.length * minimumSpanFraction) continue;

        final step = span / (expectedLines - 1);
        final radius = math.max(2, (step * 0.18).round());
        final positions = <int>[];
        final strengths = <double>[];

        var previous = -1;
        var valid = true;
        for (var line = 0; line < expectedLines; line++) {
          final expected = first + (step * line);
          final candidate = _localPeak(profile, expected.round(), radius);
          if (candidate <= previous) {
            valid = false;
            break;
          }
          positions.add(candidate);
          strengths.add(profile[candidate]);
          previous = candidate;
        }
        if (!valid) continue;

        final spacingScore = _spacingRegularity(positions);
        final strengthScore = _relativeStrength(profile, strengths);
        final boundaryScore =
            (_normalizedPeak(profile, first) + _normalizedPeak(profile, last)) /
            2;
        final score =
            (spacingScore * 0.46) +
            (strengthScore * 0.34) +
            (boundaryScore * 0.20);

        if (best == null || score > best.confidence) {
          best = _AxisSegmentation(
            positions: positions,
            confidence: score.clamp(0.0, 1.0),
          );
        }
      }
    }
    return best;
  }

  List<int> _strongestPeaks(
    List<double> profile,
    int start,
    int end, {
    required int maximum,
  }) {
    final candidates = <int>[];
    final safeStart = start.clamp(1, profile.length - 2);
    final safeEnd = end.clamp(safeStart + 1, profile.length - 1);
    for (var index = safeStart; index < safeEnd; index++) {
      final value = profile[index];
      if (value >= profile[index - 1] && value >= profile[index + 1]) {
        candidates.add(index);
      }
    }
    candidates.sort((a, b) => profile[b].compareTo(profile[a]));
    return candidates.take(maximum).toList(growable: false);
  }

  int _localPeak(List<double> profile, int centre, int radius) {
    final start = (centre - radius).clamp(1, profile.length - 2);
    final end = (centre + radius).clamp(start + 1, profile.length - 1);
    var bestIndex = start;
    var bestValue = profile[start];
    for (var index = start + 1; index < end; index++) {
      if (profile[index] > bestValue) {
        bestValue = profile[index];
        bestIndex = index;
      }
    }
    return bestIndex;
  }

  double _spacingRegularity(List<int> positions) {
    if (positions.length < 3) return 0;
    final gaps = <double>[];
    for (var index = 1; index < positions.length; index++) {
      gaps.add((positions[index] - positions[index - 1]).toDouble());
    }
    final mean = gaps.reduce((a, b) => a + b) / gaps.length;
    if (mean <= 0) return 0;
    final variance =
        gaps
            .map((gap) => math.pow(gap - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        gaps.length;
    final coefficient = math.sqrt(variance) / mean;
    return (1 - (coefficient / 0.28)).clamp(0.0, 1.0);
  }

  double _relativeStrength(List<double> profile, List<double> strengths) {
    if (strengths.isEmpty) return 0;
    final sorted = List<double>.from(profile)..sort();
    final baseline = sorted[(sorted.length * 0.70).floor()];
    final peak = sorted.last;
    if (peak <= baseline) return 0;
    final average = strengths.reduce((a, b) => a + b) / strengths.length;
    return ((average - baseline) / (peak - baseline)).clamp(0.0, 1.0);
  }

  double _normalizedPeak(List<double> profile, int index) {
    final sorted = List<double>.from(profile)..sort();
    final low = sorted[(sorted.length * 0.55).floor()];
    final high = sorted.last;
    if (high <= low) return 0;
    return ((profile[index] - low) / (high - low)).clamp(0.0, 1.0);
  }

  List<double> _smooth(List<double> source, {required int radius}) {
    final result = List<double>.filled(source.length, 0);
    for (var index = 0; index < source.length; index++) {
      var sum = 0.0;
      var count = 0;
      final start = math.max(0, index - radius);
      final end = math.min(source.length - 1, index + radius);
      for (var sample = start; sample <= end; sample++) {
        sum += source[sample];
        count++;
      }
      result[index] = count == 0 ? source[index] : sum / count;
    }
    return result;
  }

  double _combinedConfidence(double vertical, double horizontal) {
    final lower = math.min(vertical, horizontal);
    final upper = math.max(vertical, horizontal);
    return ((lower * 0.70) + (upper * 0.30)).clamp(0.0, 1.0);
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
