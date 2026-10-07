import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Command Centre is ordered as a ranked Raider briefing', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_content.dart',
    ).readAsStringSync();

    final order = <String>[
      '_commandHero(commandState, commandMoves)',
      '_nextRaidBrief(commandState)',
      '_progressionBrief(commandState)',
      '_loadoutQuestBrief(commandState)',
      '_eventsForYou(commandState)',
      '_tradeUpcomingBrief(commandState)',
      '_exploreBrief(commandState, exploreTiles)',
    ];

    var previous = -1;
    for (final token in order) {
      final index = source.indexOf(token);
      expect(index, greaterThan(previous), reason: token);
      previous = index;
    }
  });

  test('Explore owns the broad systems carousel and stays collapsed', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_content.dart',
    ).readAsStringSync();

    final exploreStart = source.indexOf("title: 'EXPLORE'");
    expect(exploreStart, greaterThanOrEqualTo(0));
    final exploreBlock = source.substring(
      exploreStart,
      (exploreStart + 650).clamp(0, source.length).toInt(),
    );
    expect(exploreBlock, contains('initiallyExpanded: false'));
    expect(exploreBlock, contains('_systemCarousel'));
  });

  test('primary briefing surfaces the agreed operational sections', () {
    final source = File(
      'lib/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_content.dart',
    ).readAsStringSync();

    for (final label in const [
      'NEXT RAID',
      'BLUEPRINT TRACKER',
      'BENCH',
      'SCRAPPY',
      'FAVOURITE LOADOUT',
      'CURRENT QUESTS',
      'EVENTS FOR YOU',
      'DUPLICATES / TRADE',
      'CALENDAR / UPCOMING',
      'EXPLORE',
    ]) {
      expect(source, contains(label), reason: label);
    }
  });
}
