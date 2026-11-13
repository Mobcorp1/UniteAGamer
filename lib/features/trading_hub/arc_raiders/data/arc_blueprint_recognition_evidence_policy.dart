import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_cell_analyzer.dart';

@immutable
class ArcBlueprintRecognitionCalibration {
  const ArcBlueprintRecognitionCalibration({
    required this.score,
    required this.reason,
    required this.promoted,
    required this.suppressed,
  });

  final double score;
  final String reason;
  final bool promoted;
  final bool suppressed;
}

/// Converts raw cell occupancy into a conservative ownership score using the
/// independent visual signals that are actually present in the ARC Raiders
/// Blueprint grid.
///
/// The previous pipeline used the Blueprint-specific detector for the primary
/// crop but allowed generic retry scoring to influence uncertain cells. That
/// produced a large cluster around 0.790-0.853 in real-device captures. This
/// policy requires agreement between electric-blue grid coverage, bright
/// foreground artwork, texture/edges and contrast before a borderline cell can
/// become confidently owned.
class ArcBlueprintRecognitionEvidencePolicy {
  const ArcBlueprintRecognitionEvidencePolicy();

  ArcBlueprintRecognitionCalibration calibrate(
    ArcBlueprintCellEvidence evidence,
  ) {
    final raw = evidence.occupancyScore.clamp(0.0, 1.0).toDouble();

    final strongBlueprintBackground = evidence.blueprintBlueCoverage >= 0.135;
    final strongArtwork =
        evidence.brightFeatureCoverage >= 0.045 &&
        evidence.foregroundCoverage >= 0.16;
    final structuralDetail =
        evidence.texture >= 0.13 || evidence.edgeDensity >= 0.12;
    final usefulContrast = evidence.luminanceRange >= 0.11;

    final decisiveOwned =
        raw >= 0.94 &&
        strongBlueprintBackground &&
        strongArtwork &&
        structuralDetail;

    if (decisiveOwned) {
      return ArcBlueprintRecognitionCalibration(
        score: raw,
        reason: 'decisive multi-signal Blueprint artwork',
        promoted: false,
        suppressed: false,
      );
    }

    final reliableOwned =
        raw >= 0.84 &&
        evidence.confidence >= 0.74 &&
        strongBlueprintBackground &&
        strongArtwork &&
        structuralDetail &&
        usefulContrast &&
        evidence.windowAgreement >= 0.52;

    if (reliableOwned) {
      return ArcBlueprintRecognitionCalibration(
        score: raw,
        reason: 'reliable multi-window Blueprint evidence',
        promoted: false,
        suppressed: false,
      );
    }

    // Recover a narrow band of real artwork that the conservative PASS 335
    // colour gate left at ~0.79. Promotion requires every independent signal
    // to agree, so a blue panel, divider line or reflection cannot qualify.
    final recoverableOwned =
        raw >= 0.76 &&
        raw < 0.84 &&
        evidence.confidence >= 0.72 &&
        evidence.blueprintBlueCoverage >= 0.17 &&
        evidence.brightFeatureCoverage >= 0.065 &&
        evidence.foregroundCoverage >= 0.20 &&
        evidence.texture >= 0.145 &&
        evidence.edgeDensity >= 0.135 &&
        evidence.luminanceRange >= 0.15 &&
        evidence.windowAgreement >= 0.60;

    if (recoverableOwned) {
      return const ArcBlueprintRecognitionCalibration(
        score: 0.845,
        reason: 'borderline score recovered by unanimous artwork evidence',
        promoted: true,
        suppressed: false,
      );
    }

    // Borderline owned scores without independent artwork agreement are held
    // below the automatic-owned threshold. They remain review/uncertain rather
    // than becoming false positives.
    if (raw >= 0.84 && raw < 0.94) {
      return ArcBlueprintRecognitionCalibration(
        score: 0.82,
        reason: 'borderline owned score suppressed: evidence did not agree',
        promoted: false,
        suppressed: true,
      );
    }

    return ArcBlueprintRecognitionCalibration(
      score: raw,
      reason: 'raw evidence retained',
      promoted: false,
      suppressed: false,
    );
  }
}
