import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

@immutable
class ArcBlueprintImportQualityResult {
  const ArcBlueprintImportQualityResult({
    required this.accepted,
    required this.score,
    required this.uncertainCount,
    required this.message,
  });

  final bool accepted;
  final double score;
  final int uncertainCount;
  final String message;
}

class ArcBlueprintImportQualityGate {
  const ArcBlueprintImportQualityGate({
    this.expectedPositions = 83,
    this.minimumCaptureConfidence = 0.50,
    this.maximumUncertainCells = 20,
  });

  final int expectedPositions;
  final double minimumCaptureConfidence;
  final int maximumUncertainCells;

  ArcBlueprintImportQualityResult evaluate({
    required List<ArcBlueprintPhotoCellDecision> decisions,
    required double topCaptureConfidence,
    required double bottomCaptureConfidence,
    required double overlapConfidence,
  }) {
    if (decisions.length != expectedPositions) {
      return ArcBlueprintImportQualityResult(
        accepted: false,
        score: 0,
        uncertainCount: decisions
            .where((decision) => decision.needsReview)
            .length,
        message:
            'The automatic scanner produced ${decisions.length} of $expectedPositions positions.',
      );
    }

    if (topCaptureConfidence < minimumCaptureConfidence ||
        bottomCaptureConfidence < minimumCaptureConfidence) {
      final weakest = topCaptureConfidence <= bottomCaptureConfidence
          ? 'top'
          : 'bottom';

      return ArcBlueprintImportQualityResult(
        accepted: false,
        score: (topCaptureConfidence + bottomCaptureConfidence) / 2,
        uncertainCount: decisions
            .where((decision) => decision.needsReview)
            .length,
        message: 'The $weakest section was too unclear for a safe import.',
      );
    }

    final uncertainCount = decisions
        .where((decision) => decision.needsReview)
        .length;

    if (uncertainCount > maximumUncertainCells) {
      return ArcBlueprintImportQualityResult(
        accepted: false,
        score: 0,
        uncertainCount: uncertainCount,
        message:
            '$uncertainCount Blueprint positions were uncertain. No changes were applied.',
      );
    }

    final averageConfidence = decisions.isEmpty
        ? 0.0
        : decisions
                  .map((decision) => decision.confidence)
                  .reduce((a, b) => a + b) /
              decisions.length;

    final score =
        ((topCaptureConfidence * 0.30) +
                (bottomCaptureConfidence * 0.30) +
                (averageConfidence * 0.40))
            .clamp(0.0, 1.0);

    return ArcBlueprintImportQualityResult(
      accepted: true,
      score: score,
      uncertainCount: uncertainCount,
      message:
          'Automatic 83-position grid verified at ${(score * 100).round()}% confidence.',
    );
  }
}
