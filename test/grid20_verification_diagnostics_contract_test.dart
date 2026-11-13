import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final path =
      'lib/features/trading_hub/arc_raiders/screens/arc_frozen_trail_single_grid_capture_screen.dart';
  test('scanner preserves classifier signals and collection-writing guard', () {
    final text = File(path).readAsStringSync();
    for (final required in <String>[
      'normalizeLocatedGrid(located)',
      'ArcBlueprintPhotoOccupancyEngine(',
      'automaticUpdateBlockReason(',
      '_recognised.isNotEmpty',
      'Update Blueprint Collection',
    ]) {
      expect(text, contains(required), reason: required);
    }
  });
  test('empty verified result never enters collection-writing flow', () {
    final text = File(path).readAsStringSync();
    expect(RegExp(r'\|\|\s*_recognised\.isEmpty').hasMatch(text), isTrue);
    expect(RegExp(r'&&\s*_recognised\.isNotEmpty').hasMatch(text), isTrue);
    expect(text, contains('_recognised.isEmpty'));
  });
}
