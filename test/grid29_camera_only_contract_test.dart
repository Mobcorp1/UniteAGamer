import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final path =
      'lib/features/trading_hub/arc_raiders/screens/arc_frozen_trail_single_grid_capture_screen.dart';

  test('Grid29: camera still must be manually aligned before recognition', () {
    final source = File(path).readAsStringSync();
    final camera = source
        .split('Future<void> _openOriginalCameraFrame() async {')[1]
        .split('Future<void> _capture(ImageSource source) async {')[0];
    expect(camera, contains('_FrozenTrailPostCaptureAlignScreen(imageBytes: image)'));
    expect(camera, contains('if (!mounted || aligned == null) return;'));
    expect(camera, contains('await _analyse(aligned, alreadyRegistered: true);'));
  });

  test('Grid29: direct PS5/gallery screenshot still uses existing locator', () {
    final source = File(path).readAsStringSync();
    final gallery = source
        .split('Future<void> _capture(ImageSource source) async {')[1]
        .split('Future<void> _analyse(Uint8List bytes,')[0];
    expect(gallery, contains('final aligned = bytes;'));
    expect(gallery, contains('await _analyse(aligned);'));
    expect(gallery, isNot(contains('alreadyRegistered: true')));
    expect(gallery, isNot(contains('_FrozenTrailPostCaptureAlignScreen')));
  });

  test('Grid29: rectified camera bytes skip second geometry crop', () {
    final source = File(path).readAsStringSync();
    final analysis = source
        .split('Future<void> _analyse(Uint8List bytes,')[1]
        .split('Future<void> _save() async {')[0];
    expect(analysis, contains('if (alreadyRegistered) {'));
    expect(analysis, contains('registeredImage = bytes;'));
    expect(analysis, contains('final located = const ArcBlueprintSingleGridLocator().locate(bytes);'));
    expect(analysis, contains('.normalizeLocatedGrid(located);'));
    expect(analysis, contains('ArcBlueprintThreeStateGridClassifier().analyze('));
  });

  test('Grid29: importing Blueprint ownership still requires user action', () {
    final source = File(path).readAsStringSync();
    final analysis = source
        .split('Future<void> _analyse(Uint8List bytes,')[1]
        .split('Future<void> _save() async {')[0];
    expect(analysis, isNot(contains('ArcBlueprintPhotoImportService().apply(')));
    final save = source.split('Future<void> _save() async {')[1];
    expect(save, contains('Confirm first Blueprint import'));
    expect(save, contains('ArcBlueprintPhotoImportService().apply('));
  });
}
