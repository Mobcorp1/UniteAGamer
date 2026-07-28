import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_photo_import_models.dart';

class ArcBlueprintPhotoDetectedCell {
  const ArcBlueprintPhotoDetectedCell({
    required this.rowIndex,
    required this.columnIndex,
    this.blueprintId = '',
    this.label = '',
    this.confidence = 0,
    this.blank = false,
    this.perceptualHash = '',
    this.sourceCaptureId = '',
  });

  final int rowIndex;
  final int columnIndex;
  final String blueprintId;
  final String label;
  final double confidence;
  final bool blank;
  final String perceptualHash;
  final String sourceCaptureId;

  bool get hasCandidate =>
      !blank && blueprintId.trim().isNotEmpty && confidence > 0;

  String get stableSignature {
    if (blank) return 'blank:$columnIndex';
    final id = blueprintId.trim().toLowerCase();
    final hash = perceptualHash.trim().toLowerCase();
    return '$columnIndex:${id.isEmpty ? hash : id}';
  }
}

class ArcBlueprintPhotoDetectedRow {
  const ArcBlueprintPhotoDetectedRow({
    required this.captureId,
    required this.rowIndex,
    required this.cells,
    this.overlapSignature = '',
  });

  final String captureId;
  final int rowIndex;
  final List<ArcBlueprintPhotoDetectedCell> cells;
  final String overlapSignature;

  String get signature {
    final explicit = overlapSignature.trim();
    if (explicit.isNotEmpty) return explicit;
    return cells.map((cell) => cell.stableSignature).join('|');
  }

  bool conflictsWith(ArcBlueprintPhotoDetectedRow other) {
    if (signature != other.signature) return false;
    final byColumn = <int, ArcBlueprintPhotoDetectedCell>{
      for (final cell in cells) cell.columnIndex: cell,
    };
    for (final otherCell in other.cells) {
      final current = byColumn[otherCell.columnIndex];
      if (current == null) continue;
      if (current.blank != otherCell.blank) return true;
      if (current.blueprintId.trim().isNotEmpty &&
          otherCell.blueprintId.trim().isNotEmpty &&
          current.blueprintId != otherCell.blueprintId) {
        return true;
      }
    }
    return false;
  }
}

class ArcBlueprintPhotoLocalMatchResult {
  const ArcBlueprintPhotoLocalMatchResult({
    required this.rows,
    required this.candidates,
    required this.reviewChanges,
    required this.conflictMessages,
    required this.removedOverlapRows,
    required this.providerCapabilitiesUnavailable,
  });

  final List<ArcBlueprintPhotoDetectedRow> rows;
  final List<ArcBlueprintPhotoCandidate> candidates;
  final List<ArcBlueprintPhotoReviewChange> reviewChanges;
  final List<String> conflictMessages;
  final int removedOverlapRows;
  final List<String> providerCapabilitiesUnavailable;

  bool get needsUserReview =>
      conflictMessages.isNotEmpty ||
      candidates.any((candidate) => candidate.needsReview) ||
      reviewChanges.any((change) => change.needsReview);

  ArcBlueprintPhotoImportSession applyToSession(
    ArcBlueprintPhotoImportSession session,
  ) {
    return ArcBlueprintPhotoImportSession(
      id: session.id,
      uid: session.uid,
      status: needsUserReview
          ? ArcBlueprintPhotoImportStatus.needsUserReview
          : ArcBlueprintPhotoImportStatus.confirmed,
      imagePath: session.imagePath,
      provider: session.provider,
      errorMessage: conflictMessages.join(' '),
      candidates: candidates,
      captures: session.captures,
      reviewChanges: reviewChanges,
      confirmedByUser: false,
      writePreviewOnly: true,
      retentionDays: session.retentionDays,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    );
  }
}

class ArcBlueprintPhotoLocalMatchingEngine {
  const ArcBlueprintPhotoLocalMatchingEngine({
    this.minimumAutoMatchConfidence = 0.92,
  });

  final double minimumAutoMatchConfidence;

  ArcBlueprintPhotoLocalMatchResult stitchAndScore(
    List<List<ArcBlueprintPhotoDetectedRow>> captures,
  ) {
    final rows = <ArcBlueprintPhotoDetectedRow>[];
    final conflicts = <String>[];
    var removed = 0;

    for (final captureRows in captures) {
      if (captureRows.isEmpty) continue;
      var startIndex = 0;
      if (rows.isNotEmpty &&
          rows.last.signature == captureRows.first.signature) {
        if (rows.last.conflictsWith(captureRows.first)) {
          conflicts.add(
            'Overlap row conflict between ${rows.last.captureId} and ${captureRows.first.captureId}.',
          );
        }
        startIndex = 1;
        removed += 1;
      }
      rows.addAll(captureRows.skip(startIndex));
    }

    final candidates = <ArcBlueprintPhotoCandidate>[];
    final changes = <ArcBlueprintPhotoReviewChange>[];
    final seen = <String>{};
    for (final row in rows) {
      for (final cell in row.cells) {
        if (!cell.hasCandidate) continue;
        final key = '${cell.rowIndex}:${cell.columnIndex}:${cell.blueprintId}';
        if (!seen.add(key)) continue;
        candidates.add(
          ArcBlueprintPhotoCandidate(
            blueprintId: cell.blueprintId,
            label: cell.label,
            confidence: cell.confidence,
            sourceText: cell.perceptualHash,
          ),
        );
        changes.add(
          ArcBlueprintPhotoReviewChange(
            blueprintId: cell.blueprintId,
            owned: true,
            source: 'local_blueprint_photo_matching',
            confidence: cell.confidence,
            manualCorrection: cell.confidence >= minimumAutoMatchConfidence,
          ),
        );
      }
    }

    return ArcBlueprintPhotoLocalMatchResult(
      rows: rows,
      candidates: candidates,
      reviewChanges: changes,
      conflictMessages: conflicts,
      removedOverlapRows: removed,
      providerCapabilitiesUnavailable: const <String>[
        'cloud_ocr',
        'remote_template_matching',
      ],
    );
  }
}
