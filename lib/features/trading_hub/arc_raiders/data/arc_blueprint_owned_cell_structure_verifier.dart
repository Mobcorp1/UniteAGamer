import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_template_verification_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_canonical_grid.dart';

@immutable
class ArcBlueprintOwnedCellStructureDiagnostic {
  const ArcBlueprintOwnedCellStructureDiagnostic({
    required this.rowIndex,
    required this.columnIndex,
    required this.captureId,
    required this.bluePanelCoverage,
    required this.footerDarkCoverage,
    required this.footerContrast,
    required this.bookShapeEvidence,
    required this.tickShapeEvidence,
    required this.templateSimilarity,
    required this.suppressed,
    this.classification = 'uncertain',
    this.overlapCorroborated = false,
  });

  final int rowIndex;
  final int columnIndex;
  final String captureId;
  final double bluePanelCoverage;
  final double footerDarkCoverage;
  final double footerContrast;
  final double bookShapeEvidence;
  final double tickShapeEvidence;
  final double templateSimilarity;
  final bool suppressed;
  final String classification;
  final bool overlapCorroborated;
}

@immutable
class ArcBlueprintOwnedCellStructureResult {
  const ArcBlueprintOwnedCellStructureResult({
    required this.samples,
    required this.diagnostics,
    required this.suppressedCandidateCount,
  });

  final List<ArcBlueprintPhotoOccupancySample> samples;
  final List<ArcBlueprintOwnedCellStructureDiagnostic> diagnostics;
  final int suppressedCandidateCount;
}

class ArcBlueprintOwnedCellStructureVerifier {
  const ArcBlueprintOwnedCellStructureVerifier({
    this.ownedThreshold = 0.84,
    this.missingThreshold = 0.22,
    this.maximumSuppressedScore = 0.79,
    this.confidentEmptyScore = 0.18,
    this.minimumBluePanelCoverage = 0.50,
    this.minimumFooterDarkCoverage = 0.48,
    this.minimumFooterContrast = 0.08,
    this.minimumMarkerShapeEvidence = 0.18,
    this.minimumArtworkSimilarity = 0.54,
  });

  final double ownedThreshold;
  final double missingThreshold;
  final double maximumSuppressedScore;
  final double confidentEmptyScore;

  /// Six independent mandatory ownership floors.
  ///
  /// These are deliberately presence floors, not six 80% thresholds. The real
  /// Sony diagnostics showed genuine owned cards with different raw scales:
  /// e.g. Anvil blue=0.668, footer=0.595, contrast=0.165, book=1.000,
  /// tick=0.636, artwork/template=0.643. Requiring every raw value to be 0.80
  /// would therefore reject real cards.
  final double minimumBluePanelCoverage;
  final double minimumFooterDarkCoverage;
  final double minimumFooterContrast;
  final double minimumMarkerShapeEvidence;
  final double minimumArtworkSimilarity;

  /// Final six-gate empty/owned/uncertain classifier.
  ///
  /// A cell can be auto-owned only when ALL SIX independent signals are
  /// present in the SAME photograph:
  ///  1. blue/cool Blueprint panel,
  ///  2. dark lower footer,
  ///  3. body-to-footer contrast break,
  ///  4. lower-left Blueprint/book marker,
  ///  5. upper-right completion tick,
  ///  6. canonical artwork/template similarity.
  ///
  /// There is intentionally NO combined ownership threshold and NO rescue
  /// route. Five-out-of-six is uncertain, never owned. For the row-5 overlap,
  /// the top and bottom photographs are evaluated independently; signals are
  /// never stitched together across photographs.
  ArcBlueprintOwnedCellStructureResult verify({
    required Uint8List topBytes,
    required Uint8List bottomBytes,
    Uint8List? bottomFiveRowBytes,
    required List<ArcBlueprintPhotoOccupancySample> samples,
    required List<ArcBlueprintTemplateVerificationSample> templateDiagnostics,
  }) {
    final decodedTop = img.decodeImage(topBytes);
    final decodedBottom = img.decodeImage(bottomBytes);
    if (decodedTop == null || decodedBottom == null) {
      return ArcBlueprintOwnedCellStructureResult(
        samples: List<ArcBlueprintPhotoOccupancySample>.unmodifiable(samples),
        diagnostics: const <ArcBlueprintOwnedCellStructureDiagnostic>[],
        suppressedCandidateCount: 0,
      );
    }

    final top = img.copyResize(
      img.bakeOrientation(decodedTop),
      width: ArcBlueprintCanonicalGrid.columns * 100,
      height: ArcBlueprintCanonicalGrid.topRows * 100,
      interpolation: img.Interpolation.cubic,
    );
    final bottom = img.copyResize(
      img.bakeOrientation(decodedBottom),
      width: ArcBlueprintCanonicalGrid.columns * 100,
      height: ArcBlueprintCanonicalGrid.bottomRows * 100,
      interpolation: img.Interpolation.cubic,
    );

    img.Image? bottomFive;
    if (bottomFiveRowBytes != null) {
      final decodedBottomFive = img.decodeImage(bottomFiveRowBytes);
      if (decodedBottomFive != null) {
        bottomFive = img.copyResize(
          img.bakeOrientation(decodedBottomFive),
          width: ArcBlueprintCanonicalGrid.columns * 100,
          height: ArcBlueprintCanonicalGrid.topRows * 100,
          interpolation: img.Interpolation.cubic,
        );
      }
    }

    final templateByIndex = <int, ArcBlueprintTemplateVerificationSample>{
      for (final item in templateDiagnostics) item.canonicalIndex: item,
    };

    final verified = <ArcBlueprintPhotoOccupancySample>[];
    final diagnostics = <ArcBlueprintOwnedCellStructureDiagnostic>[];
    var suppressedCount = 0;

    for (final sample in samples) {
      final canonicalIndex = ArcBlueprintCanonicalGrid.indexForGlobalCell(
        rowIndex: sample.rowIndex,
        columnIndex: sample.columnIndex,
      );
      if (canonicalIndex == null) {
        verified.add(sample);
        continue;
      }

      final source = sample.captureId == 'bottom' ? bottom : top;
      final localRow = sample.captureId == 'bottom'
          ? sample.rowIndex - ArcBlueprintCanonicalGrid.topRows
          : sample.rowIndex;
      final rowCount = sample.captureId == 'bottom'
          ? ArcBlueprintCanonicalGrid.bottomRows
          : ArcBlueprintCanonicalGrid.topRows;

      if (localRow < 0 || localRow >= rowCount) {
        verified.add(sample);
        continue;
      }

      final primaryStructure = _measureCell(
        source,
        rowIndex: localRow,
        columnIndex: sample.columnIndex,
        rows: rowCount,
      );

      _CellStructure? overlapStructure;
      if (sample.captureId == 'top' &&
          sample.rowIndex == ArcBlueprintCanonicalGrid.topRows - 1 &&
          bottomFive != null) {
        overlapStructure = _measureCell(
          bottomFive,
          rowIndex: 0,
          columnIndex: sample.columnIndex,
          rows: ArcBlueprintCanonicalGrid.topRows,
        );
      }

      final template = templateByIndex[canonicalIndex];
      final templateSimilarity = template?.templateSimilarity ?? 0.0;

      // Keep the recogniser's original evidence only for diagnostics/output
      // banding. It is NOT an ownership gate. Ownership is decided solely by
      // the six mandatory structural/artwork checks below.
      final rawProposalEvidence = math.max(
        sample.occupancyScore.clamp(0.0, 1.0).toDouble(),
        (template?.multiSignalEvidence ?? 0.0).clamp(0.0, 1.0).toDouble(),
      );

      final primaryGate = _evaluateRequiredSignals(
        primaryStructure,
        artworkSimilarity: templateSimilarity,
      );
      final overlapGate = overlapStructure == null
          ? null
          : _evaluateRequiredSignals(
              overlapStructure,
              artworkSimilarity: templateSimilarity,
            );

      // Row 5 is photographed twice, but each photograph must independently
      // prove all six signals. Never max-fuse book/tick/footer/etc. from two
      // different photos into a synthetic "owned" cell.
      final confidentlyOwned =
          primaryGate.allPassed || (overlapGate?.allPassed ?? false);

      final bestPassedSignalCount = math.max(
        primaryGate.passedCount,
        overlapGate?.passedCount ?? 0,
      );

      // 0-2 of six signals is confidently empty. 3-5 is deliberately
      // uncertain: it cannot auto-add and it cannot remove existing ownership.
      final confidentlyEmpty =
          !confidentlyOwned &&
          (rawProposalEvidence <= missingThreshold ||
              bestPassedSignalCount <= 2);

      final String classification;
      final double finalScore;
      if (confidentlyOwned) {
        classification = 'owned';
        finalScore = math.max(rawProposalEvidence, ownedThreshold + 0.01);
      } else if (confidentlyEmpty) {
        classification = 'empty';
        finalScore = math.min(rawProposalEvidence, confidentEmptyScore);
      } else {
        classification = 'uncertain';
        finalScore = math.min(rawProposalEvidence, maximumSuppressedScore);
      }

      final suppressed =
          classification != 'owned' && rawProposalEvidence >= ownedThreshold;
      if (suppressed) suppressedCount++;

      final overlapCorroborated =
          overlapGate != null && overlapGate.allPassed;
      final diagnosticStructure =
          overlapCorroborated && !primaryGate.allPassed
          ? overlapStructure!
          : primaryStructure;

      verified.add(
        ArcBlueprintPhotoOccupancySample(
          captureId: sample.captureId,
          rowIndex: sample.rowIndex,
          columnIndex: sample.columnIndex,
          occupancyScore: finalScore.clamp(0.0, 1.0).toDouble(),
        ),
      );

      diagnostics.add(
        ArcBlueprintOwnedCellStructureDiagnostic(
          rowIndex: sample.rowIndex,
          columnIndex: sample.columnIndex,
          captureId: sample.captureId,
          bluePanelCoverage: diagnosticStructure.bluePanelCoverage,
          footerDarkCoverage: diagnosticStructure.footerDarkCoverage,
          footerContrast: diagnosticStructure.footerContrast,
          bookShapeEvidence: diagnosticStructure.bookShapeEvidence,
          tickShapeEvidence: diagnosticStructure.tickShapeEvidence,
          templateSimilarity: templateSimilarity,
          suppressed: suppressed,
          classification: classification,
          overlapCorroborated: overlapCorroborated,
        ),
      );

      if (kDebugMode &&
          (rawProposalEvidence >= ownedThreshold ||
              classification == 'owned' ||
              overlapCorroborated)) {
        debugPrint(
          'ARC OWNED STRUCTURE: '
          '${sample.captureId} '
          'R${sample.rowIndex + 1}C${sample.columnIndex + 1} '
          'blue=${primaryStructure.bluePanelCoverage.toStringAsFixed(3)} '
          'footer=${primaryStructure.footerDarkCoverage.toStringAsFixed(3)} '
          'contrast=${primaryStructure.footerContrast.toStringAsFixed(3)} '
          'bookShape=${primaryStructure.bookShapeEvidence.toStringAsFixed(3)} '
          'tickShape=${primaryStructure.tickShapeEvidence.toStringAsFixed(3)} '
          'artwork=${templateSimilarity.toStringAsFixed(3)} '
          'signals=${primaryGate.passedCount}/6 '
          'failed=${primaryGate.failedSignals.join(",")} '
          'overlapSignals=${overlapGate?.passedCount ?? 0}/6 '
          'overlapFailed=${overlapGate?.failedSignals.join(",") ?? "-"} '
          'raw=${rawProposalEvidence.toStringAsFixed(3)} '
          'classification=$classification '
          'overlapOwned=$overlapCorroborated '
          'suppressed=$suppressed',
        );
      }
    }

    if (kDebugMode) {
      final owned = diagnostics
          .where((item) => item.classification == 'owned')
          .length;
      final empty = diagnostics
          .where((item) => item.classification == 'empty')
          .length;
      final uncertain = diagnostics.length - owned - empty;
      debugPrint(
        'ARC OWNED STRUCTURE: summary '
        'owned=$owned empty=$empty uncertain=$uncertain '
        'suppressed=$suppressedCount',
      );
    }

    return ArcBlueprintOwnedCellStructureResult(
      samples: List<ArcBlueprintPhotoOccupancySample>.unmodifiable(verified),
      diagnostics: List<ArcBlueprintOwnedCellStructureDiagnostic>.unmodifiable(
        diagnostics,
      ),
      suppressedCandidateCount: suppressedCount,
    );
  }

  _RequiredSignalGate _evaluateRequiredSignals(
    _CellStructure structure, {
    required double artworkSimilarity,
  }) {
    final checks = <String, bool>{
      'blue': structure.bluePanelCoverage >= minimumBluePanelCoverage,
      'footer': structure.footerDarkCoverage >= minimumFooterDarkCoverage,
      'contrast': structure.footerContrast >= minimumFooterContrast,
      'book': structure.bookShapeEvidence >= minimumMarkerShapeEvidence,
      'tick': structure.tickShapeEvidence >= minimumMarkerShapeEvidence,
      'artwork': artworkSimilarity >= minimumArtworkSimilarity,
    };

    final failed = <String>[
      for (final entry in checks.entries)
        if (!entry.value) entry.key,
    ];

    return _RequiredSignalGate(
      passedCount: checks.length - failed.length,
      failedSignals: List<String>.unmodifiable(failed),
    );
  }

  _CellStructure _measureCell(
    img.Image image, {
    required int rowIndex,
    required int columnIndex,
    required int rows,
  }) {
    final cellWidth = image.width / ArcBlueprintCanonicalGrid.columns;
    final cellHeight = image.height / rows;
    final left = columnIndex * cellWidth;
    final top = rowIndex * cellHeight;

    final bluePanel = _measureBluePanel(
      image,
      left: left + cellWidth * 0.08,
      top: top + cellHeight * 0.07,
      right: left + cellWidth * 0.92,
      bottom: top + cellHeight * 0.73,
    );

    final footer = _measureFooter(
      image,
      left: left + cellWidth * 0.08,
      top: top + cellHeight * 0.77,
      right: left + cellWidth * 0.92,
      bottom: top + cellHeight * 0.95,
    );

    final upperLuma = _meanLuma(
      image,
      left: left + cellWidth * 0.10,
      top: top + cellHeight * 0.18,
      right: left + cellWidth * 0.90,
      bottom: top + cellHeight * 0.68,
    );

    final footerContrast = ((upperLuma - footer.meanLuma) / 255.0).clamp(
      0.0,
      1.0,
    );

    final book = _measureWhiteShape(
      image,
      left: left + cellWidth * 0.07,
      top: top + cellHeight * 0.74,
      right: left + cellWidth * 0.31,
      bottom: top + cellHeight * 0.95,
    );

    final tick = _measureWhiteShape(
      image,
      left: left + cellWidth * 0.70,
      top: top + cellHeight * 0.05,
      right: left + cellWidth * 0.95,
      bottom: top + cellHeight * 0.29,
    );

    return _CellStructure(
      bluePanelCoverage: bluePanel,
      footerDarkCoverage: footer.darkCoverage,
      footerContrast: footerContrast.toDouble(),
      bookShapeEvidence: book,
      tickShapeEvidence: tick,
    );
  }

  double _measureBluePanel(
    img.Image image, {
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) {
    final bounds = _bounds(image, left, top, right, bottom);
    var vividCool = 0;
    var count = 0;

    for (var y = bounds.y0; y <= bounds.y1; y++) {
      for (var x = bounds.x0; x <= bounds.x1; x++) {
        final pixel = image.getPixelSafe(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        final maxC = math.max(r, math.max(g, b));
        final minC = math.min(r, math.min(g, b));
        final saturation = maxC <= 0 ? 0 : (maxC - minC) / maxC;
        final luma = _luma(pixel);

        final coolDominant =
            b >= 72 &&
            b >= r * 1.12 &&
            b >= g * 0.92 &&
            saturation >= 0.30 &&
            luma >= 36;

        if (coolDominant) vividCool++;
        count++;
      }
    }

    return count == 0 ? 0 : vividCool / count;
  }

  _FooterEvidence _measureFooter(
    img.Image image, {
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) {
    final bounds = _bounds(image, left, top, right, bottom);
    var dark = 0;
    var lumaTotal = 0.0;
    var count = 0;

    for (var y = bounds.y0; y <= bounds.y1; y++) {
      for (var x = bounds.x0; x <= bounds.x1; x++) {
        final value = _luma(image.getPixelSafe(x, y));
        if (value <= 68) dark++;
        lumaTotal += value;
        count++;
      }
    }

    return _FooterEvidence(
      darkCoverage: count == 0 ? 0 : dark / count,
      meanLuma: count == 0 ? 0 : lumaTotal / count,
    );
  }

  double _measureWhiteShape(
    img.Image image, {
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) {
    final bounds = _bounds(image, left, top, right, bottom);
    final width = bounds.x1 - bounds.x0 + 1;
    final height = bounds.y1 - bounds.y0 + 1;

    var brightCount = 0;
    var minX = width;
    var maxX = -1;
    var minY = height;
    var maxY = -1;

    for (var y = bounds.y0; y <= bounds.y1; y++) {
      for (var x = bounds.x0; x <= bounds.x1; x++) {
        final pixel = image.getPixelSafe(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        final maxC = math.max(r, math.max(g, b));
        final minC = math.min(r, math.min(g, b));
        final neutral = maxC - minC <= 78;
        final bright = _luma(pixel) >= 150;

        if (neutral && bright) {
          final localX = x - bounds.x0;
          final localY = y - bounds.y0;
          brightCount++;
          minX = math.min(minX, localX);
          maxX = math.max(maxX, localX);
          minY = math.min(minY, localY);
          maxY = math.max(maxY, localY);
        }
      }
    }

    final area = math.max(1, width * height);
    final coverage = brightCount / area;
    if (brightCount == 0) return 0;

    final spanX = (maxX - minX + 1) / math.max(1, width);
    final spanY = (maxY - minY + 1) / math.max(1, height);

    // A cell border produces a thin one-dimensional line. Real book/tick
    // glyphs occupy meaningful width AND height inside the inset ROI.
    if (spanX < 0.18 || spanY < 0.18) return 0;
    if (coverage < 0.018 || coverage > 0.52) return 0;

    final coverageVote = (coverage / 0.16).clamp(0.0, 1.0);
    final spanVote = (math.min(spanX, spanY) / 0.45).clamp(0.0, 1.0);

    return ((coverageVote * 0.62) + (spanVote * 0.38))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double _meanLuma(
    img.Image image, {
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) {
    final bounds = _bounds(image, left, top, right, bottom);
    var total = 0.0;
    var count = 0;
    for (var y = bounds.y0; y <= bounds.y1; y++) {
      for (var x = bounds.x0; x <= bounds.x1; x++) {
        total += _luma(image.getPixelSafe(x, y));
        count++;
      }
    }
    return count == 0 ? 0 : total / count;
  }

  _Bounds _bounds(
    img.Image image,
    double left,
    double top,
    double right,
    double bottom,
  ) {
    final x0 = left.round().clamp(0, image.width - 2);
    final y0 = top.round().clamp(0, image.height - 2);
    final x1 = right.round().clamp(x0 + 1, image.width - 1);
    final y1 = bottom.round().clamp(y0 + 1, image.height - 1);
    return _Bounds(x0: x0, y0: y0, x1: x1, y1: y1);
  }

  double _luma(img.Pixel pixel) =>
      (pixel.r.toDouble() * 0.2126) +
      (pixel.g.toDouble() * 0.7152) +
      (pixel.b.toDouble() * 0.0722);
}

@immutable
class _RequiredSignalGate {
  const _RequiredSignalGate({
    required this.passedCount,
    required this.failedSignals,
  });

  final int passedCount;
  final List<String> failedSignals;

  bool get allPassed => passedCount == 6;
}

@immutable
class _CellStructure {
  const _CellStructure({
    required this.bluePanelCoverage,
    required this.footerDarkCoverage,
    required this.footerContrast,
    required this.bookShapeEvidence,
    required this.tickShapeEvidence,
  });

  final double bluePanelCoverage;
  final double footerDarkCoverage;
  final double footerContrast;
  final double bookShapeEvidence;
  final double tickShapeEvidence;
}

@immutable
class _FooterEvidence {
  const _FooterEvidence({required this.darkCoverage, required this.meanLuma});

  final double darkCoverage;
  final double meanLuma;
}

@immutable
class _Bounds {
  const _Bounds({
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
  });

  final int x0;
  final int y0;
  final int x1;
  final int y1;
}
