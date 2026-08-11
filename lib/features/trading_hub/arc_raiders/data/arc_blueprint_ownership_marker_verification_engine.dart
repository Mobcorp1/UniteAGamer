import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_template_verification_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_canonical_grid.dart';

@immutable
class ArcBlueprintOwnershipMarkerDiagnostic {
  const ArcBlueprintOwnershipMarkerDiagnostic({
    required this.blueprintId,
    required this.blueprintName,
    required this.canonicalIndex,
    required this.captureId,
    required this.rowIndex,
    required this.columnIndex,
    required this.multiSignalEvidence,
    required this.templateSimilarity,
    required this.bookMarkerEvidence,
    required this.tickMarkerEvidence,
    required this.markerEvidence,
    required this.finalScore,
    required this.suppressed,
  });

  final String blueprintId;
  final String blueprintName;
  final int canonicalIndex;
  final String captureId;
  final int rowIndex;
  final int columnIndex;
  final double multiSignalEvidence;
  final double templateSimilarity;
  final double bookMarkerEvidence;
  final double tickMarkerEvidence;
  final double markerEvidence;
  final double finalScore;
  final bool suppressed;
}

@immutable
class ArcBlueprintOwnershipMarkerVerificationResult {
  const ArcBlueprintOwnershipMarkerVerificationResult({
    required this.samples,
    required this.diagnostics,
    required this.suppressedCandidateCount,
  });

  final List<ArcBlueprintPhotoOccupancySample> samples;
  final List<ArcBlueprintOwnershipMarkerDiagnostic> diagnostics;
  final int suppressedCandidateCount;
}

/// PASS 343 direct ownership-UI verifier.
///
/// The existing recogniser remains authoritative for finding visually occupied
/// cells. This verifier is suppression-only and asks a second, more direct
/// question for strong NEW-owned candidates:
///
///   Does the cell actually contain ARC Raiders' owned-card UI markers?
///
/// On the in-game Blueprint grid an owned card has two stable high-contrast
/// markers:
/// - a small white/open-book Blueprint emblem at the lower-left;
/// - a white completion tick at the upper-right.
///
/// Empty slots still contain blue/purple borders and background texture, which
/// can fool whole-cell colour/texture scoring. The marker verifier therefore
/// looks only at those two small regions. It never promotes ownership.
///
/// Glare safety:
/// If both marker regions are weak but the expected artwork template is an
/// exceptionally strong match, the candidate is preserved rather than
/// suppressed. This prevents a reflection or clipped corner from deleting a
/// genuine Blueprint.
class ArcBlueprintOwnershipMarkerVerificationEngine {
  const ArcBlueprintOwnershipMarkerVerificationEngine({
    this.ownedThreshold = 0.84,
    this.maximumSuppressedScore = 0.79,
    this.minimumBookMarkerEvidence = 0.22,
    this.minimumTickMarkerEvidence = 0.18,
    this.minimumCombinedMarkerEvidence = 0.20,
    this.minimumReliableSingleBookEvidence = 0.68,
    this.glareSafetyTemplateSimilarity = 0.78,
  });

  final double ownedThreshold;
  final double maximumSuppressedScore;
  final double minimumBookMarkerEvidence;
  final double minimumTickMarkerEvidence;
  final double minimumCombinedMarkerEvidence;
  final double minimumReliableSingleBookEvidence;
  final double glareSafetyTemplateSimilarity;

  ArcBlueprintOwnershipMarkerVerificationResult verify({
    required Uint8List topBytes,
    required Uint8List bottomBytes,
    required List<ArcBlueprintPhotoOccupancySample> samples,
    required List<ArcBlueprintTemplateVerificationSample> templateDiagnostics,
  }) {
    final decodedTop = img.decodeImage(topBytes);
    final decodedBottom = img.decodeImage(bottomBytes);
    if (decodedTop == null || decodedBottom == null) {
      return ArcBlueprintOwnershipMarkerVerificationResult(
        samples: List<ArcBlueprintPhotoOccupancySample>.unmodifiable(samples),
        diagnostics: const <ArcBlueprintOwnershipMarkerDiagnostic>[],
        suppressedCandidateCount: 0,
      );
    }

    final top = img.copyResize(
      decodedTop,
      width: ArcBlueprintCanonicalGrid.columns * 100,
      height: ArcBlueprintCanonicalGrid.topRows * 100,
      interpolation: img.Interpolation.cubic,
    );
    final bottom = img.copyResize(
      decodedBottom,
      width: ArcBlueprintCanonicalGrid.columns * 100,
      height: ArcBlueprintCanonicalGrid.bottomRows * 100,
      interpolation: img.Interpolation.cubic,
    );

    final templatesByIndex = <int, ArcBlueprintTemplateVerificationSample>{
      for (final diagnostic in templateDiagnostics)
        diagnostic.canonicalIndex: diagnostic,
    };

    final verified = <ArcBlueprintPhotoOccupancySample>[];
    final diagnostics = <ArcBlueprintOwnershipMarkerDiagnostic>[];
    var suppressedCount = 0;

    for (final sample in samples) {
      final canonicalIndex = ArcBlueprintCanonicalGrid.indexForGlobalCell(
        rowIndex: sample.rowIndex,
        columnIndex: sample.columnIndex,
      );
      final template = canonicalIndex == null
          ? null
          : templatesByIndex[canonicalIndex];

      if (canonicalIndex == null || template == null) {
        verified.add(sample);
        continue;
      }

      final source = sample.captureId == 'bottom' ? bottom : top;
      final localRow = sample.captureId == 'bottom'
          ? sample.rowIndex - ArcBlueprintCanonicalGrid.topRows
          : sample.rowIndex;

      if (localRow < 0 ||
          localRow >=
              (sample.captureId == 'bottom'
                  ? ArcBlueprintCanonicalGrid.bottomRows
                  : ArcBlueprintCanonicalGrid.topRows)) {
        verified.add(sample);
        continue;
      }

      final marker = _measureCellMarkers(
        source,
        rowIndex: localRow,
        columnIndex: sample.columnIndex,
      );

      final evidence = sample.occupancyScore.clamp(0.0, 1.0).toDouble();
      var finalScore = evidence;
      var suppressed = false;

      final markersAbsent =
          marker.bookEvidence < minimumBookMarkerEvidence &&
          marker.tickEvidence < minimumTickMarkerEvidence &&
          marker.combinedEvidence < minimumCombinedMarkerEvidence;
      final ambiguousBookOnly =
          marker.tickEvidence < minimumTickMarkerEvidence &&
          marker.bookEvidence >= minimumBookMarkerEvidence &&
          marker.bookEvidence < minimumReliableSingleBookEvidence;
      final markerEvidenceRejects = markersAbsent || ambiguousBookOnly;

      // Suppression-only. A weak cell is never promoted by marker detection.
      //
      // A visually "occupied" whole-cell candidate that has neither of the
      // game's owned-card UI markers is rejected unless expected artwork is an
      // exceptionally strong match. This is intentionally aimed at first-run
      // scans where no personal calibration anchors exist yet.
      if (evidence >= ownedThreshold &&
          markerEvidenceRejects &&
          template.templateSimilarity < glareSafetyTemplateSimilarity) {
        finalScore = math.min(finalScore, maximumSuppressedScore);
        suppressed = true;
        suppressedCount++;
      }

      final output = ArcBlueprintPhotoOccupancySample(
        captureId: sample.captureId,
        rowIndex: sample.rowIndex,
        columnIndex: sample.columnIndex,
        occupancyScore: finalScore.clamp(0.0, 1.0).toDouble(),
      );
      verified.add(output);

      diagnostics.add(
        ArcBlueprintOwnershipMarkerDiagnostic(
          blueprintId: template.blueprintId,
          blueprintName: template.blueprintName,
          canonicalIndex: canonicalIndex,
          captureId: sample.captureId,
          rowIndex: sample.rowIndex,
          columnIndex: sample.columnIndex,
          multiSignalEvidence: evidence,
          templateSimilarity: template.templateSimilarity,
          bookMarkerEvidence: marker.bookEvidence,
          tickMarkerEvidence: marker.tickEvidence,
          markerEvidence: marker.combinedEvidence,
          finalScore: finalScore,
          suppressed: suppressed,
        ),
      );

      if (kDebugMode && evidence >= ownedThreshold) {
        debugPrint(
          'ARC OWNERSHIP MARKER: '
          'expected=${template.blueprintName} '
          'index=$canonicalIndex '
          'cell=${sample.rowIndex + 1}:${sample.columnIndex + 1} '
          'book=${marker.bookEvidence.toStringAsFixed(3)} '
          'tick=${marker.tickEvidence.toStringAsFixed(3)} '
          'marker=${marker.combinedEvidence.toStringAsFixed(3)} '
          'template=${template.templateSimilarity.toStringAsFixed(3)} '
          'multiSignal=${evidence.toStringAsFixed(3)} '
          'final=${finalScore.toStringAsFixed(3)} '
          'suppressed=$suppressed',
        );
      }
    }

    if (kDebugMode) {
      debugPrint(
        'ARC OWNERSHIP MARKER: summary '
        'candidates=${diagnostics.where((d) => d.multiSignalEvidence >= ownedThreshold).length} '
        'suppressed=$suppressedCount',
      );
    }

    return ArcBlueprintOwnershipMarkerVerificationResult(
      samples: List<ArcBlueprintPhotoOccupancySample>.unmodifiable(verified),
      diagnostics: List<ArcBlueprintOwnershipMarkerDiagnostic>.unmodifiable(
        diagnostics,
      ),
      suppressedCandidateCount: suppressedCount,
    );
  }

  static _OwnershipMarkerEvidence _measureCellMarkers(
    img.Image image, {
    required int rowIndex,
    required int columnIndex,
  }) {
    final cellWidth = image.width / ArcBlueprintCanonicalGrid.columns;
    final rowCount = math.max(1, image.height ~/ 100);
    final cellHeight = image.height / rowCount;

    // PASS 344: sample each ownership glyph with a small family of shifted
    // windows. Real-device top captures showed the final two columns drifting
    // horizontally enough for the fixed PASS 343 ROI to miss both glyphs.
    // Taking the strongest tightly bounded window keeps the measurement inside
    // the current cell while tolerating perspective/crop residuals.
    final book = _measureShiftTolerantMarker(
      image,
      cellLeft: columnIndex * cellWidth,
      cellTop: rowIndex * cellHeight,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      baseLeft: 0.055,
      baseTop: 0.665,
      baseRight: 0.300,
      baseBottom: 0.945,
    );

    final tick = _measureShiftTolerantMarker(
      image,
      cellLeft: columnIndex * cellWidth,
      cellTop: rowIndex * cellHeight,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      baseLeft: 0.695,
      baseTop: 0.045,
      baseRight: 0.955,
      baseBottom: 0.305,
    );

    final combined = ((book * 0.62) + (tick * 0.38)).clamp(0.0, 1.0);
    return _OwnershipMarkerEvidence(
      bookEvidence: book,
      tickEvidence: tick,
      combinedEvidence: combined.toDouble(),
    );
  }

  static double _measureShiftTolerantMarker(
    img.Image image, {
    required double cellLeft,
    required double cellTop,
    required double cellWidth,
    required double cellHeight,
    required double baseLeft,
    required double baseTop,
    required double baseRight,
    required double baseBottom,
  }) {
    const shifts = <double>[-0.10, -0.05, 0.0, 0.05, 0.10];
    var strongest = 0.0;
    for (final horizontalShift in shifts) {
      final left = (baseLeft + horizontalShift).clamp(0.015, 0.965);
      final right = (baseRight + horizontalShift).clamp(0.035, 0.985);
      if (right <= left) continue;
      strongest = math.max(
        strongest,
        _measureWhiteMarkerRegion(
          image,
          left: cellLeft + cellWidth * left,
          top: cellTop + cellHeight * baseTop,
          right: cellLeft + cellWidth * right,
          bottom: cellTop + cellHeight * baseBottom,
        ),
      );
    }
    return strongest;
  }

  static double _measureWhiteMarkerRegion(
    img.Image image, {
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) {
    final x0 = left.round().clamp(0, image.width - 2);
    final y0 = top.round().clamp(0, image.height - 2);
    final x1 = right.round().clamp(x0 + 1, image.width - 1);
    final y1 = bottom.round().clamp(y0 + 1, image.height - 1);

    var brightNeutral = 0;
    var veryBrightNeutral = 0;
    var highContrastEdges = 0;
    var count = 0;

    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        final pixel = image.getPixelSafe(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        final maxC = math.max(r, math.max(g, b));
        final minC = math.min(r, math.min(g, b));
        final luma = (r * 0.2126) + (g * 0.7152) + (b * 0.0722);
        final chroma = maxC - minC;

        if (luma >= 145 && chroma <= 72) {
          brightNeutral++;
        }
        if (luma >= 195 && chroma <= 58) {
          veryBrightNeutral++;
        }

        if (x < x1 && y < y1) {
          final rightPixel = image.getPixelSafe(x + 1, y);
          final downPixel = image.getPixelSafe(x, y + 1);
          final dx = (luma - _luma(rightPixel)).abs();
          final dy = (luma - _luma(downPixel)).abs();
          if ((dx >= 70 || dy >= 70) && luma >= 120) {
            highContrastEdges++;
          }
        }
        count++;
      }
    }

    if (count == 0) return 0;

    final brightCoverage = brightNeutral / count;
    final veryBrightCoverage = veryBrightNeutral / count;
    final edgeCoverage = highContrastEdges / count;

    // Real UI glyphs occupy only a small portion of these ROIs. Convert a
    // concentrated 1-8% white/high-contrast footprint into a stable 0..1 vote.
    final brightVote = ((brightCoverage - 0.008) / 0.070).clamp(0.0, 1.0);
    final veryBrightVote = (veryBrightCoverage / 0.045).clamp(0.0, 1.0);
    final edgeVote = (edgeCoverage / 0.055).clamp(0.0, 1.0);

    return ((brightVote * 0.52) + (veryBrightVote * 0.30) + (edgeVote * 0.18))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  static double _luma(img.Pixel pixel) =>
      (pixel.r.toDouble() * 0.2126) +
      (pixel.g.toDouble() * 0.7152) +
      (pixel.b.toDouble() * 0.0722);
}

@immutable
class _OwnershipMarkerEvidence {
  const _OwnershipMarkerEvidence({
    required this.bookEvidence,
    required this.tickEvidence,
    required this.combinedEvidence,
  });

  final double bookEvidence;
  final double tickEvidence;
  final double combinedEvidence;
}
