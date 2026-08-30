import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_hybrid_recognition_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_perspective_cropper.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_section_grid_extractor.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

@immutable
class ArcBlueprintLiveOccupancyAnalysis {
  const ArcBlueprintLiveOccupancyAnalysis({
    required this.samples,
    required this.captureConfidence,
    required this.error,
    required this.section,
  });

  final List<ArcBlueprintPhotoOccupancySample> samples;
  final double captureConfidence;
  final String error;
  final ArcBlueprintGridSection section;

  bool get succeeded => error.isEmpty && samples.isNotEmpty;
}

class ArcBlueprintLiveOccupancyEngine {
  const ArcBlueprintLiveOccupancyEngine({
    this.cellWidth = 100,
    this.cellHeight = 100,
  });

  final int cellWidth;
  final int cellHeight;

  ArcBlueprintLiveOccupancyAnalysis analyzeFrame({
    required img.Image frameImage,
    required ArcBlueprintGridDetection detection,
    required ArcBlueprintGridSection section,
    required String captureId,
  }) {
    final expectedRows = 5;
    final expectedHorizontalDividers = expectedRows + 1;

    if (!detection.isValid ||
        !detection.hasSegmentedGrid ||
        detection.columns != 10 ||
        detection.rows != expectedRows ||
        detection.verticalDividers.length != 11 ||
        detection.horizontalDividers.length != expectedHorizontalDividers) {
      return ArcBlueprintLiveOccupancyAnalysis(
        samples: const <ArcBlueprintPhotoOccupancySample>[],
        captureConfidence: 0,
        error: 'The live Blueprint grid is not locked strongly enough.',
        section: section,
      );
    }

    try {
      final normalized = _normalizeSection(
        frameImage: frameImage,
        detection: detection,
        section: section,
      );

      final analysis =
          const ArcBlueprintHybridRecognitionEngine(
            columns: 10,
            rows: 5,
          ).analyze(
            bytes: Uint8List.fromList(img.encodeJpg(normalized, quality: 91)),
            captureId: captureId,
          );

      if (!analysis.succeeded) {
        return ArcBlueprintLiveOccupancyAnalysis(
          samples: const <ArcBlueprintPhotoOccupancySample>[],
          captureConfidence: analysis.captureConfidence,
          error: analysis.error,
          section: section,
        );
      }

      // PASS 353A keeps scan-segment rows local. The reconciliation engine
      // aligns the next segment by overlap instead of hard-coding row 6.
      return ArcBlueprintLiveOccupancyAnalysis(
        samples: List<ArcBlueprintPhotoOccupancySample>.unmodifiable(
          analysis.samples,
        ),
        captureConfidence: analysis.captureConfidence,
        error: '',
        section: section,
      );
    } on FormatException catch (error) {
      return ArcBlueprintLiveOccupancyAnalysis(
        samples: const <ArcBlueprintPhotoOccupancySample>[],
        captureConfidence: 0,
        error: error.message,
        section: section,
      );
    } on Object {
      return ArcBlueprintLiveOccupancyAnalysis(
        samples: const <ArcBlueprintPhotoOccupancySample>[],
        captureConfidence: 0,
        error: 'The live Blueprint cells could not be analysed.',
        section: section,
      );
    }
  }

  img.Image _normalizeSection({
    required img.Image frameImage,
    required ArcBlueprintGridDetection detection,
    required ArcBlueprintGridSection section,
  }) {
    // Perspective-rectify the detected grid before occupancy analysis. A phone
    // aimed at a TV commonly sees a trapezoid, so cropping cells directly from
    // raw x/y dividers causes columns to drift as they move across the panel.
    final bytes = Uint8List.fromList(img.encodeJpg(frameImage, quality: 94));
    final rectifiedBytes = const ArcBlueprintPerspectiveCropper(
      outputWidth: 1000,
      cellHeight: 100,
    ).rectifyDetection(imageBytes: bytes, detection: detection);
    final decoded = img.decodeImage(rectifiedBytes);
    if (decoded == null) {
      throw const FormatException(
        'The live Blueprint panel could not be perspective-corrected.',
      );
    }

    return img.bakeOrientation(decoded);
  }
}
