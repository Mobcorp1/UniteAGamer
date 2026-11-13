import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_hybrid_recognition_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_canonical_grid.dart';

void main() {
  test('blank grid never creates owned Blueprints', () {
    final image = img.Image(width: 1000, height: 500);
    img.fill(image, color: img.ColorRgb8(18, 19, 21));

    final result = const ArcBlueprintHybridRecognitionEngine().analyze(
      bytes: Uint8List.fromList(img.encodePng(image)),
      captureId: 'blank',
    );

    expect(result.succeeded, isTrue);
    expect(result.samples, hasLength(50));
    expect(
      result.samples.where((sample) => sample.occupancyScore >= 0.72),
      isEmpty,
    );
  });

  test('decisive primary artwork remains occupied', () {
    final image = img.Image(width: 1000, height: 500);
    img.fill(image, color: img.ColorRgb8(14, 16, 20));
    img.fillRect(
      image,
      x1: 10,
      y1: 10,
      x2: 90,
      y2: 90,
      color: img.ColorRgb8(40, 115, 185),
    );
    for (var line = 0; line < 8; line++) {
      img.drawLine(
        image,
        x1: 8,
        y1: 12 + line * 10,
        x2: 92,
        y2: 26 + line * 9,
        color: img.ColorRgb8(230, 82, 38),
        thickness: 3,
      );
    }

    final result = const ArcBlueprintHybridRecognitionEngine().analyze(
      bytes: Uint8List.fromList(img.encodePng(image)),
      captureId: 'top',
    );

    expect(result.samples.first.occupancyScore, greaterThanOrEqualTo(0.72));
  });

  test('uncertain cells use fallback without changing neighbours', () {
    final image = img.Image(width: 1000, height: 500);
    img.fill(image, color: img.ColorRgb8(15, 17, 20));
    img.fillRect(
      image,
      x1: 2,
      y1: 105,
      x2: 86,
      y2: 194,
      color: img.ColorRgb8(42, 118, 188),
    );
    for (var line = 0; line < 7; line++) {
      img.drawLine(
        image,
        x1: 0,
        y1: 110 + line * 10,
        x2: 84,
        y2: 124 + line * 9,
        color: img.ColorRgb8(230, 82, 38),
        thickness: 3,
      );
    }

    final result = const ArcBlueprintHybridRecognitionEngine().analyze(
      bytes: Uint8List.fromList(img.encodePng(image)),
      captureId: 'edge',
    );

    expect(result.samples[10].occupancyScore, greaterThanOrEqualTo(0.72));
    expect(result.samples[11].occupancyScore, lessThanOrEqualTo(0.28));
  });

  test('bottom layout returns 33 samples without final-row filler cells', () {
    final image = img.Image(width: 1000, height: 400);
    img.fill(image, color: img.ColorRgb8(18, 19, 21));

    final result =
        const ArcBlueprintHybridRecognitionEngine(
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

  test('rejects undecodable bytes', () {
    final result = const ArcBlueprintHybridRecognitionEngine().analyze(
      bytes: Uint8List.fromList(const <int>[1, 2, 3]),
      captureId: 'bad',
    );
    expect(result.succeeded, isFalse);
    expect(result.error, isNotEmpty);
  });
}
