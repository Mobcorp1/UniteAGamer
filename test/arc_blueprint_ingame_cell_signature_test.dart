import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_pixel_analyzer.dart';

void main() {
  test('dark saturated navy cells are not promoted to owned', () {
    final image = img.Image(width: 1000, height: 500);
    img.fill(image, color: img.ColorRgb8(8, 22, 64));

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x += 7) {
        if ((x + y) % 41 == 0) {
          image.setPixelRgb(x, y, 28, 48, 88);
        }
      }
    }

    final result = const ArcBlueprintPhotoPixelAnalyzer().analyze(
      bytes: Uint8List.fromList(img.encodePng(image)),
      captureId: 'navy-empty',
    );

    expect(result.succeeded, isTrue);
    expect(
      result.samples.where((sample) => sample.occupancyScore >= 0.84),
      isEmpty,
    );
  });

  test('electric-blue technical grid plus bright icon is owned', () {
    final image = img.Image(width: 1000, height: 500);
    img.fill(image, color: img.ColorRgb8(7, 16, 44));

    for (var y = 5; y < 95; y++) {
      for (var x = 5; x < 95; x++) {
        image.setPixelRgb(x, y, 8, 66, 182);
      }
    }
    for (var p = 10; p < 90; p += 10) {
      for (var x = 7; x < 93; x++) {
        image.setPixelRgb(x, p, 25, 125, 255);
      }
      for (var y = 7; y < 93; y++) {
        image.setPixelRgb(p, y, 25, 125, 255);
      }
    }
    for (var y = 30; y < 70; y++) {
      for (var x = 35; x < 65; x++) {
        image.setPixelRgb(x, y, 225, 235, 245);
      }
    }

    final result = const ArcBlueprintPhotoPixelAnalyzer().analyze(
      bytes: Uint8List.fromList(img.encodePng(image)),
      captureId: 'owned-grid',
    );

    expect(result.succeeded, isTrue);
    expect(result.samples.first.occupancyScore, greaterThanOrEqualTo(0.84));
    expect(
      result.samples.skip(1).where((sample) => sample.occupancyScore >= 0.84),
      isEmpty,
    );
  });
}
