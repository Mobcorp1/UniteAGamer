import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_automatic_grid_selector.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_section_grid_extractor.dart';

@immutable
class ArcBlueprintUploadedImageResult {
  const ArcBlueprintUploadedImageResult({
    required this.imageBytes,
    required this.confidence,
    required this.message,
    required this.rows,
  });

  final Uint8List imageBytes;
  final double confidence;
  final String message;
  final int rows;
}

class ArcBlueprintUploadedImageProcessor {
  const ArcBlueprintUploadedImageProcessor({
    this.selector = const ArcBlueprintAutomaticGridSelector(),
  });

  final ArcBlueprintAutomaticGridSelector selector;

  ArcBlueprintUploadedImageResult process(
    Uint8List bytes, {
    required ArcBlueprintGridSection section,
  }) {
    final selection = selector.select(bytes, section: section);

    return ArcBlueprintUploadedImageResult(
      imageBytes: Uint8List.fromList(selection.imageBytes),
      confidence: selection.detection.confidence,
      message: section == ArcBlueprintGridSection.top
          ? 'Rows 1–5 automatically detected and perspective-corrected.'
          : 'Rows 6–8 and the final three slots automatically detected.',
      rows: selection.rows,
    );
  }
}
