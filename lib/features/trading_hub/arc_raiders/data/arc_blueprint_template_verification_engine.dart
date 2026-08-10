import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_canonical_grid.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';

class ArcBlueprintTemplateVerificationSample {
  const ArcBlueprintTemplateVerificationSample({
    required this.blueprintId,
    required this.blueprintName,
    required this.canonicalIndex,
    required this.rowIndex,
    required this.columnIndex,
    required this.captureId,
    required this.templateSimilarity,
    required this.multiSignalEvidence,
    required this.finalScore,
    required this.templateAvailable,
    required this.suppressed,
  });

  final String blueprintId;
  final String blueprintName;
  final int canonicalIndex;
  final int rowIndex;
  final int columnIndex;
  final String captureId;
  final double templateSimilarity;
  final double multiSignalEvidence;
  final double finalScore;
  final bool templateAvailable;
  final bool suppressed;
}

class ArcBlueprintTemplateVerificationResult {
  const ArcBlueprintTemplateVerificationResult({
    required this.samples,
    required this.diagnostics,
    required this.suppressedCandidateCount,
  });

  final List<ArcBlueprintPhotoOccupancySample> samples;
  final List<ArcBlueprintTemplateVerificationSample> diagnostics;
  final int suppressedCandidateCount;
}

class ArcBlueprintTemplateVerificationEngine {
  const ArcBlueprintTemplateVerificationEngine({
    this.ownedThreshold = 0.84,
    this.minimumTemplateSimilarity = 0.34,
    this.strongTemplateSimilarity = 0.58,
    this.maximumSuppressedScore = 0.79,
  });

  final double ownedThreshold;
  final double minimumTemplateSimilarity;
  final double strongTemplateSimilarity;
  final double maximumSuppressedScore;

  Future<ArcBlueprintTemplateVerificationResult> verify({
    required Uint8List topBytes,
    required Uint8List bottomBytes,
    required List<ArcBlueprintPhotoOccupancySample> samples,
  }) async {
    final top = img.decodeImage(topBytes);
    final bottom = img.decodeImage(bottomBytes);
    if (top == null || bottom == null) {
      return ArcBlueprintTemplateVerificationResult(
        samples: List<ArcBlueprintPhotoOccupancySample>.unmodifiable(samples),
        diagnostics: const <ArcBlueprintTemplateVerificationSample>[],
        suppressedCandidateCount: 0,
      );
    }

    final normalizedTop = img.copyResize(
      top,
      width: ArcBlueprintCanonicalGrid.columns * 100,
      height: ArcBlueprintCanonicalGrid.topRows * 100,
      interpolation: img.Interpolation.cubic,
    );
    final normalizedBottom = img.copyResize(
      bottom,
      width: ArcBlueprintCanonicalGrid.columns * 100,
      height: ArcBlueprintCanonicalGrid.bottomRows * 100,
      interpolation: img.Interpolation.cubic,
    );

    final templates = <String, _TemplateSignature>{};
    for (final blueprint in ArcBlueprintSeedData.blueprints) {
      final path = blueprint.imageAssetPath;
      if (path == null || path.trim().isEmpty) continue;
      try {
        final data = await rootBundle.load(path);
        final decoded = img.decodeImage(data.buffer.asUint8List());
        if (decoded != null) {
          templates[blueprint.id] = _signature(decoded);
        }
      } catch (_) {
        // Missing template assets must never block scanning. The existing
        // multi-signal recogniser remains authoritative for those cells.
      }
    }

    final diagnostics = <ArcBlueprintTemplateVerificationSample>[];
    final verified = <ArcBlueprintPhotoOccupancySample>[];
    var suppressed = 0;

    for (final sample in samples) {
      final canonicalIndex = ArcBlueprintCanonicalGrid.indexForGlobalCell(
        rowIndex: sample.rowIndex,
        columnIndex: sample.columnIndex,
      );
      if (canonicalIndex == null ||
          canonicalIndex < 0 ||
          canonicalIndex >= ArcBlueprintSeedData.blueprints.length) {
        verified.add(sample);
        continue;
      }

      final blueprint = ArcBlueprintSeedData.blueprints[canonicalIndex];
      final template = templates[blueprint.id];
      final source = sample.captureId == 'bottom'
          ? normalizedBottom
          : normalizedTop;
      final localRow = sample.captureId == 'bottom'
          ? sample.rowIndex - ArcBlueprintCanonicalGrid.topRows
          : sample.rowIndex;
      final capturedSignature = _cellSignature(
        source,
        rowIndex: localRow,
        columnIndex: sample.columnIndex,
      );

      final similarity = template == null
          ? 0.0
          : _similarity(capturedSignature, template);
      final evidence = sample.occupancyScore.clamp(0.0, 1.0).toDouble();
      var finalScore = evidence;
      var wasSuppressed = false;

      // PASS 340 is verification, not a replacement classifier. It cannot
      // create ownership from a weak cell. It only suppresses candidates the
      // existing recogniser considered owned when the artwork expected at
      // this exact canonical position is a poor match.
      if (template != null && evidence >= ownedThreshold) {
        if (similarity < minimumTemplateSimilarity) {
          finalScore = math.min(finalScore, maximumSuppressedScore);
          wasSuppressed = true;
        } else if (similarity < strongTemplateSimilarity) {
          final blended = (evidence * 0.82) + (similarity * 0.18);
          if (blended < ownedThreshold) {
            finalScore = math.min(blended, maximumSuppressedScore);
            wasSuppressed = true;
          }
        }
      }

      if (wasSuppressed) suppressed++;
      verified.add(
        ArcBlueprintPhotoOccupancySample(
          captureId: sample.captureId,
          rowIndex: sample.rowIndex,
          columnIndex: sample.columnIndex,
          occupancyScore: finalScore.clamp(0.0, 1.0).toDouble(),
        ),
      );
      diagnostics.add(
        ArcBlueprintTemplateVerificationSample(
          blueprintId: blueprint.id,
          blueprintName: blueprint.name,
          canonicalIndex: canonicalIndex,
          rowIndex: sample.rowIndex,
          columnIndex: sample.columnIndex,
          captureId: sample.captureId,
          templateSimilarity: similarity,
          multiSignalEvidence: evidence,
          finalScore: finalScore,
          templateAvailable: template != null,
          suppressed: wasSuppressed,
        ),
      );
    }

    return ArcBlueprintTemplateVerificationResult(
      samples: List<ArcBlueprintPhotoOccupancySample>.unmodifiable(verified),
      diagnostics: List<ArcBlueprintTemplateVerificationSample>.unmodifiable(
        diagnostics,
      ),
      suppressedCandidateCount: suppressed,
    );
  }

  static _TemplateSignature _cellSignature(
    img.Image image, {
    required int rowIndex,
    required int columnIndex,
  }) {
    final cellWidth = image.width / ArcBlueprintCanonicalGrid.columns;
    final rows = image.height ~/ 100;
    final cellHeight = image.height / math.max(1, rows);
    final left = (columnIndex * cellWidth + cellWidth * 0.08).round().clamp(
      0,
      image.width - 2,
    );
    final right = (columnIndex * cellWidth + cellWidth * 0.92).round().clamp(
      left + 1,
      image.width - 1,
    );
    final top = (rowIndex * cellHeight + cellHeight * 0.08).round().clamp(
      0,
      image.height - 2,
    );
    final bottom = (rowIndex * cellHeight + cellHeight * 0.92).round().clamp(
      top + 1,
      image.height - 1,
    );
    final crop = img.copyCrop(
      image,
      x: left,
      y: top,
      width: right - left,
      height: bottom - top,
    );
    return _signature(crop);
  }

  static _TemplateSignature _signature(img.Image source) {
    final small = img.copyResize(
      source,
      width: 24,
      height: 24,
      interpolation: img.Interpolation.average,
    );

    final luminance = <double>[];
    final saturation = <double>[];
    final gradient = <double>[];
    var meanLuma = 0.0;
    var meanSaturation = 0.0;

    for (var y = 0; y < small.height; y++) {
      for (var x = 0; x < small.width; x++) {
        final p = small.getPixel(x, y);
        final r = p.r.toDouble() / 255.0;
        final g = p.g.toDouble() / 255.0;
        final b = p.b.toDouble() / 255.0;
        final l = (0.2126 * r) + (0.7152 * g) + (0.0722 * b);
        final maxC = math.max(r, math.max(g, b));
        final minC = math.min(r, math.min(g, b));
        final s = maxC <= 0 ? 0.0 : (maxC - minC) / maxC;
        luminance.add(l);
        saturation.add(s);
        meanLuma += l;
        meanSaturation += s;
      }
    }
    meanLuma /= luminance.length;
    meanSaturation /= saturation.length;

    for (var y = 0; y < small.height; y++) {
      for (var x = 0; x < small.width; x++) {
        final i = y * small.width + x;
        final rightX = x + 1 < small.width ? x + 1 : small.width - 1;
        final downY = y + 1 < small.height ? y + 1 : small.height - 1;
        final right = y * small.width + rightX;
        final down = downY * small.width + x;
        final horizontalDelta = (luminance[i] - luminance[right])
            .abs()
            .toDouble();
        final verticalDelta = (luminance[i] - luminance[down]).abs().toDouble();
        final gradientValue = (horizontalDelta + verticalDelta) / 2.0;
        gradient.add(gradientValue);
      }
    }

    final centeredLuma = luminance
        .map((v) => v - meanLuma)
        .toList(growable: false);
    final centeredSat = saturation
        .map((v) => v - meanSaturation)
        .toList(growable: false);
    return _TemplateSignature(
      luminance: centeredLuma,
      saturation: centeredSat,
      gradient: gradient,
    );
  }

  static double _similarity(_TemplateSignature a, _TemplateSignature b) {
    final luma = _cosine(a.luminance, b.luminance);
    final saturation = _cosine(a.saturation, b.saturation);
    final gradient = _cosine(a.gradient, b.gradient);
    return ((luma * 0.48) + (gradient * 0.34) + (saturation * 0.18))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  static double _cosine(List<double> a, List<double> b) {
    final count = math.min(a.length, b.length);
    if (count == 0) return 0;
    var dot = 0.0;
    var aa = 0.0;
    var bb = 0.0;
    for (var i = 0; i < count; i++) {
      dot += a[i] * b[i];
      aa += a[i] * a[i];
      bb += b[i] * b[i];
    }
    if (aa <= 0.000001 || bb <= 0.000001) return 0;
    final raw = dot / math.sqrt(aa * bb);
    return ((raw + 1) / 2).clamp(0.0, 1.0).toDouble();
  }
}

class _TemplateSignature {
  const _TemplateSignature({
    required this.luminance,
    required this.saturation,
    required this.gradient,
  });

  final List<double> luminance;
  final List<double> saturation;
  final List<double> gradient;
}
