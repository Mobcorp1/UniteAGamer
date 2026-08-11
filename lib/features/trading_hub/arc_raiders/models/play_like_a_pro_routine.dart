import 'package:flutter/material.dart';

enum PlayLikeAProPerformanceState { drained, ready, nervous, lockedIn }

extension PlayLikeAProPerformanceStateX on PlayLikeAProPerformanceState {
  String get label => switch (this) {
    PlayLikeAProPerformanceState.drained => 'Drained',
    PlayLikeAProPerformanceState.ready => 'Ready',
    PlayLikeAProPerformanceState.nervous => 'Wired / Nervous',
    PlayLikeAProPerformanceState.lockedIn => 'Locked In',
  };
}

enum PlayLikeAProRoutinePhase {
  readiness,
  fuel,
  physicalWarmup,
  mechanicalWarmup,
  mentalWarmup,
  activation,
  duringSession,
  recovery,
}

extension PlayLikeAProRoutinePhaseX on PlayLikeAProRoutinePhase {
  String get label => switch (this) {
    PlayLikeAProRoutinePhase.readiness => 'Readiness',
    PlayLikeAProRoutinePhase.fuel => 'Hydration & Fuel',
    PlayLikeAProRoutinePhase.physicalWarmup => 'Physical Warm-Up',
    PlayLikeAProRoutinePhase.mechanicalWarmup => 'Game Warm-Up',
    PlayLikeAProRoutinePhase.mentalWarmup => 'Mental Lock-In',
    PlayLikeAProRoutinePhase.activation => 'Activation',
    PlayLikeAProRoutinePhase.duringSession => 'During Session',
    PlayLikeAProRoutinePhase.recovery => 'Recovery',
  };

  IconData get icon => switch (this) {
    PlayLikeAProRoutinePhase.readiness => Icons.monitor_heart_outlined,
    PlayLikeAProRoutinePhase.fuel => Icons.water_drop_outlined,
    PlayLikeAProRoutinePhase.physicalWarmup => Icons.accessibility_new_rounded,
    PlayLikeAProRoutinePhase.mechanicalWarmup => Icons.sports_esports_rounded,
    PlayLikeAProRoutinePhase.mentalWarmup => Icons.psychology_alt_rounded,
    PlayLikeAProRoutinePhase.activation => Icons.headphones_rounded,
    PlayLikeAProRoutinePhase.duringSession => Icons.timer_outlined,
    PlayLikeAProRoutinePhase.recovery => Icons.bedtime_outlined,
  };
}

class PlayLikeAProRoutineInputs {
  const PlayLikeAProRoutineInputs({
    required this.sessionStart,
    this.targetSessionMinutes = 90,
    this.performanceState = PlayLikeAProPerformanceState.ready,
    this.energy = 3,
    this.hydrated = false,
    this.ateRecently = false,
    this.sleepHours = 7,
    this.mechanicalWarmup = true,
  });

  final DateTime sessionStart;
  final int targetSessionMinutes;
  final PlayLikeAProPerformanceState performanceState;
  final int energy;
  final bool hydrated;
  final bool ateRecently;
  final double sleepHours;
  final bool mechanicalWarmup;
}

class PlayLikeAProRoutineTask {
  const PlayLikeAProRoutineTask({
    required this.id,
    required this.phase,
    required this.title,
    required this.detail,
    required this.minutesBeforeStart,
    this.mixtapeId,
    this.emphasis = false,
  });

  final String id;
  final PlayLikeAProRoutinePhase phase;
  final String title;
  final String detail;
  final int minutesBeforeStart;
  final String? mixtapeId;
  final bool emphasis;

  DateTime scheduledAt(DateTime sessionStart) =>
      sessionStart.subtract(Duration(minutes: minutesBeforeStart));
}

class PlayLikeAProRoutinePlan {
  const PlayLikeAProRoutinePlan({
    required this.inputs,
    required this.tasks,
    required this.preGameMixtapeId,
    required this.recoveryMixtapeId,
  });

  final PlayLikeAProRoutineInputs inputs;
  final List<PlayLikeAProRoutineTask> tasks;
  final String preGameMixtapeId;
  final String recoveryMixtapeId;

  List<PlayLikeAProRoutineTask> forPhase(PlayLikeAProRoutinePhase phase) =>
      tasks.where((task) => task.phase == phase).toList(growable: false);
}
