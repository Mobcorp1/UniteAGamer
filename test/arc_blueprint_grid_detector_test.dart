import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_detector.dart';

img.Image buildGrid({
  required int rows,
  int width = 720,
  int height = 420,
  int left = 80,
  int top = 60,
  int cellWidth = 55,
  int cellHeight = 58,
  bool addNoise = false,
}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(8, 8, 12));

  img.fillRect(
    image,
    x1: left,
    y1: top,
    x2: left + (cellWidth * 10),
    y2: top + (cellHeight * rows),
    color: img.ColorRgb8(28, 32, 40),
  );

  for (var column = 0; column <= 10; column++) {
    final x = left + (column * cellWidth);
    img.drawLine(
      image,
      x1: x,
      y1: top,
      x2: x,
      y2: top + (cellHeight * rows),
      color: img.ColorRgb8(220, 230, 240),
      thickness: 3,
    );
  }

  for (var row = 0; row <= rows; row++) {
    final y = top + (row * cellHeight);
    img.drawLine(
      image,
      x1: left,
      y1: y,
      x2: left + (cellWidth * 10),
      y2: y,
      color: img.ColorRgb8(220, 230, 240),
      thickness: 3,
    );
  }

  if (addNoise) {
    for (var x = 25; x < width - 25; x += 43) {
      img.drawLine(
        image,
        x1: x,
        y1: 12,
        x2: x + 14,
        y2: height - 16,
        color: img.ColorRgb8(55, 60, 70),
      );
    }
  }

  return image;
}

void main() {
  test('automatically segments the 10 by 5 top grid', () {
    final result = const ArcBlueprintGridDetector(
      columns: 10,
      rows: 5,
    ).detect(Uint8List.fromList(img.encodePng(buildGrid(rows: 5))));

    expect(result.isValid, isTrue);
    expect(result.hasSegmentedGrid, isTrue);
    expect(result.columns, 10);
    expect(result.rows, 5);
    expect(result.verticalDividers, hasLength(11));
    expect(result.horizontalDividers, hasLength(6));
  });

  test('supports direct image detection without PNG bytes', () {
    final result = const ArcBlueprintGridDetector(
      columns: 10,
      rows: 5,
    ).detectImage(buildGrid(rows: 5));

    expect(result.isValid, isTrue);
    expect(result.hasSegmentedGrid, isTrue);
  });

  test('automatically segments the 10 by 3 lower full-row section', () {
    final result =
        const ArcBlueprintGridDetector(
          columns: 10,
          rows: 3,
          minimumConfidence: 0.50,
        ).detect(
          Uint8List.fromList(
            img.encodePng(
              buildGrid(rows: 3, height: 360, top: 70, cellHeight: 62),
            ),
          ),
        );

    expect(result.isValid, isTrue);
    expect(result.hasSegmentedGrid, isTrue);
    expect(result.rows, 3);
    expect(result.verticalDividers, hasLength(11));
    expect(result.horizontalDividers, hasLength(4));
  });

  test('locks through moderate unrelated screen noise', () {
    final result = const ArcBlueprintGridDetector().detect(
      Uint8List.fromList(img.encodePng(buildGrid(rows: 5, addNoise: true))),
    );

    expect(result.isLocked, isTrue);
  });

  test('does not lock onto a rectangle without internal dividers', () {
    final image = img.Image(width: 640, height: 360);
    img.fill(image, color: img.ColorRgb8(8, 8, 12));
    img.drawRect(
      image,
      x1: 70,
      y1: 45,
      x2: 570,
      y2: 315,
      color: img.ColorRgb8(220, 230, 240),
      thickness: 3,
    );

    final result = const ArcBlueprintGridDetector().detect(
      Uint8List.fromList(img.encodePng(image)),
    );

    expect(result.isLocked, isFalse);
  });

  test('rejects undecodable image data', () {
    final result = const ArcBlueprintGridDetector().detect(
      Uint8List.fromList(<int>[1, 2, 3]),
    );

    expect(result.isLocked, isFalse);
    expect(result.message, contains('decode'));
  });
}
