import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Command Centre uses the compact responsive workspace policy', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_content.dart',
    ).readAsStringSync();

    expect(source, contains('ArcCommandCentreLayoutPolicy.moveColumns'));
    expect(source, contains('ArcCommandCentreLayoutPolicy.moveTileHeight'));
    expect(source, contains('ArcCommandCentreLayoutPolicy.dailyColumns'));
    expect(source, contains('ArcCommandCentreLayoutPolicy.dailyTileHeight'));
    expect(source, contains('ArcCommandCentreLayoutPolicy.systemRingHeight'));
  });

  test(
    'mobile systems remain available without duplicating priority content',
    () {
      final source = File(
        'lib/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_content.dart',
      ).readAsStringSync();

      final systemsStart = source.indexOf("title: 'ARC SYSTEMS'");
      expect(systemsStart, greaterThanOrEqualTo(0));

      final systemsBlock = source.substring(
        systemsStart,
        (systemsStart + 420).clamp(0, source.length).toInt(),
      );
      expect(systemsBlock, contains('initiallyExpanded: false'));
      expect(systemsBlock, contains('_systemCarousel'));
    },
  );

  test('daily mission cards no longer use the old cramped 68px height', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_content.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('height: 68,')));
  });
}
