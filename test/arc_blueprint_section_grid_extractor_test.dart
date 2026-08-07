import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_section_grid_extractor.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_grid_detection.dart';

void main() {
  test('extracts bottom rows 6–8 plus the final three slots', () {
    final image = img.Image(width: 1100, height: 520);
    img.fill(image, color: img.ColorRgb8(8, 10, 14));

    const left = 50;
    const top = 40;
    const cellWidth = 100;
    const cellHeight = 100;

    for (var row = 0; row < 4; row++) {
      final columns = row == 3 ? 3 : 10;
      for (var column = 0; column < columns; column++) {
        img.fillRect(
          image,
          x1: left + column * cellWidth + 5,
          y1: top + row * cellHeight + 5,
          x2: left + (column + 1) * cellWidth - 5,
          y2: top + (row + 1) * cellHeight - 5,
          color: img.ColorRgb8(30 + column * 15, 40 + row * 35, 100),
        );
      }
    }

    final detection = ArcBlueprintGridDetection(
      topLeft: const Offset(left / 1100, top / 520),
      topRight: const Offset((left + 1000) / 1100, top / 520),
      bottomLeft: const Offset(left / 1100, (top + 300) / 520),
      bottomRight: const Offset((left + 1000) / 1100, (top + 300) / 520),
      confidence: 0.95,
      message: 'Grid locked',
      columns: 10,
      rows: 3,
      verticalDividers: List<double>.generate(
        11,
        (index) => (left + index * cellWidth) / 1100,
      ),
      horizontalDividers: List<double>.generate(
        4,
        (index) => (top + index * cellHeight) / 520,
      ),
    );

    final bytes = const ArcBlueprintSectionGridExtractor().extract(
      imageBytes: Uint8List.fromList(img.encodePng(image)),
      detection: detection,
      section: ArcBlueprintGridSection.bottom,
    );

    final output = img.decodeImage(bytes);
    expect(output, isNotNull);
    expect(output!.width, 1000);
    expect(output.height, 400);

    final finalThirdCell = output.getPixel(250, 350);
    final emptyFourthCell = output.getPixel(350, 350);

    expect(finalThirdCell.r, greaterThan(8));
    expect(emptyFourthCell.r, lessThanOrEqualTo(12));
  });
}
