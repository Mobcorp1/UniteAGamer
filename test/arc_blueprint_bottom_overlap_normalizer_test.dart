import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_bottom_overlap_normalizer.dart';

Uint8List buildFiveRows() {
  final image = img.Image(width: 1000, height: 500);
  final colours = <img.ColorRgb8>[
    img.ColorRgb8(255, 0, 0),
    img.ColorRgb8(0, 255, 0),
    img.ColorRgb8(0, 0, 255),
    img.ColorRgb8(255, 255, 0),
    img.ColorRgb8(255, 0, 255),
  ];

  for (var row = 0; row < 5; row++) {
    for (var y = row * 100; y < (row + 1) * 100; y++) {
      for (var x = 0; x < 1000; x++) {
        image.setPixel(x, y, colours[row]);
      }
    }
  }

  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  test('removes exactly one registered overlap row', () {
    const normalizer = ArcBlueprintBottomOverlapNormalizer();

    final result = normalizer.removeRegisteredOverlap(buildFiveRows());
    final decoded = img.decodeImage(result);

    expect(decoded, isNotNull);
    expect(decoded!.width, 1000);
    expect(decoded.height, 400);

    final first = decoded.getPixel(500, 50);
    expect(first.g, greaterThan(first.r));
    expect(first.g, greaterThan(first.b));

    final last = decoded.getPixel(500, 350);
    expect(last.r, greaterThan(last.g));
    expect(last.b, greaterThan(last.g));
  });
}
