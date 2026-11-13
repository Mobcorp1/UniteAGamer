import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_photo_occupancy_engine.dart';

/// Conservative camera-only second opinion for predominantly dark card faces.
/// This does not make any cell owned or missing: a questionable *owned* result
/// becomes uncertain and must be reviewed. Never apply to gallery screenshots.
class ArcBlueprintCameraDarkCellGuard {
  const ArcBlueprintCameraDarkCellGuard();

  /// Candidate rule tested on a single real camera diagnostic from 12 October.
  /// The thresholds are conservative, not evidence of general camera accuracy.
  static bool needsReview({
    required double occupancyScore,
    required double darkFraction,
    required int darkRegions,
  }) =>
      occupancyScore >= 0.9 && darkFraction >= 0.65 && darkRegions >= 2;

  List<ArcBlueprintPhotoOccupancySample> review(
    Uint8List registeredImage,
    List<ArcBlueprintPhotoOccupancySample> samples,
  ) {
    final image = img.decodeImage(registeredImage);
    if (image == null || image.width != 1700 || image.height != 600) {
      throw const FormatException('Camera grid must be aligned to 1700x600.');
    }
    final reviewed = <ArcBlueprintPhotoOccupancySample>[];
    for (final sample in samples) {
      if (sample.occupancyScore < 0.9) {
        reviewed.add(sample);
        continue;
      }
      final row = sample.rowIndex;
      final col = sample.columnIndex;
      if (row < 0 || row >= 6 || col < 0 || col >= (row == 5 ? 6 : 17)) {
        throw const FormatException('Camera sample is outside the physical grid.');
      }
      final regionDark = <int>[0, 0, 0, 0];
      final regionTotal = <int>[0, 0, 0, 0];
      var darks = 0;
      var count = 0;
      // Exactly the classifier's sampling rectangle, pitch and dark predicate.
      for (var y = row * 100 + 14; y < row * 100 + 76; y += 3) {
        for (var x = col * 100 + 12; x < col * 100 + 88; x += 3) {
          final p = image.getPixel(x, y);
          final region = ((y - row * 100) >= 45 ? 2 : 0) +
              ((x - col * 100) >= 50 ? 1 : 0);
          regionTotal[region]++;
          if (p.r < 43 && p.g < 49 && p.b < 59) {
            darks++;
            regionDark[region]++;
          }
          count++;
        }
      }
      final fraction = darks / count;
      var darkRegions = 0;
      for (var region = 0; region < 4; region++) {
        if (regionTotal[region] > 0 &&
            regionDark[region] / regionTotal[region] >= 0.70) {
          darkRegions++;
        }
      }
      if (!needsReview(
        occupancyScore: sample.occupancyScore,
        darkFraction: fraction,
        darkRegions: darkRegions,
      )) {
        reviewed.add(sample);
        continue;
      }
      debugPrint(
        'ARC GRID31 DARK_REVIEW row=${row + 1} col=${col + 1} '
        'slot=${row * 17 + col + 1} '
        'dark=${(fraction * 100).toStringAsFixed(1)} '
        'darkRegions=$darkRegions prior=${sample.occupancyScore.toStringAsFixed(2)}',
      );
      reviewed.add(ArcBlueprintPhotoOccupancySample(
        captureId: sample.captureId,
        rowIndex: row,
        columnIndex: col,
        occupancyScore: 0.50,
      ));
    }
    return reviewed;
  }
}
