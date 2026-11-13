import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one locate, one normalize, no second geometry crop', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_frozen_trail_single_grid_capture_screen.dart',
    ).readAsStringSync();
    expect(source, contains('normalizeLocatedGrid(located)'));
    expect(source, isNot(contains('registrar.register(bytes: located')));
    expect(source, contains('ArcBlueprintPhotoOccupancyEngine('));
    expect(source, contains('automaticUpdateBlockReason('));
  });
  test('single-grid locator normalises to 17x6 without second crop', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/data/arc_blueprint_single_grid_locator.dart',
    ).readAsStringSync();
    expect(source, contains(RegExp(r'width:\s*1700\s*,\s*height:\s*600\s*,')));
  });
}
