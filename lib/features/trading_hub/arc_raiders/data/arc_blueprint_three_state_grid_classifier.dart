import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';

/// Empty-first classification for a pre-aligned 17x6 grid. Unknown cells remain
/// uncertain, never inferred as owned simply because they are not black.
class ArcBlueprintThreeStateGridClassifier {
  const ArcBlueprintThreeStateGridClassifier();

  List<ArcBlueprintPhotoOccupancySample> analyze(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null || image.width != 1700 || image.height != 600) {
      throw const FormatException('Aligned Blueprint grid must be 1700x600.');
    }
    final result = <ArcBlueprintPhotoOccupancySample>[];
    for (var row = 0; row < 6; row++) {
      for (var col = 0; col < (row == 5 ? 6 : 17); col++) {
        var blues = 0;
        var brightMarks = 0;
        var darks = 0;
        var count = 0;
        final regionDark = <int>[0, 0, 0, 0];
        final regionTotal = <int>[0, 0, 0, 0];
        // Ignore the border and use the actual card face, not the surrounding
        // black or the fixed 20% footer. Bright white artwork and grid marks
        // count as supporting evidence, not mandatory matching templates.
        for (var y = row * 100 + 14; y < row * 100 + 76; y += 3) {
          for (var x = col * 100 + 12; x < col * 100 + 88; x += 3) {
            final pixel = image.getPixel(x, y);
            final r = pixel.r.toDouble();
            final g = pixel.g.toDouble();
            final b = pixel.b.toDouble();
            if (b > 48 && b > r * 1.28 && b > g * 1.06 && b - r > 17) {
              blues++;
            }
            if (r > 140 && g > 145 && b > 155) brightMarks++;
            final region =
                ((y - row * 100) >= 45 ? 2 : 0) +
                ((x - col * 100) >= 50 ? 1 : 0);
            regionTotal[region]++;
            if (r < 43 && g < 49 && b < 59) {
              darks++;
              regionDark[region]++;
            }
            count++;
          }
        }
        final blue = blues / count;
        final bright = brightMarks / count;
        final dark = darks / count;
        // A missing card should be predominantly dark across its face,
        // rather than only in one misaligned black edge or glare shadow.
        final darkRegions = List<int>.generate(
          4,
          (i) => regionTotal[i] == 0
              ? 0
              : (regionDark[i] / regionTotal[i] >= 0.70 ? 1 : 0),
        ).fold<int>(0, (sum, value) => sum + value);
        // Three states: visibly unowned black, visibly occupied blue, or
        // uncertain. The two positive tests must agree for moderate blue.
        final score =
            blue < 0.035 && bright < 0.055 && dark > 0.76 && darkRegions >= 3
            ? 0.03
            : blue >= 0.27 || (blue >= 0.12 && bright >= 0.018)
            ? 0.96
            : 0.50;
        // Cell-level diagnostics are deliberately emitted before catalogue
        // mapping so even currently unmapped slots remain visible.
        // Values are percentages, rounded only for the log, not classification.
        assert(() {
          // ignore: avoid_print
          print(
            'ARC GRID24 CELL row=${row + 1} col=${col + 1} '
            'slot=${row * 17 + col + 1} '
            'blue=${(blue * 100).toStringAsFixed(1)} '
            'bright=${(bright * 100).toStringAsFixed(1)} '
            'dark=${(dark * 100).toStringAsFixed(1)} darkRegions=$darkRegions '
            'score=${score.toStringAsFixed(2)}',
          );
          return true;
        }());
        result.add(
          ArcBlueprintPhotoOccupancySample(
            captureId: 'full-grid',
            rowIndex: row,
            columnIndex: col,
            occupancyScore: score,
          ),
        );
      }
    }
    return result;
  }
}
