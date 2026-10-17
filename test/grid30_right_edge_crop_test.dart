import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_single_grid_locator.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_blueprint_three_state_grid_classifier.dart';

void main() {
  test('PS5 reference grid has symmetric right-edge crop and 83 owned cards', () {
    // This is the user's real 83/91 PS5 screenshot, trimmed to remove the HUD
    // and player identifier. It is evidence for this fixture, not a claim
    // about accuracy on arbitrary screenshots or photographed displays.
    final bytes = File('test/fixtures/grid30_ps5_grid_only.png').readAsBytesSync();
    const locator = ArcBlueprintSingleGridLocator();
    final located = locator.locate(bytes);
    final cropped = img.decodeImage(located);
    expect(cropped, isNotNull);
    // On this image, leftBlue=52, rightBlue=1919, xPitch=1867/16.7;
    // symmetric padding yields roughly [37,1934), width 1897.
    // Allow a few pixels of decoder variation; old width=1952 must fail.
    expect(cropped!.width, inInclusiveRange(1880, 1920));
    final registered = locator.normalizeLocatedGrid(located);
    final samples = const ArcBlueprintThreeStateGridClassifier().analyze(registered);
    expect(samples, hasLength(91));

    // User-confirmed occupied column-17 cells. Classification must follow
    // actual colour evidence, never identity or a hard-coded owned-slot list.
    expect(samples[16].occupancyScore, 0.96, reason: 'row 1 col 17');
    expect(samples[33].occupancyScore, 0.96, reason: 'row 2 col 17');

    // Eight visibly black cells in THIS reference screenshot.
    for (final slot in <int>[2, 9, 38, 55, 60, 62, 87, 89]) {
      expect(samples[slot - 1].occupancyScore, 0.03,
          reason: 'reference black slot $slot');
    }
    expect(samples.where((s) => s.occupancyScore == 0.96), hasLength(83));
    expect(samples.where((s) => s.occupancyScore == 0.03), hasLength(8));
    expect(samples.where((s) => s.occupancyScore == 0.50), isEmpty);
  });
}
