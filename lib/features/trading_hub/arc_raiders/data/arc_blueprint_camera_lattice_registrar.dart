import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Camera-only periodic 17x6 grid registration.
///
/// Uses the repeating *card / dark gap* structure in the photographed image,
/// rather than assuming that every blueprint slot is blue or relying on a
/// catalogue of which cells a particular player owns.
///
/// The caller has already applied the cyan crop. This is the final geometry
/// stage before the established three-state classifier. A failed registration
/// refuses the scan rather than producing misleading ownership evidence.
/// Gallery/console screenshot imports must NOT use this class.
class ArcBlueprintCameraLatticeRegistrar {
  const ArcBlueprintCameraLatticeRegistrar();

  static const int outputWidth = 1700;
  static const int outputHeight = 600;

  ArcBlueprintCameraLatticeRegistration register(Uint8List alignedBytes) {
    final decoded = img.decodeImage(alignedBytes);
    if (decoded == null) {
      throw const FormatException('Could not decode the aligned camera image.');
    }
    final oriented = img.bakeOrientation(decoded);
    final working = oriented.width == outputWidth &&
            oriented.height == outputHeight
        ? oriented
        : img.copyResize(oriented, width: outputWidth, height: outputHeight);

    // The first five rows span all 17 columns. The final row has only six
    // cells, so a whole-image column average would bias the right edge dark.
    // Similarly the first six columns appear in all six rows; use those
    // columns for the horizontal row-gap profile.
    final colProfile = <double>[];
    for (var x = 0; x < outputWidth; x += 2) {
      var evidence = 0;
      var samples = 0;
      for (var y = 16; y < 480; y += 6) {
        if (_isCardForeground(working.getPixel(x, y))) evidence++;
        samples++;
      }
      colProfile.add(evidence / samples);
    }
    final rowProfile = <double>[];
    for (var y = 0; y < outputHeight; y += 2) {
      var evidence = 0;
      var samples = 0;
      for (var x = 20; x < 610; x += 7) {
        if (_isCardForeground(working.getPixel(x, y))) evidence++;
        samples++;
      }
      rowProfile.add(evidence / samples);
    }

    final xFit = _fitAxis(
      colProfile,
      dimension: outputWidth,
      count: 17,
      minPitch: 86,
      maxPitch: 104,
      maxOrigin: 72,
    );
    final yFit = _fitAxis(
      rowProfile,
      dimension: outputHeight,
      count: 6,
      minPitch: 82,
      maxPitch: 102,
      maxOrigin: 60,
    );

    debugPrint(
      'ARC GRID34 LATTICE x0=${xFit.origin.toStringAsFixed(1)} '
      'pitchX=${xFit.pitch.toStringAsFixed(1)} '
      'scoreX=${xFit.score.toStringAsFixed(3)} '
      'y0=${yFit.origin.toStringAsFixed(1)} '
      'pitchY=${yFit.pitch.toStringAsFixed(1)} '
      'scoreY=${yFit.score.toStringAsFixed(3)}',
    );

    // A photograph with no discernible 17x6 gaps cannot be trusted.  The
    // quality check is intentionally conservative and independent of the
    // current user's ownership count. Never fall through to an import.
    if (xFit.score < 0.13 || yFit.score < 0.12 ||
        xFit.inside <= xFit.gap + 0.13 ||
        yFit.inside <= yFit.gap + 0.12) {
      throw const FormatException(
        'The camera could not reliably locate all Blueprint card gaps. '
        'Retake the photo more square-on or adjust the cyan frame.',
      );
    }

    final left = xFit.origin.round();
    final top = yFit.origin.round();
    final cropWidth = (xFit.pitch * 17).round();
    final cropHeight = (yFit.pitch * 6).round();
    if (left < 0 || top < 0 || cropWidth <= 0 || cropHeight <= 0 ||
        left + cropWidth > outputWidth ||
        top + cropHeight > outputHeight) {
      throw const FormatException(
        'The complete 17-column, six-row grid does not fit in the photograph.',
      );
    }

    final cropped = img.copyCrop(
      working,
      x: left,
      y: top,
      width: cropWidth,
      height: cropHeight,
    );
    final registered = img.copyResize(
      cropped,
      width: outputWidth,
      height: outputHeight,
    );
    return ArcBlueprintCameraLatticeRegistration(
      bytes: Uint8List.fromList(img.encodeJpg(registered, quality: 97)),
      left: left,
      top: top,
      sourceWidth: cropWidth,
      sourceHeight: cropHeight,
      columnPitch: xFit.pitch,
      rowPitch: yFit.pitch,
      columnScore: xFit.score,
      rowScore: yFit.score,
    );
  }

  bool _isCardForeground(img.Pixel pixel) {
    final r = pixel.r.toDouble();
    final g = pixel.g.toDouble();
    final b = pixel.b.toDouble();
    final blue = b > 46 && b > r * 1.14 && b > g * 1.02 && b - r > 9;
    // Neutral bright card outlines remain visible even for empty cards.
    final lightFrame = r > 67 && g > 75 && b > 78;
    return blue || lightFrame;
  }

  _Grid34AxisFit _fitAxis(
    List<double> profile, {
    required int dimension,
    required int count,
    required int minPitch,
    required int maxPitch,
    required int maxOrigin,
  }) {
    var best = const _Grid34AxisFit(
      origin: 0,
      pitch: 100,
      score: -100,
      inside: 0,
      gap: 0,
    );
    for (var pitchStep = minPitch * 2; pitchStep <= maxPitch * 2;
        pitchStep++) {
      final pitch = pitchStep / 2;
      for (var origin = 0; origin <= maxOrigin; origin += 2) {
        if (origin + count * pitch > dimension) continue;
        var insideTotal = 0.0;
        var gapTotal = 0.0;
        for (var cell = 0; cell < count; cell++) {
          final start = origin + cell * pitch;
          insideTotal += _profileAt(profile, start + pitch * .24);
          insideTotal += _profileAt(profile, start + pitch * .44);
          insideTotal += _profileAt(profile, start + pitch * .64);
          // The end-of-card separator exists for all cells except the last.
          if (cell < count - 1) {
            gapTotal += _profileAt(profile, start + pitch * .92);
            gapTotal += _profileAt(profile, start + pitch * .97);
          }
        }
        final inside = insideTotal / (count * 3);
        final gap = gapTotal / ((count - 1) * 2);
        final score = inside - gap;
        // Tie-break near 100px pitch. The source cropper already targets
        // 100px/card; this only discourages false short-period matches.
        final weightedScore = score - (pitch - 100).abs() * .0015;
        if (weightedScore >
            best.score - (best.pitch - 100).abs() * .0015) {
          best = _Grid34AxisFit(
            origin: origin.toDouble(),
            pitch: pitch,
            score: score,
            inside: inside,
            gap: gap,
          );
        }
      }
    }
    return best;
  }

  double _profileAt(List<double> profile, double position) {
    final index = (position / 2).round();
    if (index < 0 || index >= profile.length) return 0;
    var sum = 0.0;
    var count = 0;
    for (var delta = -1; delta <= 1; delta++) {
      final candidate = index + delta;
      if (candidate < 0 || candidate >= profile.length) continue;
      sum += profile[candidate];
      count++;
    }
    return sum / count;
  }
}

class ArcBlueprintCameraLatticeRegistration {
  const ArcBlueprintCameraLatticeRegistration({
    required this.bytes,
    required this.left,
    required this.top,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.columnPitch,
    required this.rowPitch,
    required this.columnScore,
    required this.rowScore,
  });

  final Uint8List bytes;
  final int left;
  final int top;
  final int sourceWidth;
  final int sourceHeight;
  final double columnPitch;
  final double rowPitch;
  final double columnScore;
  final double rowScore;
}

class _Grid34AxisFit {
  const _Grid34AxisFit({
    required this.origin,
    required this.pitch,
    required this.score,
    required this.inside,
    required this.gap,
  });

  final double origin;
  final double pitch;
  final double score;
  final double inside;
  final double gap;
}
