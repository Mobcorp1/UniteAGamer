import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_segmented_grid_extractor.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

enum ArcBlueprintGridSection { top, bottom }

class ArcBlueprintSectionGridExtractor {
  const ArcBlueprintSectionGridExtractor({
    this.cellWidth = 100,
    this.cellHeight = 100,
  });

  final int cellWidth;
  final int cellHeight;

  Uint8List extract({
    required Uint8List imageBytes,
    required ArcBlueprintGridDetection detection,
    required ArcBlueprintGridSection section,
  }) {
    if (section == ArcBlueprintGridSection.top) {
      return const ArcBlueprintSegmentedGridExtractor(
        columns: 10,
        rows: 5,
        cellWidth: 100,
        cellHeight: 100,
      ).extract(imageBytes: imageBytes, detection: detection);
    }

    return _extractBottomSection(imageBytes: imageBytes, detection: detection);
  }

  Uint8List _extractBottomSection({
    required Uint8List imageBytes,
    required ArcBlueprintGridDetection detection,
  }) {
    final decoded = _decode(imageBytes);

    if (detection.verticalDividers.length != 11 ||
        detection.horizontalDividers.length != 4) {
      throw const FormatException(
        'Rows 6–8 could not be detected as a complete 10 × 3 grid.',
      );
    }

    final rowGaps = <double>[
      for (var index = 1; index < detection.horizontalDividers.length; index++)
        detection.horizontalDividers[index] -
            detection.horizontalDividers[index - 1],
    ];
    final inferredRowHeight = rowGaps.reduce((a, b) => a + b) / rowGaps.length;

    final inferredBottom =
        detection.horizontalDividers.last + inferredRowHeight;

    if (inferredBottom > 1.02) {
      throw const FormatException(
        'The final three Blueprint slots are outside the captured image.',
      );
    }

    final horizontalDividers = <double>[
      ...detection.horizontalDividers,
      inferredBottom.clamp(0.0, 1.0),
    ];

    final output = img.Image(width: 10 * cellWidth, height: 4 * cellHeight);
    img.fill(output, color: img.ColorRgb8(8, 10, 14));

    for (var row = 0; row < 4; row++) {
      final maxColumns = row == 3 ? 3 : 10;
      final rawTop = horizontalDividers[row] * decoded.height;
      final rawBottom = horizontalDividers[row + 1] * decoded.height;
      final rowHeight = rawBottom - rawTop;
      final verticalInset = math.max(1, (rowHeight * 0.025).round());

      for (var column = 0; column < maxColumns; column++) {
        final rawLeft = detection.verticalDividers[column] * decoded.width;
        final rawRight = detection.verticalDividers[column + 1] * decoded.width;
        final columnWidth = rawRight - rawLeft;
        final horizontalInset = math.max(1, (columnWidth * 0.025).round());

        final left = (rawLeft.round() + horizontalInset).clamp(
          0,
          decoded.width - 2,
        );
        final right = (rawRight.round() - horizontalInset).clamp(
          left + 1,
          decoded.width - 1,
        );
        final top = (rawTop.round() + verticalInset).clamp(
          0,
          decoded.height - 2,
        );
        final bottom = (rawBottom.round() - verticalInset).clamp(
          top + 1,
          decoded.height - 1,
        );

        final cropped = img.copyCrop(
          decoded,
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

    return Uint8List.fromList(img.encodeJpg(output, quality: 96));
  }

  img.Image _decode(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw const FormatException(
          'The selected Blueprint image could not be decoded.',
        );
      }
      return img.bakeOrientation(decoded);
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException(
        'The selected Blueprint image could not be decoded.',
      );
    }
  }
}
