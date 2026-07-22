import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_season_reset_models.dart';

enum ArcExpeditionSubsystem {
  blueprintTracker,
  scrappyTracker,
  benchTracker,
  questTracker,
  operations,
  rewardVault,
  huntTargets,
  commandCentre,
  favouriteLoadout,
  tradeIntelligence,
}

extension ArcExpeditionSubsystemLabel on ArcExpeditionSubsystem {
  String get label => switch (this) {
    ArcExpeditionSubsystem.blueprintTracker => 'Blueprint Tracker',
    ArcExpeditionSubsystem.scrappyTracker => 'Scrappy Tracker',
    ArcExpeditionSubsystem.benchTracker => 'Bench Tracker',
    ArcExpeditionSubsystem.questTracker => 'Quest Tracker',
    ArcExpeditionSubsystem.operations => 'Operations',
    ArcExpeditionSubsystem.rewardVault => 'Reward Vault',
    ArcExpeditionSubsystem.huntTargets => 'Hunt Targets',
    ArcExpeditionSubsystem.commandCentre => 'Command Centre',
    ArcExpeditionSubsystem.favouriteLoadout => 'Favourite Loadout',
    ArcExpeditionSubsystem.tradeIntelligence => 'Trade Intelligence',
  };
}

enum ArcExpeditionRefreshReason {
  initialLoad,
  manualRefresh,
  progressionChanged,
  resetStarted,
  resetCompleted,
  resetFailed,
  resetReconciled,
}

class ArcExpeditionStateSnapshot {
  const ArcExpeditionStateSnapshot({
    required this.seasonState,
    required this.resetSystems,
    required this.recalculatedSystems,
    required this.subscribedSystems,
    this.lastRefreshReason = ArcExpeditionRefreshReason.initialLoad,
  });

  final ArcSeasonState seasonState;
  final List<ArcExpeditionSubsystem> resetSystems;
  final List<ArcExpeditionSubsystem> recalculatedSystems;
  final List<ArcExpeditionSubsystem> subscribedSystems;
  final ArcExpeditionRefreshReason lastRefreshReason;

  String get currentSeasonId => seasonState.currentSeasonId;
  String get statusLabel => seasonState.resetStatus.name;
  int get resetVersion => seasonState.resetVersion;
  bool get resetInProgress => seasonState.resetInProgress;
  bool get hasCompletedReset =>
      seasonState.resetStatus == ArcSeasonResetStatus.completed;

  factory ArcExpeditionStateSnapshot.fromSeasonState(
    ArcSeasonState seasonState, {
    ArcExpeditionRefreshReason reason = ArcExpeditionRefreshReason.initialLoad,
  }) {
    return ArcExpeditionStateSnapshot(
      seasonState: seasonState,
      resetSystems: const <ArcExpeditionSubsystem>[
        ArcExpeditionSubsystem.blueprintTracker,
        ArcExpeditionSubsystem.scrappyTracker,
        ArcExpeditionSubsystem.benchTracker,
        ArcExpeditionSubsystem.questTracker,
        ArcExpeditionSubsystem.operations,
        ArcExpeditionSubsystem.rewardVault,
      ],
      recalculatedSystems: const <ArcExpeditionSubsystem>[
        ArcExpeditionSubsystem.commandCentre,
        ArcExpeditionSubsystem.favouriteLoadout,
        ArcExpeditionSubsystem.huntTargets,
        ArcExpeditionSubsystem.tradeIntelligence,
      ],
      subscribedSystems: ArcExpeditionSubsystem.values,
      lastRefreshReason: reason,
    );
  }
}

class ArcExpeditionRefreshEvent {
  const ArcExpeditionRefreshEvent({
    required this.reason,
    required this.currentSeasonId,
    required this.occurredAt,
    this.resetId,
    this.resetVersion = 0,
    this.systems = ArcExpeditionSubsystem.values,
  });

  final ArcExpeditionRefreshReason reason;
  final String currentSeasonId;
  final DateTime occurredAt;
  final String? resetId;
  final int resetVersion;
  final List<ArcExpeditionSubsystem> systems;

  bool includes(ArcExpeditionSubsystem subsystem) =>
      systems.contains(subsystem);
}
