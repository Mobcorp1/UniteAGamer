import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/play_like_a_pro_routine.dart';

class PlayLikeAProRoutineEngine {
  const PlayLikeAProRoutineEngine();

  PlayLikeAProRoutinePlan build(PlayLikeAProRoutineInputs inputs) {
    final preGameMixtapeId = switch (inputs.performanceState) {
      PlayLikeAProPerformanceState.drained => 'uag_activation',
      PlayLikeAProPerformanceState.ready => 'uag_focus',
      PlayLikeAProPerformanceState.nervous => 'uag_reset',
      PlayLikeAProPerformanceState.lockedIn => 'uag_flow',
    };

    final tasks = <PlayLikeAProRoutineTask>[
      PlayLikeAProRoutineTask(
        id: 'readiness-check',
        phase: PlayLikeAProRoutinePhase.readiness,
        title: 'Check the state you are bringing in',
        detail: inputs.sleepHours < 6
            ? 'You logged under 6 hours sleep. Lower the stakes, shorten the target session and avoid treating fatigue as a motivation problem.'
            : 'Notice energy, focus and tension before you start. The point is to prepare for the state you actually have.',
        minutesBeforeStart: 45,
        emphasis: inputs.sleepHours < 6,
      ),
      PlayLikeAProRoutineTask(
        id: 'hydrate',
        phase: PlayLikeAProRoutinePhase.fuel,
        title: inputs.hydrated
            ? 'Set water within reach'
            : 'Hydrate before you queue',
        detail: inputs.hydrated
            ? 'Keep water beside the setup so hydration does not depend on remembering mid-match.'
            : 'Have water now rather than starting the session already thirsty. Keep it beside the setup for the session.',
        minutesBeforeStart: 35,
        emphasis: !inputs.hydrated,
      ),
      PlayLikeAProRoutineTask(
        id: 'fuel',
        phase: PlayLikeAProRoutinePhase.fuel,
        title: inputs.ateRecently
            ? 'Avoid unnecessary pre-game snacking'
            : 'Get proper food in before the session',
        detail: inputs.ateRecently
            ? 'You have eaten recently. Keep the pre-game routine light and avoid turning energy drinks or snacks into the whole fuel strategy.'
            : 'Do not arrive at a long gaming session hungry. Choose a normal meal or sensible food rather than relying on sugar and caffeine alone.',
        minutesBeforeStart: 35,
        emphasis: !inputs.ateRecently,
      ),
      const PlayLikeAProRoutineTask(
        id: 'physical-warmup',
        phase: PlayLikeAProRoutinePhase.physicalWarmup,
        title: 'Move before you sit down to perform',
        detail:
            'Stand up, move your shoulders and neck, loosen hands and forearms, then settle into a comfortable neutral setup. No aggressive stretching or forcing painful joints.',
        minutesBeforeStart: 20,
      ),
      if (inputs.mechanicalWarmup)
        const PlayLikeAProRoutineTask(
          id: 'mechanical-warmup',
          phase: PlayLikeAProRoutinePhase.mechanicalWarmup,
          title: 'Use a short mechanical warm-up',
          detail:
              'Use a short low-stakes warm-up game, practice mode or aim routine. Warm up mechanics; do not exhaust yourself doing a full training session before the real session.',
          minutesBeforeStart: 15,
        ),
      const PlayLikeAProRoutineTask(
        id: 'clear-distractions',
        phase: PlayLikeAProRoutinePhase.mentalWarmup,
        title: 'Clear the desk and the head',
        detail:
            'Remove avoidable interruptions, set the session objective and decide what will make this session worth playing before the first queue.',
        minutesBeforeStart: 10,
      ),
      PlayLikeAProRoutineTask(
        id: 'mixtape',
        phase: PlayLikeAProRoutinePhase.activation,
        title: 'Start the recommended UAG Mixtape',
        detail: switch (inputs.performanceState) {
          PlayLikeAProPerformanceState.drained =>
            'Use activation music to raise energy without extending the warm-up forever.',
          PlayLikeAProPerformanceState.ready =>
            'Use a focus cue to move from normal life into deliberate play.',
          PlayLikeAProPerformanceState.nervous =>
            'Bring stimulation down first. Calm confidence beats piling hype on top of nerves.',
          PlayLikeAProPerformanceState.lockedIn =>
            'Protect the state you already have. Do not over-hype yourself out of a good window.',
        },
        minutesBeforeStart: 10,
        mixtapeId: preGameMixtapeId,
      ),
      const PlayLikeAProRoutineTask(
        id: 'start-intent',
        phase: PlayLikeAProRoutinePhase.activation,
        title: 'Queue with one clear intention',
        detail:
            'Start the session knowing the objective. The first serious game should not be where you discover whether you are ready.',
        minutesBeforeStart: 2,
      ),
      PlayLikeAProRoutineTask(
        id: 'session-break',
        phase: PlayLikeAProRoutinePhase.duringSession,
        title: 'Use a real break before autopilot takes over',
        detail: inputs.targetSessionMinutes > 90
            ? 'This is a longer session. Build in a proper stand-up, water and eye-away reset rather than waiting until performance has already fallen apart.'
            : 'If the session runs beyond the planned window, use a stand-up, water and eye-away reset before extending it.',
        minutesBeforeStart: 0,
        emphasis: inputs.targetSessionMinutes > 90,
      ),
      const PlayLikeAProRoutineTask(
        id: 'recovery-reset',
        phase: PlayLikeAProRoutinePhase.recovery,
        title: 'End the performance state deliberately',
        detail:
            'Stand up, move, hydrate and stop carrying the last match into the rest of the evening. Use the post-session review in Session Coach if you want to log the pattern.',
        minutesBeforeStart: -1,
        mixtapeId: 'uag_wind_down',
      ),
      const PlayLikeAProRoutineTask(
        id: 'sleep-protect',
        phase: PlayLikeAProRoutinePhase.recovery,
        title: 'Protect sleep after late sessions',
        detail:
            'If you are playing late, give yourself a lower-stimulation transition instead of going straight from maximum intensity into bed.',
        minutesBeforeStart: -1,
      ),
    ];

    tasks.sort((a, b) => b.minutesBeforeStart.compareTo(a.minutesBeforeStart));
    return PlayLikeAProRoutinePlan(
      inputs: inputs,
      tasks: tasks,
      preGameMixtapeId: preGameMixtapeId,
      recoveryMixtapeId: 'uag_wind_down',
    );
  }
}
