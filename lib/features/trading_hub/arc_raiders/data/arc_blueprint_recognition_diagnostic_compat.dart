import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_recognition_diagnostics.dart';

extension ArcBlueprintCellDiagnosticCompatibility
    on ArcBlueprintCellDiagnostic {
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'row': rowIndex + 1,
      'column': columnIndex + 1,
      'classification': classificationLabel,
      'occupancyScore': occupancyScore,
      'confidence': confidence,
      'texture': textureVote,
      'edgeDensity': edgeVote,
      'saturation': colourVote,
      'foregroundCoverage': foregroundVote,
      'luminanceRange': silhouetteVote,
      'retryCount': retryCount,
      'reason': reason,
    };
  }

  String get classificationLabel {
    if (isOwned) return 'owned';
    if (isMissing) return 'missing';
    return 'uncertain';
  }

  String get reason {
    return 'occupancy=${occupancyScore.toStringAsFixed(3)}; '
        'confidence=${confidence.toStringAsFixed(3)}; '
        'texture=${textureVote.toStringAsFixed(3)}; '
        'edge=${edgeVote.toStringAsFixed(3)}; '
        'colour=${colourVote.toStringAsFixed(3)}; '
        'foreground=${foregroundVote.toStringAsFixed(3)}; '
        'silhouette=${silhouetteVote.toStringAsFixed(3)}; '
        'retries=$retryCount';
  }
}
