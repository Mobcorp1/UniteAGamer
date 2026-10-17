import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('single corrected image is used for recognition and guarded import', () {
    final s = File('lib/features/trading_hub/arc_raiders/screens/arc_frozen_trail_single_grid_capture_screen.dart').readAsStringSync();
    expect(s, contains('normalizeLocatedGrid(located)'));
    expect(s, contains('_image = registeredImage'));
    expect(s, contains('columns: 17'));
    expect(s, contains('columns: 17'));
    expect(s, contains('ArcBlueprintPhotoImportService().apply('));
    expect(s, contains('automaticUpdateBlockReason('));
    expect(s, isNot(contains('await _alignCapturedImage(')));
    expect(s, contains('grid35-expanded-alignment-photo'));
  });
}
