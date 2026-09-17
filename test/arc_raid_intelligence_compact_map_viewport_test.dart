import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Raid Intelligence keeps a usable map viewport on compact devices', () {
    final screen = File(
      'lib/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart',
    ).readAsStringSync();
    final renderer = File(
      'lib/features/trading_hub/arc_raiders/widgets/arc_raid_intelligence_map.dart',
    ).readAsStringSync();

    expect(screen, contains('final compactLandscape ='));
    expect(screen, contains('constraints.maxWidth >= 680'));
    expect(screen, contains('final sideBySide = desktop || compactLandscape;'));
    expect(screen, contains('final compactMapHeight = math.min('));
    expect(screen, contains('height: compactMapHeight'));

    expect(renderer, contains('height.clamp(1.0, 1100.0)'));
    expect(renderer, isNot(contains('height.clamp(360.0, 1100.0)')));
    expect(renderer, contains('width.clamp(1.0, 1800.0)'));
  });
}
