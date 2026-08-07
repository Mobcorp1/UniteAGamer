import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_detector.dart';

void main() {
  test('segments an exact 10 by 5 Blueprint grid from divider lines', () {
    final image = img.Image(width: 720, height: 420);
    img.fill(image, color: img.ColorRgb8(8, 8, 12));

    const left = 80;
    const top = 60;
    const cellWidth = 55;
    const cellHeight = 58;

    img.fillRect(
      image,
      x1: left,
      y1: top,
      x2: left + (cellWidth * 10),
      y2: top + (cellHeight * 5),
      color: img.ColorRgb8(28, 32, 40),
    );

    for (var column = 0; column <= 10; column++) {
      final x = left + (column * cellWidth);
      img.drawLine(
        image,
        x1: x,
        y1: top,
        x2: x,
        y2: top + (cellHeight * 5),
        color: img.ColorRgb8(220, 230, 240),
        thickness: 3,
      );
    }
    for (var row = 0; row <= 5; row++) {
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

    final result = const ArcBlueprintGridDetector().detect(
      Uint8List.fromList(img.encodePng(image)),
    );

    expect(result.isValid, isTrue);
    expect(result.hasSegmentedGrid, isTrue);
    expect(result.verticalDividers, hasLength(11));
    expect(result.horizontalDividers, hasLength(6));
    expect(result.verticalDividers.first, closeTo(left / 720, 0.03));
    expect(
      result.verticalDividers.last,
      closeTo((left + cellWidth * 10) / 720, 0.03),
    );
    expect(result.horizontalDividers.first, closeTo(top / 420, 0.03));
    expect(
      result.horizontalDividers.last,
      closeTo((top + cellHeight * 5) / 420, 0.03),
    );
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
