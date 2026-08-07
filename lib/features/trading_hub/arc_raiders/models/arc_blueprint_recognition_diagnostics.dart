import 'package:flutter/foundation.dart';

@immutable
class ArcBlueprintCellDiagnostic {
  const ArcBlueprintCellDiagnostic({
    required this.rowIndex,
    required this.columnIndex,
    required this.occupancyScore,
    required this.confidence,
    required this.textureVote,
    required this.edgeVote,
    required this.colourVote,
    required this.foregroundVote,
    required this.silhouetteVote,
    required this.retryCount,
  });

  final int rowIndex;
  final int columnIndex;
  final double occupancyScore;
  final double confidence;
  final double textureVote;
  final double edgeVote;
  final double colourVote;
  final double foregroundVote;
  final double silhouetteVote;
  final int retryCount;

  bool get isOwned => occupancyScore >= 0.72;
  bool get isMissing => occupancyScore <= 0.28;
  bool get isUncertain => !isOwned && !isMissing;
}
