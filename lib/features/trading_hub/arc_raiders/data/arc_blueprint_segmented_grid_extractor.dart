import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

class ArcBlueprintSegmentedGridExtractor {
  const ArcBlueprintSegmentedGridExtractor({
    this.columns = 10,
    this.rows = 5,
    this.cellWidth = 100,
    this.cellHeight = 100,
    this.dividerInsetFraction = 0.025,
  });

  final int columns;
  final int rows;
  final int cellWidth;
  final int cellHeight;
  final double dividerInsetFraction;

  Uint8List extract({
    required Uint8List imageBytes,
    required ArcBlueprintGridDetection detection,
  }) {
    final decoded = _decode(imageBytes);
    if (!detection.hasSegmentedGrid ||
        detection.verticalDividers.length != columns + 1 ||
        detection.horizontalDividers.length != rows + 1) {
      throw const FormatException(
        'A complete segmented Blueprint grid was not available.',
      );
    }

    final output = img.Image(
      width: columns * cellWidth,
      height: rows * cellHeight,
    );

    for (var row = 0; row < rows; row++) {
      final rawTop = detection.horizontalDividers[row] * decoded.height;
      final rawBottom = detection.horizontalDividers[row + 1] * decoded.height;
      final rowHeight = rawBottom - rawTop;
      final verticalInset = math.max(
        1,
        (rowHeight * dividerInsetFraction).round(),
      );

      for (var column = 0; column < columns; column++) {
        final rawLeft = detection.verticalDividers[column] * decoded.width;
        final rawRight = detection.verticalDividers[column + 1] * decoded.width;
        final columnWidth = rawRight - rawLeft;
        final horizontalInset = math.max(
          1,
          (columnWidth * dividerInsetFraction).round(),
        );

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
