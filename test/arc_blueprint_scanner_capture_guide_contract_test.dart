import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scanner uses one persistent alignment frame and no synthetic grid', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_blueprint_live_scanner_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('final ManualAlignmentController _alignmentController'),
    );
    expect(source, isNot(contains('_bottomAlignmentController')));
    expect(source, isNot(contains('_topAlignmentController')));
    expect(
      source,
      isNot(contains('for (var column = 1; column < 10; column++)')),
    );
    expect(source, isNot(contains('for (var row = 1; row < 5; row++)')));
    expect(source, contains('_DragTarget.topLeft'));
    expect(source, contains('_DragTarget.bottomRight'));
  });
}
