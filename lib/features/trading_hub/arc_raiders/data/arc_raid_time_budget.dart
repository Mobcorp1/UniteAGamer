import 'dart:math' as math;
import '../models/arc_raid_intelligence_models.dart';

/// Planning presets, not a claim about a game's maximum raid duration.
/// The player can replace these estimates with their actual remaining time.
class ArcRaidTimeBudget {
  const ArcRaidTimeBudget({
    this.fullMinutes = 30,
    this.midMinutes = 15,
    this.lateMinutes = 5,
    this.exitReserveMinutes = 2,
    this.minutesPerStop = 3,
  });
  final int fullMinutes,
      midMinutes,
      lateMinutes,
      exitReserveMinutes,
      minutesPerStop;
  int preset(String stage) => switch (stage) {
    'Late' => lateMinutes,
    'Mid' => midMinutes,
    _ => fullMinutes,
  };
  int stopLimit({
    required int remainingMinutes,
    required ArcRaidRouteStyle style,
    required String stage,
  }) => math.min(
    style.stopLimitForStage(stage),
    math.max(0, (remainingMinutes - exitReserveMinutes) ~/ minutesPerStop),
  );
}
