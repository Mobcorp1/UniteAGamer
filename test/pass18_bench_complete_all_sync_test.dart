import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_progression_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';

void main() {
  const engine = ArcProgressionEngine();
  final defs = engine.benchDefinitions
      .where((definition) => definition.station == 'Gunsmith')
      .toList(growable: false)
    ..sort((a, b) => a.level.compareTo(b.level));

  Map<String, ArcScrappyState> statesThrough(int level) => {
    for (final definition in defs.where((def) => def.level <= level))
      for (final requirement in definition.objectives)
        requirement.id: ArcScrappyState(
          itemId: requirement.id,
          collectedCount: requirement.requiredCount,
        ),
  };

  test('Complete All records every consecutive finished bench tier', () {
    expect(defs.length, greaterThanOrEqualTo(3));
    final levels = engine.completedBenchLevels(
      station: 'Gunsmith',
      currentLevel: 1,
      scrappyStates: statesThrough(defs.last.level),
    );
    expect(levels, [for (var i = 2; i <= defs.last.level; i++) i]);
  });

  test('part-complete next tier cannot skip ahead', () {
    final states = statesThrough(2);
    for (final requirement in defs.last.objectives) {
      states[requirement.id] = ArcScrappyState(
        itemId: requirement.id,
        collectedCount: requirement.requiredCount,
      );
    }
    expect(
      engine.completedBenchLevels(
        station: 'Gunsmith',
        currentLevel: 1,
        scrappyStates: states,
      ),
      [2],
    );
  });

  test('already completed tiers are idempotent', () {
    expect(
      engine.completedBenchLevels(
        station: 'Gunsmith',
        currentLevel: defs.last.level,
        scrappyStates: statesThrough(defs.last.level),
      ),
      isEmpty,
    );
  });

  test('bench progression never borrows another station materials', () {
    final states = statesThrough(defs.last.level);
    expect(
      engine.completedBenchLevels(
        station: 'Medical Lab',
        currentLevel: 1,
        scrappyStates: states,
      ),
      isEmpty,
    );
  });
}
