import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_hybrid_recognition_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';
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
    final expectedRows = section == ArcBlueprintGridSection.top ? 5 : 3;
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
          ArcBlueprintHybridRecognitionEngine(
            columns: 10,
            rows: section == ArcBlueprintGridSection.top ? 5 : 4,
            validColumnCountsByRow: section == ArcBlueprintGridSection.top
                ? const <int>[]
                : const <int>[10, 10, 10, 3],
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

      final rowOffset = section == ArcBlueprintGridSection.top ? 0 : 5;
      final globalSamples = analysis.samples
          .map(
            (sample) => ArcBlueprintPhotoOccupancySample(
              captureId: sample.captureId,
              rowIndex: sample.rowIndex + rowOffset,
              columnIndex: sample.columnIndex,
              occupancyScore: sample.occupancyScore,
            ),
          )
          .toList(growable: false);

      return ArcBlueprintLiveOccupancyAnalysis(
        samples: List<ArcBlueprintPhotoOccupancySample>.unmodifiable(
          globalSamples,
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
    final source = img.bakeOrientation(frameImage);
    final rowCount = section == ArcBlueprintGridSection.top ? 5 : 4;
    final validColumns = section == ArcBlueprintGridSection.top
        ? const <int>[10, 10, 10, 10, 10]
        : const <int>[10, 10, 10, 3];

    final horizontalDividers = <double>[...detection.horizontalDividers];

    if (section == ArcBlueprintGridSection.bottom) {
      final gaps = <double>[
        for (
          var index = 1;
          index < detection.horizontalDividers.length;
          index++
        )
          detection.horizontalDividers[index] -
              detection.horizontalDividers[index - 1],
      ];

      if (gaps.isEmpty) {
        throw const FormatException(
          'The lower Blueprint row spacing could not be inferred.',
        );
      }

      final inferredHeight = gaps.reduce((a, b) => a + b) / gaps.length;
      final inferredBottom = detection.horizontalDividers.last + inferredHeight;

      if (inferredBottom > 1.04) {
        throw const FormatException(
          'The final Blueprint row is outside the live camera frame.',
        );
      }

      horizontalDividers.add(inferredBottom.clamp(0.0, 1.0));
    }

    if (horizontalDividers.length != rowCount + 1) {
      throw const FormatException(
        'The live Blueprint row boundaries are incomplete.',
      );
    }

    final output = img.Image(
      width: 10 * cellWidth,
      height: rowCount * cellHeight,
    );
    img.fill(output, color: img.ColorRgb8(8, 10, 14));

    for (var row = 0; row < rowCount; row++) {
      final rawTop = horizontalDividers[row] * source.height;
      final rawBottom = horizontalDividers[row + 1] * source.height;
      final rowHeight = rawBottom - rawTop;
      if (rowHeight <= 2) {
        throw const FormatException(
          'The live Blueprint row height is invalid.',
        );
      }

      final verticalInset = math.max(1, (rowHeight * 0.025).round());

      for (var column = 0; column < validColumns[row]; column++) {
        final rawLeft = detection.verticalDividers[column] * source.width;
        final rawRight = detection.verticalDividers[column + 1] * source.width;
        final columnWidth = rawRight - rawLeft;
        if (columnWidth <= 2) {
          throw const FormatException(
            'The live Blueprint column width is invalid.',
          );
        }

        final horizontalInset = math.max(1, (columnWidth * 0.025).round());

        final left = (rawLeft.round() + horizontalInset).clamp(
          0,
          source.width - 2,
        );
        final right = (rawRight.round() - horizontalInset).clamp(
          left + 1,
          source.width - 1,
        );
        final top = (rawTop.round() + verticalInset).clamp(
          0,
          source.height - 2,
        );
        final bottom = (rawBottom.round() - verticalInset).clamp(
          top + 1,
          source.height - 1,
        );

        final cropped = img.copyCrop(
          source,
          x: left,
          y: top,
          width: right - left + 1,
          height: bottom - top + 1,
        );
        final normalized = img.copyResize(
          cropped,
          width: cellWidth,
          height: cellHeight,
          interpolation: img.Interpolation.cubic,
        );

        final destinationX = column * cellWidth;
        final destinationY = row * cellHeight;

        for (var y = 0; y < cellHeight; y++) {
          for (var x = 0; x < cellWidth; x++) {
            output.setPixel(
              destinationX + x,
              destinationY + y,
              normalized.getPixel(x, y),
            );
          }
        }
      }
    }

    return output;
  }
}
