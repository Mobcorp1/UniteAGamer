import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_section_grid_extractor.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_uploaded_image_processor.dart';

img.Image buildGrid({
  required int completeRows,
  required bool includePartialFinalRow,
}) {
  final image = img.Image(width: 1200, height: 700);
  img.fill(image, color: img.ColorRgb8(8, 10, 14));

  const left = 100;
  const top = 100;
  const cellWidth = 100;
  const cellHeight = 90;

  for (var row = 0; row <= completeRows; row++) {
    final y = top + row * cellHeight;
    img.drawLine(
      image,
      x1: left,
      y1: y,
      x2: left + 1000,
      y2: y,
      color: img.ColorRgb8(230, 230, 235),
      thickness: 4,
    );
  }

  for (var column = 0; column <= 10; column++) {
    final x = left + column * cellWidth;
    img.drawLine(
      image,
      x1: x,
      y1: top,
      x2: x,
      y2: top + completeRows * cellHeight,
      color: img.ColorRgb8(230, 230, 235),
      thickness: 4,
    );
  }

  if (includePartialFinalRow) {
    for (var column = 0; column <= 3; column++) {
      final x = left + column * cellWidth;
      img.drawLine(
        image,
        x1: x,
        y1: top + completeRows * cellHeight,
        x2: x,
        y2: top + (completeRows + 1) * cellHeight,
        color: img.ColorRgb8(230, 230, 235),
        thickness: 4,
      );
    }

    img.drawLine(
      image,
      x1: left,
      y1: top + (completeRows + 1) * cellHeight,
      x2: left + 300,
      y2: top + (completeRows + 1) * cellHeight,
      color: img.ColorRgb8(230, 230, 235),
      thickness: 4,
    );
  }

  return image;
}

void main() {
  test('uploaded top image requires automatic grid detection', () {
    final image = img.Image(width: 1000, height: 500);
    img.fill(image, color: img.ColorRgb8(22, 24, 28));

    expect(
      () => const ArcBlueprintUploadedImageProcessor().process(
        Uint8List.fromList(img.encodePng(image)),
        section: ArcBlueprintGridSection.top,
      ),
      throwsFormatException,
    );
  });

  test('uploaded bottom image requires automatic grid detection', () {
    final image = img.Image(width: 1000, height: 400);
    img.fill(image, color: img.ColorRgb8(22, 24, 28));

    expect(
      () => const ArcBlueprintUploadedImageProcessor().process(
        Uint8List.fromList(img.encodePng(image)),
        section: ArcBlueprintGridSection.bottom,
      ),
      throwsFormatException,
    );
  });

  test('empty bytes are rejected', () {
    expect(
      () => const ArcBlueprintUploadedImageProcessor().process(
        Uint8List(0),
        section: ArcBlueprintGridSection.top,
      ),
      throwsFormatException,
    );
  });

  test('uploaded bottom image keeps the inferred final three-slot row', () {
    final result = const ArcBlueprintUploadedImageProcessor().process(
      Uint8List.fromList(
        img.encodePng(buildGrid(completeRows: 3, includePartialFinalRow: true)),
      ),
      section: ArcBlueprintGridSection.bottom,
    );

    final decoded = img.decodeImage(result.imageBytes);

    expect(decoded, isNotNull);
    expect(decoded!.width, 1000);
    expect(decoded.height, 400);
    expect(result.rows, 4);
  });
}
