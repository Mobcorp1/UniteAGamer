import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_pixel_analyzer.dart';

void main() {
  test('legacy pixel analyzer delegates to hybrid recognition', () {
    final image = img.Image(width: 1000, height: 500);
    img.fill(image, color: img.ColorRgb8(12, 14, 18));
    img.fillRect(
      image,
      x1: 12,
      y1: 12,
      x2: 88,
      y2: 88,
      color: img.ColorRgb8(40, 125, 190),
    );
    for (var line = 0; line < 7; line++) {
      img.drawLine(
        image,
        x1: 10,
        y1: 15 + line * 10,
        x2: 90,
        y2: 28 + line * 9,
        color: img.ColorRgb8(230, 80, 35),
        thickness: 3,
      );
    }

    final result = const ArcBlueprintPhotoPixelAnalyzer().analyze(
      bytes: Uint8List.fromList(img.encodePng(image)),
      captureId: 'top',
    );

    expect(result.succeeded, isTrue);
    expect(result.samples, hasLength(50));
    expect(result.samples.first.occupancyScore, greaterThanOrEqualTo(0.72));
    expect(result.confidence, inInclusiveRange(0.0, 1.0));
  });
}
