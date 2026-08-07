import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_pixel_analyzer.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_canonical_grid.dart';

void main() {
  test('pixel analyzer returns exactly 50 grid samples', () {
    final image = img.Image(width: 1000, height: 500);
    img.fill(image, color: img.ColorRgb8(15, 17, 20));

    final result = const ArcBlueprintPhotoPixelAnalyzer().analyze(
      bytes: Uint8List.fromList(img.encodePng(image)),
      captureId: 'top',
    );

    expect(result.succeeded, isTrue);
    expect(result.samples, hasLength(50));
    expect(result.samples.every((sample) => sample.captureId == 'top'), isTrue);
  });

  test('pixel analyzer does not invent owned cells on an empty image', () {
    final image = img.Image(width: 1000, height: 500);
    img.fill(image, color: img.ColorRgb8(18, 19, 21));

    final result = const ArcBlueprintPhotoPixelAnalyzer().analyze(
      bytes: Uint8List.fromList(img.encodePng(image)),
      captureId: 'empty',
    );

    expect(
      result.samples.where((sample) => sample.occupancyScore >= 0.72),
      isEmpty,
    );
  });

  test('bottom pixel analyzer returns exactly 33 real samples', () {
    final image = img.Image(width: 1000, height: 400);
    img.fill(image, color: img.ColorRgb8(15, 17, 20));

    final result =
        const ArcBlueprintPhotoPixelAnalyzer(
          columns: 10,
          rows: 4,
          validColumnCountsByRow:
              ArcBlueprintCanonicalGrid.bottomRowColumnCounts,
        ).analyze(
          bytes: Uint8List.fromList(img.encodePng(image)),
          captureId: 'bottom',
        );

    expect(result.succeeded, isTrue);
    expect(result.samples, hasLength(33));
    expect(
      result.samples.where(
        (sample) => sample.rowIndex == 3 && sample.columnIndex > 2,
      ),
      isEmpty,
    );
  });

  test('pixel analyzer rejects undecodable bytes', () {
    final result = const ArcBlueprintPhotoPixelAnalyzer().analyze(
      bytes: Uint8List.fromList(const <int>[1, 2, 3]),
      captureId: 'bad',
    );

    expect(result.succeeded, isFalse);
    expect(result.error, isNotEmpty);
  });

  test('pixel analyzer rejects images too small for the grid', () {
    final image = img.Image(width: 50, height: 30);

    final result = const ArcBlueprintPhotoPixelAnalyzer().analyze(
      bytes: Uint8List.fromList(img.encodePng(image)),
      captureId: 'small',
    );

    expect(result.succeeded, isFalse);
    expect(result.error, contains('too small'));
  });
}
