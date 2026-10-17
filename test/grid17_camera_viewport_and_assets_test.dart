import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clean camera preview and separate saved still alignment are both registered', () {
    final source = File('lib/features/trading_hub/arc_raiders/screens/arc_frozen_trail_single_grid_capture_screen.dart').readAsStringSync();
    expect(source, contains('grid35-clean-camera-preview'));
    expect(source, contains('CameraPreview(controller)'));
    expect(source, contains('grid35-expanded-alignment-photo'));
    expect(source, contains('ArcBlueprintEdgeCropOverlay('));
    expect(source, contains('automaticUpdateBlockReason('));
    expect(source, contains('Update Blueprint Collection'));
  });
  test('reference WebPs exist and pubspec registers blueprint folder', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/arc_raiders/blueprints/'));
    for (final name in [
      'banjo',
      'stiletto',
      'advanced-camera',
      'emperor-gateway-conduit',
    ]) {
      expect(
        File('assets/arc_raiders/blueprints/$name.webp').existsSync(),
        isTrue,
        reason: name,
      );
    }
  });
}
