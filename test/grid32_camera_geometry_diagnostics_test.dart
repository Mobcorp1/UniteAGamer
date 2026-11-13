import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final file = File(
    'lib/features/trading_hub/arc_raiders/screens/'
    'arc_frozen_trail_single_grid_capture_screen.dart',
  );

  test('Grid32 instrumentation only inspects the camera route', () {
    final source = file.readAsStringSync();
    expect(source, contains('ARC GRID32 CAPTURE press'));
    expect(source, contains('ARC GRID32 CAPTURE stillReadyMs='));
    expect(source, contains('ARC GRID32 ALIGN viewport='));
    expect(source, contains('ARC GRID32 PROFILE row='));
    expect(source, contains('ARC GRID32 PROFILE col='));
    expect(source, contains('ARC GRID32 FLOW endToEndMs='));
    expect(source, contains('if (kDebugMode && alreadyRegistered)'));
    expect(source, contains('await compute(_grid32GeometryProbe, registeredImage)'));
    expect(source, contains('_showSamplingOverlay = false;'));
  });

  test('Grid30 screenshot route and camera import protection still exist', () {
    final source = file.readAsStringSync();
    final gallery = source
        .split('Future<void> _capture(ImageSource source) async {')[1]
        .split('Future<void> _analyse(')[0];
    expect(gallery, contains('await _analyse(aligned);'));
    expect(gallery, isNot(contains('alreadyRegistered: true')));
    expect(source, contains('if (alreadyRegistered) {'));
    expect(source, contains('samples: reviewedSamples'));
    expect(source, contains('darkReviewSlots.isNotEmpty'));
    expect(source, contains('ArcBlueprintPhotoImportService().apply('));
    expect(source, contains('ArcBlueprintEdgeCropOverlay('));
    expect(source, isNot(contains('ArcBlueprintCameraQuadRectifier')));
  });
}
