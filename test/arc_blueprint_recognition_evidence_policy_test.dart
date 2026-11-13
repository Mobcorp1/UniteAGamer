import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_cell_analyzer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_recognition_evidence_policy.dart';

ArcBlueprintCellEvidence evidence({
  required double score,
  required double confidence,
  double blue = 0.20,
  double bright = 0.08,
  double texture = 0.18,
  double edges = 0.17,
  double foreground = 0.24,
  double range = 0.20,
  double agreement = 0.75,
}) {
  return ArcBlueprintCellEvidence(
    occupancyScore: score,
    confidence: confidence,
    texture: texture,
    edgeDensity: edges,
    saturation: 0.5,
    foregroundCoverage: foreground,
    luminanceRange: range,
    blueprintBlueCoverage: blue,
    brightFeatureCoverage: bright,
    windowAgreement: agreement,
  );
}

void main() {
  const policy = ArcBlueprintRecognitionEvidencePolicy();

  test('decisive artwork remains owned', () {
    final result = policy.calibrate(evidence(score: 0.98, confidence: 0.97));
    expect(result.score, greaterThanOrEqualTo(0.94));
    expect(result.suppressed, isFalse);
  });

  test('weak borderline owned score is suppressed to uncertain', () {
    final result = policy.calibrate(
      evidence(
        score: 0.86,
        confidence: 0.68,
        blue: 0.12,
        bright: 0.02,
        texture: 0.10,
        edges: 0.09,
        foreground: 0.12,
        range: 0.09,
        agreement: 0.45,
      ),
    );
    expect(result.score, lessThan(0.84));
    expect(result.suppressed, isTrue);
  });

  test('0.79 plateau can recover only with unanimous artwork evidence', () {
    final result = policy.calibrate(evidence(score: 0.79, confidence: 0.76));
    expect(result.score, greaterThanOrEqualTo(0.84));
    expect(result.promoted, isTrue);
  });

  test('0.79 without bright artwork remains uncertain', () {
    final result = policy.calibrate(
      evidence(score: 0.79, confidence: 0.76, bright: 0.02),
    );
    expect(result.score, lessThan(0.84));
    expect(result.promoted, isFalse);
  });
}
