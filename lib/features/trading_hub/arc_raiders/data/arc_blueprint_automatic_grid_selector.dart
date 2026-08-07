import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_detector.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_section_grid_extractor.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_canonical_grid.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

@immutable
class ArcBlueprintAutomaticGridSelection {
  const ArcBlueprintAutomaticGridSelection({
    required this.imageBytes,
    required this.detection,
    required this.message,
    required this.rows,
    required this.canonicalPositions,
  });

  final Uint8List imageBytes;
  final ArcBlueprintGridDetection detection;
  final String message;
  final int rows;
  final List<ArcBlueprintCanonicalPosition> canonicalPositions;
}

class ArcBlueprintAutomaticGridSelector {
  const ArcBlueprintAutomaticGridSelector({
    this.minimumConfidence = 0.58,
    this.extractor = const ArcBlueprintSectionGridExtractor(),
  });

  final double minimumConfidence;
  final ArcBlueprintSectionGridExtractor extractor;

  ArcBlueprintAutomaticGridSelection select(
    Uint8List bytes, {
    required ArcBlueprintGridSection section,
  }) {
    if (bytes.isEmpty) {
      throw const FormatException('The selected image was empty.');
    }

    final detectedRows = section == ArcBlueprintGridSection.top ? 5 : 3;

    final detector = ArcBlueprintGridDetector(
      columns: 10,
      rows: detectedRows,
      minimumConfidence: minimumConfidence,
    );

    final detection = detector.detect(bytes);
    final expectedHorizontalDividers = detectedRows + 1;

    if (!detection.isValid ||
        !detection.hasSegmentedGrid ||
        detection.verticalDividers.length != detection.columns + 1 ||
        detection.horizontalDividers.length != expectedHorizontalDividers ||
        detection.confidence < minimumConfidence) {
      final label = section == ArcBlueprintGridSection.top
          ? 'rows 1–5'
          : 'rows 6–8 plus the final three slots';
      throw FormatException(
        'The automatic scanner could not lock $label. '
        'Keep the complete section visible and square to the camera.',
      );
    }

    final normalized = extractor.extract(
      imageBytes: bytes,
      detection: detection,
      section: section,
    );

    return ArcBlueprintAutomaticGridSelection(
      imageBytes: Uint8List.fromList(normalized),
      detection: detection,
      rows: section == ArcBlueprintGridSection.top ? 5 : 4,
      canonicalPositions: section == ArcBlueprintGridSection.top
          ? ArcBlueprintCanonicalGrid.topCapturePositions()
          : ArcBlueprintCanonicalGrid.bottomCapturePositions(),
      message: section == ArcBlueprintGridSection.top
          ? 'Rows 1–5 locked automatically.'
          : 'Rows 6–8 and the final three slots locked automatically.',
    );
  }
}
