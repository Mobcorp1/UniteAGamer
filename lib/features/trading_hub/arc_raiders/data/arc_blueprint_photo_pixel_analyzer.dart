import 'dart:typed_data';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_hybrid_recognition_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';

class ArcBlueprintPhotoPixelAnalysis {
  const ArcBlueprintPhotoPixelAnalysis({
    required this.samples,
    required this.error,
    this.confidence = 0,
  });

  final List<ArcBlueprintPhotoOccupancySample> samples;
  final String error;
  final double confidence;

  bool get succeeded => error.isEmpty && samples.isNotEmpty;
}

class ArcBlueprintPhotoPixelAnalyzer {
  const ArcBlueprintPhotoPixelAnalyzer({this.columns = 10, this.rows = 5});

  final int columns;
  final int rows;

  ArcBlueprintPhotoPixelAnalysis analyze({
    required Uint8List bytes,
    required String captureId,
  }) {
    final result = ArcBlueprintHybridRecognitionEngine(
      columns: columns,
      rows: rows,
    ).analyze(bytes: bytes, captureId: captureId);

    return ArcBlueprintPhotoPixelAnalysis(
      samples: result.samples,
      error: result.error,
      confidence: result.captureConfidence,
    );
  }
}
