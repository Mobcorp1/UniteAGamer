import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_camera_dark_cell_guard.dart';

void main() {
  test('real 20:35 camera diagnostic: dark-face guard reviews six risky owned results', () {
    // Observations from an actual photographed TV, not a synthetic grid.
    // Fixture is log metrics; actual captured still pixels were not available.
    // These assertions do not claim camera recognition is proven accurate.
    final lines = File('test/fixtures/grid31_camera_audit_203626.txt')
        .readAsLinesSync();
    final pattern = RegExp(
      r'ARC GRID24 CELL row=(\d+) col=(\d+) slot=(\d+) '
      r'blue=([\d.]+) bright=([\d.]+) dark=([\d.]+) '
      r'darkRegions=(\d+) score=([\d.]+)',
    );
    var total = 0;
    var originalOwned = 0;
    var retainedOwned = 0;
    final flagged = <int>[];
    for (final line in lines) {
      final match = pattern.firstMatch(line);
      if (match == null) continue;
      total++;
      final slot = int.parse(match.group(3)!);
      final score = double.parse(match.group(8)!);
      if (score < 0.9) continue;
      originalOwned++;
      final flag = ArcBlueprintCameraDarkCellGuard.needsReview(
        occupancyScore: score,
        darkFraction: double.parse(match.group(6)!) / 100,
        darkRegions: int.parse(match.group(7)!),
      );
      if (flag) {
        flagged.add(slot);
      } else {
        retainedOwned++;
      }
    }
    expect(total, 91);
    expect(originalOwned, 89);
    // Expected bad cells in this one reference photo only, NEVER in app logic.
    expect(flagged, [2, 9, 38, 55, 60, 89]);
    expect(retainedOwned, 83);
  });

  test('camera-only check cannot promote uncertain or missing cards to owned', () {
    for (final score in <double>[0.03, 0.50]) {
      expect(
        ArcBlueprintCameraDarkCellGuard.needsReview(
          occupancyScore: score,
          darkFraction: 0.95,
          darkRegions: 4,
        ),
        isFalse,
      );
    }
  });

  test('dark-looking genuine card is not rejected merely for low blue', () {
    expect(
      ArcBlueprintCameraDarkCellGuard.needsReview(
        occupancyScore: 0.96,
        darkFraction: 0.53,
        darkRegions: 2,
      ),
      isFalse,
    );
  });

  test('gallery route and ownership save block retain their previous code', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/'
      'arc_frozen_trail_single_grid_capture_screen.dart',
    ).readAsStringSync();
    final gallery = source
        .split('Future<void> _capture(ImageSource source) async {')[1]
        .split('Future<void> _analyse(')[0];
    expect(gallery, contains('await _analyse(aligned);'));
    expect(gallery, isNot(contains('alreadyRegistered: true')));
    final gate = source.split('Future<void> _save() async {')[1];
    expect(gate, contains('ArcBlueprintPhotoImportService().apply('));
    expect(source, contains('if (alreadyRegistered) {'));
    expect(source, contains('samples: reviewedSamples'));
    expect(source, contains('ARC GRID31 TIMING shutterToStillMs='));
    expect(source, contains('grid31-toggle-sampling-overlay'));
  });
}
