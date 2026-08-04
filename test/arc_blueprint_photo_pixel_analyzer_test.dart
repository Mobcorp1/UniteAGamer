import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_pixel_analyzer.dart';

void main() {
  test('pixel analyzer returns one sample per fixed grid cell', () {
    final image = img.Image(width: 1000, height: 500);
    img.fill(image, color: img.ColorRgb8(18, 20, 24));
    for (var row = 0; row < 5; row++) {
      for (var column = 0; column < 10; column += 2) {
        img.fillRect(
          image,
          x1: column * 100 + 12,
          y1: row * 100 + 12,
          x2: column * 100 + 88,
          y2: row * 100 + 88,
          color: img.ColorRgb8(30 + row * 20, 120, 210 - row * 15),
        );
      }
    }

    final result = const ArcBlueprintPhotoPixelAnalyzer().analyze(
      bytes: img.encodePng(image),
      captureId: 'top',
    );

    expect(result.succeeded, isTrue);
    expect(result.samples, hasLength(50));
    expect(result.samples.every((sample) => sample.captureId == 'top'), isTrue);
    expect(
      result.samples.every(
        (sample) => sample.occupancyScore >= 0 && sample.occupancyScore <= 1,
      ),
      isTrue,
    );
  });

  test('pixel analyzer rejects undecodable image bytes', () {
    final result = const ArcBlueprintPhotoPixelAnalyzer().analyze(
      bytes: Uint8List.fromList(const [1, 2, 3]),
      captureId: 'top',
    );
    expect(result.succeeded, isFalse);
    expect(result.error, isNotEmpty);
  });
}
