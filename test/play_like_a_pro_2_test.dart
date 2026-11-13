import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/play_like_a_pro_mixtape_library.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/play_like_a_pro_routine_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/play_like_a_pro_routine.dart';

void main() {
  group('Play Like A Pro 2', () {
    test('retains all nine UAG YouTube mixtapes', () {
      expect(PlayLikeAProMixtapeLibrary.mixtapes, hasLength(9));
      expect(
        PlayLikeAProMixtapeLibrary.mixtapes.every((mix) => mix.isConfigured),
        isTrue,
      );
      expect(
        PlayLikeAProMixtapeLibrary.byId('uag_wind_down').purpose,
        'RECOVER',
      );
    });

    test('nervous pre-game state recommends reset before hype', () {
      final plan = const PlayLikeAProRoutineEngine().build(
        PlayLikeAProRoutineInputs(
          sessionStart: DateTime(2026, 8, 11, 20),
          performanceState: PlayLikeAProPerformanceState.nervous,
        ),
      );
      expect(plan.preGameMixtapeId, 'uag_reset');
      expect(plan.recoveryMixtapeId, 'uag_wind_down');
    });

    test('low sleep and missing hydration create emphasized prep', () {
      final plan = const PlayLikeAProRoutineEngine().build(
        PlayLikeAProRoutineInputs(
          sessionStart: DateTime(2026, 8, 11, 20),
          sleepHours: 5,
          hydrated: false,
          ateRecently: false,
        ),
      );
      expect(
        plan.tasks.firstWhere((task) => task.id == 'readiness-check').emphasis,
        isTrue,
      );
      expect(
        plan.tasks.firstWhere((task) => task.id == 'hydrate').emphasis,
        isTrue,
      );
      expect(
        plan.tasks.firstWhere((task) => task.id == 'fuel').emphasis,
        isTrue,
      );
    });

    test('routine covers prepare, perform and recover phases', () {
      final plan = const PlayLikeAProRoutineEngine().build(
        PlayLikeAProRoutineInputs(
          sessionStart: DateTime(2026, 8, 11, 20),
          targetSessionMinutes: 120,
        ),
      );
      final phases = plan.tasks.map((task) => task.phase).toSet();
      expect(phases, contains(PlayLikeAProRoutinePhase.fuel));
      expect(phases, contains(PlayLikeAProRoutinePhase.physicalWarmup));
      expect(phases, contains(PlayLikeAProRoutinePhase.mechanicalWarmup));
      expect(phases, contains(PlayLikeAProRoutinePhase.duringSession));
      expect(phases, contains(PlayLikeAProRoutinePhase.recovery));
    });
  });
}
