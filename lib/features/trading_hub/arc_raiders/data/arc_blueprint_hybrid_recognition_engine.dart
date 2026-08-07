import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_cell_analyzer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_recognition_diagnostics.dart';

@immutable
class ArcBlueprintHybridRecognitionResult {
  const ArcBlueprintHybridRecognitionResult({
    required this.samples,
    required this.diagnostics,
    required this.captureConfidence,
    required this.error,
  });

  final List<ArcBlueprintPhotoOccupancySample> samples;
  final List<ArcBlueprintCellDiagnostic> diagnostics;
  final double captureConfidence;
  final String error;

  bool get succeeded => error.isEmpty && samples.isNotEmpty;
}

class ArcBlueprintHybridRecognitionEngine {
  const ArcBlueprintHybridRecognitionEngine({this.columns = 10, this.rows = 5});

  final int columns;
  final int rows;

  ArcBlueprintHybridRecognitionResult analyze({
    required Uint8List bytes,
    required String captureId,
  }) {
    final decoded = _decode(bytes);
    if (decoded == null) {
      return const ArcBlueprintHybridRecognitionResult(
        samples: <ArcBlueprintPhotoOccupancySample>[],
        diagnostics: <ArcBlueprintCellDiagnostic>[],
        captureConfidence: 0,
        error: 'The selected image could not be decoded.',
      );
    }
    if (decoded.width < columns * 20 || decoded.height < rows * 20) {
      return const ArcBlueprintHybridRecognitionResult(
        samples: <ArcBlueprintPhotoOccupancySample>[],
        diagnostics: <ArcBlueprintCellDiagnostic>[],
        captureConfidence: 0,
        error: 'The image is too small to analyse the Blueprint grid.',
      );
    }

    final normalized = decoded.width == 1000 && decoded.height == 500
        ? decoded
        : img.copyResize(
            decoded,
            width: 1000,
            height: 500,
            interpolation: img.Interpolation.cubic,
          );

    final primary = ArcBlueprintCellAnalyzer(
      columns: columns,
      rows: rows,
    ).analyze(normalized);

    final samples = <ArcBlueprintPhotoOccupancySample>[];
    final diagnostics = <ArcBlueprintCellDiagnostic>[];

    for (var index = 0; index < primary.length; index++) {
      final row = index ~/ columns;
      final column = index % columns;
      final base = primary[index];

      var score = base.occupancyScore;
      var confidence = base.confidence;
      var retryCount = 0;

      // The proven primary analyzer remains authoritative for decisive cells.
      // Only uncertain cells are retried with targeted expanded/shifted crops.
      if (score > 0.28 && score < 0.72) {
        final retry = _retryUncertainCell(normalized, row, column);
        retryCount = retry.attempts;

        if (retry.decisive && retry.confidence >= 0.66) {
          score = retry.score;
          confidence = math.max(confidence, retry.confidence);
        }
      }

      // A flat, low-information cell can never become owned through fallback.
      if (base.texture < 0.09 &&
          base.edgeDensity < 0.09 &&
          base.saturation < 0.10 &&
          base.foregroundCoverage < 0.08 &&
          base.luminanceRange < 0.12) {
        score = math.min(score, 0.16);
        confidence = math.max(confidence, 0.88);
      }

      samples.add(
        ArcBlueprintPhotoOccupancySample(
          captureId: captureId,
          rowIndex: row,
          columnIndex: column,
          occupancyScore: score.clamp(0.0, 1.0).toDouble(),
        ),
      );
      diagnostics.add(
        ArcBlueprintCellDiagnostic(
          rowIndex: row,
          columnIndex: column,
          occupancyScore: score,
          confidence: confidence,
          textureVote: base.texture,
          edgeVote: base.edgeDensity,
          colourVote: base.saturation,
          foregroundVote: base.foregroundCoverage,
          silhouetteVote: base.luminanceRange,
          retryCount: retryCount,
        ),
      );
    }

    final captureConfidence = diagnostics.isEmpty
        ? 0.0
        : diagnostics.map((item) => item.confidence).reduce((a, b) => a + b) /
              diagnostics.length;

    return ArcBlueprintHybridRecognitionResult(
      samples: List<ArcBlueprintPhotoOccupancySample>.unmodifiable(samples),
      diagnostics: List<ArcBlueprintCellDiagnostic>.unmodifiable(diagnostics),
      captureConfidence: captureConfidence,
      error: '',
    );
  }

  _RetryResult _retryUncertainCell(img.Image image, int row, int column) {
    final cellWidth = image.width / columns;
    final cellHeight = image.height / rows;
    final shifts = <double>[0, -0.06, 0.06];
    final insets = <double>[0.02, 0.10, 0.18];
    final scores = <double>[];

    for (final shift in shifts) {
      for (final inset in insets) {
        scores.add(
          _scoreWindow(image, row, column, cellWidth, cellHeight, inset, shift),
        );
      }
    }

    scores.sort();
    final median = scores[scores.length ~/ 2];
    final high = scores.last;
    final low = scores.first;
    final consensus = ((median * 0.78) + (high * 0.22)).clamp(0.0, 1.0);
    final agreement = (1 - ((high - low) / 0.70)).clamp(0.0, 1.0);
    final distance = ((consensus - 0.5).abs() * 2).clamp(0.0, 1.0);
    final confidence = ((agreement * 0.45) + (distance * 0.55)).clamp(0.0, 1.0);

    return _RetryResult(
      score: consensus,
      confidence: confidence,
      decisive: consensus <= 0.28 || consensus >= 0.72,
      attempts: scores.length,
    );
  }

  double _scoreWindow(
    img.Image image,
    int row,
    int column,
    double cellWidth,
    double cellHeight,
    double inset,
    double horizontalShift,
  ) {
    final originX = column * cellWidth;
    final originY = row * cellHeight;
    final shiftPixels = cellWidth * horizontalShift;

    final left = (originX + (cellWidth * inset) + shiftPixels).round().clamp(
      0,
      image.width - 2,
    );
    final right = (originX + (cellWidth * (1 - inset)) + shiftPixels)
        .round()
        .clamp(left + 1, image.width - 1);
    final top = (originY + (cellHeight * inset)).round().clamp(
      0,
      image.height - 2,
    );
    final bottom = (originY + (cellHeight * (1 - inset))).round().clamp(
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

    final lumas = <double>[];
    var saturationSum = 0.0;
    var edgeSum = 0.0;
    var foreground = 0;
    var count = 0;

    for (var y = top; y < bottom; y += stride) {
      for (var x = left; x < right; x += stride) {
        final pixel = image.getPixelSafe(x, y);
        final luma = _luma(pixel);
        final saturation = _saturation(pixel);
        lumas.add(luma);
        saturationSum += saturation;

        final nx = math.min(right - 1, x + stride);
        final ny = math.min(bottom - 1, y + stride);
        final dx = (luma - _luma(image.getPixelSafe(nx, y))).abs();
        final dy = (luma - _luma(image.getPixelSafe(x, ny))).abs();
        edgeSum += dx + dy;

        if ((saturation >= 0.15 && luma >= 20) || dx >= 22 || dy >= 22) {
          foreground++;
        }
        count++;
      }
    }

    if (count == 0 || lumas.isEmpty) return 0;
    lumas.sort();
    final mean = lumas.reduce((a, b) => a + b) / count;
    var variance = 0.0;
    for (final value in lumas) {
      final delta = value - mean;
      variance += delta * delta;
    }

    final texture = (math.sqrt(variance / count) / 70).clamp(0.0, 1.0);
    final edges = ((edgeSum / (count * 2)) / 68).clamp(0.0, 1.0);
    final saturation = (saturationSum / count).clamp(0.0, 1.0);
    final coverage = (foreground / count).clamp(0.0, 1.0);
    final range = ((_percentile(lumas, 0.90) - _percentile(lumas, 0.10)) / 145)
        .clamp(0.0, 1.0);

    if (texture < 0.09 &&
        edges < 0.09 &&
        saturation < 0.10 &&
        coverage < 0.08 &&
        range < 0.12) {
      return 0.12;
    }

    final combined =
        ((texture * 0.27) +
                (edges * 0.26) +
                (saturation * 0.17) +
                (coverage * 0.22) +
                (range * 0.08))
            .clamp(0.0, 1.0);
    return 1 / (1 + math.exp(-((combined - 0.245) * 11.2)));
  }

  img.Image? _decode(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      return decoded == null ? null : img.bakeOrientation(decoded);
    } on Object {
      return null;
    }
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
    return sorted[position.clamp(0, sorted.length - 1)];
  }
}

@immutable
class _RetryResult {
  const _RetryResult({
    required this.score,
    required this.confidence,
    required this.decisive,
    required this.attempts,
  });

  final double score;
  final double confidence;
  final bool decisive;
  final int attempts;
}
