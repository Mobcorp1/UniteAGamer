import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_event_artwork.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_map_conditions.dart';

void main() {
  test('all mapped raid conditions have distinct bundled art', () {
    final conditions = <String>{
      for (final mapName in const <String>[
        'Dam Battlegrounds',
        'Buried City',
        'Spaceport',
        'Blue Gate',
        'Stella Montis',
        'Riven Tides',
      ])
        for (final condition in ArcMapConditions.combinedOptionsForMap(mapName))
          if (!condition.isNeutral) condition.label,
    };
    expect(conditions.length, 18);
    final seen = <String>{};
    for (final condition in conditions) {
      final path = ArcEventArtwork.forCondition(condition);
      expect(path, endsWith('.svg'), reason: condition);
      expect(File(path).existsSync(), isTrue, reason: condition);
      expect(seen.add(path), isTrue, reason: condition);
    }
  });

  test('approved Operations and Nomadic Trader assets exist', () {
    expect(File(ArcEventArtwork.operations).existsSync(), isTrue);
    expect(File(ArcEventArtwork.nomadicTrader).existsSync(), isTrue);
    expect(File(ArcEventArtwork.fallback).existsSync(), isTrue);
  });

  test('alternate and future condition names resolve safely', () {
    expect(ArcEventArtwork.forCondition('EM Storm'),
        ArcEventArtwork.forCondition('Electromagnetic Storm'));
    expect(ArcEventArtwork.forCondition('HURRICANE'),
        'assets/arc_raiders/conditions/hurricane.svg');
    expect(ArcEventArtwork.forCondition('unknown future condition'),
        ArcEventArtwork.fallback);
  });

  test('Flutter asset bundle registers the conditions directory', () {
    expect(File('pubspec.yaml').readAsStringSync(),
        contains('assets/arc_raiders/conditions/'));
  });
}
