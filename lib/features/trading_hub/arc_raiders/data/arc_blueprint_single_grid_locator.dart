import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Geometric pre-registration for a single complete 17x6 ARC blueprint grid.
/// Does not classify ownership or alter recognition confidence/thresholds.
/// The 6th row contains only six cells; the other five contain 17.
class ArcBlueprintSingleGridLocator {
  const ArcBlueprintSingleGridLocator();

  Uint8List locate(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Cannot decode Blueprint grid image.');
    }
    final source = img.bakeOrientation(decoded);
    final w = source.width;
    final h = source.height;
    if (w < 340 || h < 120) {
      throw const FormatException('Blueprint screenshot is too small.');
    }

    // Identify actual BLUE blueprint tile interiors, not grey-outlined empty
    // cells, cyan app chrome or dark borders. Sample at most ~2K columns.
    final stride = math.max(1, w ~/ 1850);
    final xHits = List<int>.filled(w, 0);
    final yHits = List<int>.filled(h, 0);
    for (var y = 0; y < h; y += stride) {
      for (var x = 0; x < w; x += stride) {
        final p = source.getPixel(x, y);
        final r = p.r.toDouble();
        final g = p.g.toDouble();
        final b = p.b.toDouble();
        if (b > 65 && b > r * 1.48 && b > g * 1.14 && b - r > 34) {
          xHits[x]++;
          yHits[y]++;
        }
      }
    }
    final requiredRowHits = math.max(10, (w / stride * 0.055).round());
    final activeRows = <int>[
      for (var y = 0; y < h; y += stride)
        if (yHits[y] >= requiredRowHits) y,
    ];
    if (activeRows.length < 12) {
      throw const FormatException(
        'Cannot locate the complete blue Blueprint grid; no collection changes were made.',
      );
    }
    // Ignore sporadic highlights; find longest cluster of rows holding blue
    // cards. Real rows are separated by short black strips, never long gaps.
    var bestStart = activeRows.first;
    var bestEnd = activeRows.first;
    var runStart = activeRows.first;
    var previous = activeRows.first;
    for (final y in activeRows.skip(1)) {
      if (y - previous > math.max(14, (h * .075).round())) {
        if (previous - runStart > bestEnd - bestStart) {
          bestStart = runStart;
          bestEnd = previous;
        }
        runStart = y;
      }
      previous = y;
    }
    if (previous - runStart > bestEnd - bestStart) {
      bestStart = runStart;
      bestEnd = previous;
    }
    final ySpan = bestEnd - bestStart;
    if (ySpan < h * .12) {
      throw const FormatException(
        'Blueprint grid row alignment is incomplete.',
      );
    }
    // The blue panel omits the lower book-marker strip (about 20% of card).
    // Include that strip by extending the bottom, not by changing recognition.
    final cellPitchY = ySpan / 5.55;
    final top = math.max(0, (bestStart - cellPitchY * .12).floor());
    final bottom = math.min(h, (bestEnd + cellPitchY * .30).ceil());
    // X extent is evaluated only within confirmed grid rows; this rejects
    // stray blue UI elsewhere on screen.
    var leftBlue = w;
    var rightBlue = -1;
    final minimumColumnHits = math.max(
      2,
      ((bottom - top) / stride * .045).round(),
    );
    for (var x = 0; x < w; x += stride) {
      var count = 0;
      for (var y = top; y < bottom; y += stride) {
        final p = source.getPixel(x, y);
        final r = p.r.toDouble();
        final g = p.g.toDouble();
        final b = p.b.toDouble();
        if (b > 65 && b > r * 1.48 && b > g * 1.14 && b - r > 34) count++;
      }
      if (count >= minimumColumnHits) {
        leftBlue = math.min(leftBlue, x);
        rightBlue = math.max(rightBlue, x);
      }
    }
    if (rightBlue < leftBlue || rightBlue - leftBlue < w * .35) {
      throw const FormatException('Cannot verify all 17 Blueprint columns.');
    }
    final xPitch = (rightBlue - leftBlue) / 16.7;
    final left = math.max(0, (leftBlue - xPitch * .13).floor());
    // Keep right-hand border padding symmetrical with the left. The old
    // 0.62 pitch allowance introduced black margin beyond column 17 and
    // shifted sampled cells when the crop was normalised to 1700 pixels.
    final right = math.min(w, (rightBlue + xPitch * .13).ceil());
    if (right - left < 340 || bottom - top < 110) {
      throw const FormatException('Blueprint grid boundaries are incomplete.');
    }
    final cropped = img.copyCrop(
      source,
      x: left,
      y: top,
      width: right - left,
      height: bottom - top,
    );
    return Uint8List.fromList(img.encodeJpg(cropped, quality: 97));
  }

  /// Normalise the already isolated 17x6 grid exactly once, without another
  /// lattice fit/crop. The six-card bottom row occupies its left six slots.
  Uint8List normalizeLocatedGrid(Uint8List locatedBytes) {
    final image = img.decodeImage(locatedBytes);
    if (image == null) {
      throw const FormatException('Unable to decode located Blueprint grid.');
    }
    return Uint8List.fromList(
      img.encodeJpg(
        img.copyResize(
          image,
          width: 1700,
          height: 600,
          interpolation: img.Interpolation.cubic,
        ),
        quality: 96,
      ),
    );
  }
}
