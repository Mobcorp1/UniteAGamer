import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_detector.dart';

void main() {
  test('TV fallback rejects a featureless large dark rectangle', () {
    final image = img.Image(width: 1280, height: 720);
    img.fill(image, color: img.ColorRgb8(164, 172, 178));

    img.fillRect(
      image,
      x1: 230,
      y1: 110,
      x2: 1120,
      y2: 625,
      color: img.ColorRgb8(18, 24, 42),
    );

    final result = const ArcBlueprintGridDetector(
      columns: 10,
      rows: 5,
      analysisWidth: 720,
    ).detect(Uint8List.fromList(img.encodePng(image)));

    expect(result.isLocked, isFalse, reason: result.message);
  });
}
