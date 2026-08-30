import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_grid_detector.dart';

void main() {
  test('TV panel fallback locks a large dark Blueprint-style panel', () {
    final image = img.Image(width: 1280, height: 720);
    img.fill(image, color: img.ColorRgb8(164, 172, 178));

    // Synthetic perspective-like dark/navy panel. Only a subset of internal
    // Blueprint divider evidence is drawn and a bright glare band erases part
    // of it. The strict full-grid path should not be required, but the TV-panel
    // fallback still has evidence that this is a grid rather than a rectangle.
    for (var y = 120; y <= 620; y++) {
      final t = (y - 120) / 500;
      final left = (250 + (35 * t)).round();
      final right = (1120 - (20 * t)).round();
      for (var x = left; x <= right; x++) {
        image.setPixel(x, y, img.ColorRgb8(18, 24, 42));
      }
    }

    // Partial internal vertical dividers. These follow the panel perspective
    // but intentionally omit several columns.
    for (final column in <int>[2, 4, 6, 8]) {
      for (var y = 230; y <= 560; y++) {
        if (y >= 330 && y <= 410) continue; // simulated reflection/glare
        final t = (y - 120) / 500;
        final left = 250 + (35 * t);
        final right = 1120 - (20 * t);
        final gridLeft = left + ((right - left) * 0.065);
        final gridRight = left + ((right - left) * 0.945);
        final x = (gridLeft + ((gridRight - gridLeft) * column / 10)).round();
        image.setPixel(x, y, img.ColorRgb8(108, 132, 152));
        if (x + 1 < image.width) {
          image.setPixel(x + 1, y, img.ColorRgb8(82, 108, 132));
        }
      }
    }

    // One horizontal divider provides an independent grid cue.
    for (var x = 330; x <= 1010; x++) {
      image.setPixel(x, 430, img.ColorRgb8(94, 118, 142));
    }

    // Bright reflection across the panel: divider evidence must tolerate this
    // rather than demanding a pristine synthetic screenshot.
    img.fillRect(
      image,
      x1: 470,
      y1: 330,
      x2: 790,
      y2: 410,
      color: img.ColorRgb8(118, 126, 136),
    );

    final result = const ArcBlueprintGridDetector(
      columns: 10,
      rows: 5,
      analysisWidth: 720,
    ).detectImage(image);

    expect(result.isValid, isTrue, reason: result.message);
    expect(
      result.message,
      anyOf(
        equals('Grid locked'),
        contains('TV Blueprint panel'),
        contains('verified internal evidence'),
        contains('verified regular spacing'),
      ),
    );
    expect(result.columns, 10);
    expect(result.rows, 5);
    expect(result.verticalDividers, hasLength(11));
    expect(result.horizontalDividers, hasLength(6));
  });
}
