import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_automatic_grid_selector.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_section_grid_extractor.dart';

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
  test('top selector returns a 10 by 5 mosaic', () {
    final result = const ArcBlueprintAutomaticGridSelector().select(
      Uint8List.fromList(
        img.encodePng(
          buildGrid(completeRows: 5, includePartialFinalRow: false),
        ),
      ),
      section: ArcBlueprintGridSection.top,
    );

    final decoded = img.decodeImage(result.imageBytes);
    expect(decoded, isNotNull);
    expect(decoded!.width, 1000);
    expect(decoded.height, 500);
    expect(result.canonicalPositions, hasLength(50));
  });

  test('bottom selector detects three full rows and infers final row', () {
    final result = const ArcBlueprintAutomaticGridSelector().select(
      Uint8List.fromList(
        img.encodePng(buildGrid(completeRows: 3, includePartialFinalRow: true)),
      ),
      section: ArcBlueprintGridSection.bottom,
    );

    final decoded = img.decodeImage(result.imageBytes);
    expect(decoded, isNotNull);
    expect(decoded!.width, 1000);
    expect(decoded.height, 400);
    expect(result.detection.horizontalDividers, hasLength(4));
    expect(result.canonicalPositions, hasLength(33));
    expect(result.canonicalPositions.last.globalRowIndex, 8);
    expect(result.canonicalPositions.last.columnIndex, 2);
  });
}
