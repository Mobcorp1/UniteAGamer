import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_segmented_grid_extractor.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

void main() {
  test('extracts every detected cell into a rigid 10 by 5 mosaic', () {
    final image = img.Image(width: 1100, height: 600);
    img.fill(image, color: img.ColorRgb8(5, 5, 8));

    const left = 50;
    const top = 50;
    const cellWidth = 100;
    const cellHeight = 100;

    for (var row = 0; row < 5; row++) {
      for (var column = 0; column < 10; column++) {
        img.fillRect(
          image,
          x1: left + column * cellWidth + 4,
          y1: top + row * cellHeight + 4,
          x2: left + (column + 1) * cellWidth - 4,
          y2: top + (row + 1) * cellHeight - 4,
          color: img.ColorRgb8(
            20 + column * 18,
            30 + row * 35,
            90 + ((row + column) % 4) * 30,
          ),
        );
      }
    }

    final detection = ArcBlueprintGridDetection(
      topLeft: const Offset(left / 1100, top / 600),
      topRight: const Offset((left + 1000) / 1100, top / 600),
      bottomLeft: const Offset(left / 1100, (top + 500) / 600),
      bottomRight: const Offset((left + 1000) / 1100, (top + 500) / 600),
      confidence: 0.95,
      message: 'Grid locked',
      verticalDividers: List<double>.generate(
        11,
        (index) => (left + index * cellWidth) / 1100,
      ),
      horizontalDividers: List<double>.generate(
        6,
        (index) => (top + index * cellHeight) / 600,
      ),
    );

    final result = const ArcBlueprintSegmentedGridExtractor().extract(
      imageBytes: Uint8List.fromList(img.encodePng(image)),
      detection: detection,
    );

    final decoded = img.decodeImage(result);
    expect(decoded, isNotNull);
    expect(decoded!.width, 1000);
    expect(decoded.height, 500);

    final first = decoded.getPixel(50, 50);
    final last = decoded.getPixel(950, 450);
    expect(first.r, isNot(equals(last.r)));
    expect(first.g, isNot(equals(last.g)));
  });

  test('rejects incomplete divider geometry', () {
    final image = img.Image(width: 1000, height: 500);
    expect(
      () => const ArcBlueprintSegmentedGridExtractor().extract(
        imageBytes: Uint8List.fromList(img.encodePng(image)),
        detection: const ArcBlueprintGridDetection(
          topLeft: Offset(0.1, 0.1),
          topRight: Offset(0.9, 0.1),
          bottomLeft: Offset(0.1, 0.9),
          bottomRight: Offset(0.9, 0.9),
          confidence: 0.9,
          message: 'Incomplete',
        ),
      ),
      throwsFormatException,
    );
  });
}
