import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one aligned still, automatic classifier, explicit guarded collection update', () {
    final s = File('lib/features/trading_hub/arc_raiders/screens/arc_frozen_trail_single_grid_capture_screen.dart').readAsStringSync();
    expect(s, contains('normalizeLocatedGrid(located)'));
    expect(s, contains('ArcBlueprintPhotoOccupancyEngine('));
    expect(s, contains('automaticUpdateBlockReason('));
    expect(s, contains('ArcBlueprintPhotoImportService().apply('));
    expect(s, contains('Update Blueprint Collection'));
    expect(s, isNot(contains('await _alignCapturedImage(')));
  });
}
