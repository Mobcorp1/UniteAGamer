import 'package:flutter/foundation.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';

enum ArcDecisionCategory {
  criticalBlocker,
  bench,
  quest,
  trade,
  resources,
  inventory,
  loadout,
  blueprint,
  raidIntelligence,
  nomadicTrader,
  operations,
  rewardVault,
  community,
  optional,
}

extension ArcDecisionCategoryLabel on ArcDecisionCategory {
  String get label => switch (this) {
    ArcDecisionCategory.criticalBlocker => 'Critical Blocker',
    ArcDecisionCategory.bench => 'Bench',
    ArcDecisionCategory.quest => 'Quest',
    ArcDecisionCategory.trade => 'Trade',
    ArcDecisionCategory.resources => 'Resources',
    ArcDecisionCategory.inventory => 'Inventory',
    ArcDecisionCategory.loadout => 'Loadout',
    ArcDecisionCategory.blueprint => 'Blueprint',
    ArcDecisionCategory.raidIntelligence => 'Raid Intelligence',
    ArcDecisionCategory.nomadicTrader => 'Nomadic Trader',
    ArcDecisionCategory.operations => 'Operations',
    ArcDecisionCategory.rewardVault => 'Reward Vault',
    ArcDecisionCategory.community => 'Community',
    ArcDecisionCategory.optional => 'Optional',
  };
}

@immutable
class ArcDecisionAction {
  const ArcDecisionAction({
    required this.label,
    this.routeName,
    this.intent = ArcCommandActionIntent.route,
    this.placeholderMessage,
  });

  final String label;
  final String? routeName;
  final ArcCommandActionIntent intent;
  final String? placeholderMessage;

  ArcCommandAction toCommandAction() {
    return ArcCommandAction(
      label: label,
      routeName: routeName,
      intent: intent,
      placeholderMessage: placeholderMessage,
    );
  }
}

@immutable
class ArcDecisionScore {
  const ArcDecisionScore({
    required this.readiness,
    required this.blockerSeverity,
    required this.multiSystemImpact,
    required this.timeSensitivity,
    required this.tradeAvailability,
    required this.progressionUnlockValue,
    required this.missingResourcePressure,
    required this.completionPercentage,
    required this.setupCompleteness,
    required this.confidence,
  });

  final int readiness;
  final int blockerSeverity;
  final int multiSystemImpact;
  final int timeSensitivity;
  final int tradeAvailability;
  final int progressionUnlockValue;
  final int missingResourcePressure;
  final int completionPercentage;
  final int setupCompleteness;
  final int confidence;

  int get total {
    final weighted =
        readiness * 13 +
        blockerSeverity * 15 +
        multiSystemImpact * 12 +
        timeSensitivity * 8 +
        tradeAvailability * 8 +
        progressionUnlockValue * 14 +
        missingResourcePressure * 9 +
        completionPercentage * 5 +
        setupCompleteness * 5 +
        confidence * 11;
    return (weighted / 100).round().clamp(0, 100);
  }

  String get confidenceLabel {
    if (confidence >= 82) return 'High confidence';
    if (confidence >= 56) return 'Medium confidence';
    return 'Low confidence';
  }

  String get urgencyLabel {
    if (timeSensitivity >= 75 || blockerSeverity >= 80) return 'Urgent';
    if (timeSensitivity >= 45 || blockerSeverity >= 45) return 'Soon';
    return 'Steady';
  }
}

@immutable
class ArcDecisionSignal {
  const ArcDecisionSignal({
    required this.id,
    required this.title,
    required this.summary,
    required this.detail,
    required this.category,
    required this.status,
    required this.progressLabel,
    required this.action,
    required this.sourceSystem,
    required this.score,
    this.secondaryAction,
    this.tradeAssisted = false,
  });

  final String id;
  final String title;
  final String summary;
  final String detail;
  final ArcDecisionCategory category;
  final ArcCommandStatus status;
  final String progressLabel;
  final ArcDecisionAction action;
  final ArcDecisionAction? secondaryAction;
  final String sourceSystem;
  final ArcDecisionScore score;
  final bool tradeAssisted;

  int get priority => score.total;
  int get urgency => score.timeSensitivity;
  int get impact => score.progressionUnlockValue;
  int get confidence => score.confidence;
  String get statusLabel => _statusLabel(status);
  String get actionLabel => action.label;
  String? get routeName => action.routeName;
  String get safeActionKey => action.intent.name;

  static String _statusLabel(ArcCommandStatus status) {
    return switch (status) {
      ArcCommandStatus.critical => 'Critical',
      ArcCommandStatus.warning => 'Blocked',
      ArcCommandStatus.active => 'Active',
      ArcCommandStatus.ready => 'Ready',
      ArcCommandStatus.neutral => 'Set up',
      ArcCommandStatus.success => 'Stable',
    };
  }
}

@immutable
class ArcDecisionMission extends ArcDecisionSignal {
  const ArcDecisionMission({
    required super.id,
    required super.title,
    required super.summary,
    required super.detail,
    required super.category,
    required super.status,
    required super.progressLabel,
    required super.action,
    required super.sourceSystem,
    required super.score,
    super.secondaryAction,
    super.tradeAssisted,
  });

  factory ArcDecisionMission.fromSignal(ArcDecisionSignal signal) {
    return ArcDecisionMission(
      id: signal.id,
      title: signal.title,
      summary: signal.summary,
      detail: signal.detail,
      category: signal.category,
      status: signal.status,
      progressLabel: signal.progressLabel,
      action: signal.action,
      secondaryAction: signal.secondaryAction,
      sourceSystem: signal.sourceSystem,
      score: signal.score,
      tradeAssisted: signal.tradeAssisted,
    );
  }
}

@immutable
class ArcDecisionObjective extends ArcDecisionSignal {
  const ArcDecisionObjective({
    required super.id,
    required super.title,
    required super.summary,
    required super.detail,
    required super.category,
    required super.status,
    required super.progressLabel,
    required super.action,
    required super.sourceSystem,
    required super.score,
    super.secondaryAction,
    super.tradeAssisted,
  });

  factory ArcDecisionObjective.fromSignal(ArcDecisionSignal signal) {
    return ArcDecisionObjective(
      id: signal.id,
      title: signal.title,
      summary: signal.summary,
      detail: signal.detail,
      category: signal.category,
      status: signal.status,
      progressLabel: signal.progressLabel,
      action: signal.action,
      secondaryAction: signal.secondaryAction,
      sourceSystem: signal.sourceSystem,
      score: signal.score,
      tradeAssisted: signal.tradeAssisted,
    );
  }
}

@immutable
class ArcDecisionBlocker extends ArcDecisionSignal {
  const ArcDecisionBlocker({
    required super.id,
    required super.title,
    required super.summary,
    required super.detail,
    required super.category,
    required super.status,
    required super.progressLabel,
    required super.action,
    required super.sourceSystem,
    required super.score,
    super.secondaryAction,
    super.tradeAssisted,
  });

  factory ArcDecisionBlocker.fromSignal(ArcDecisionSignal signal) {
    return ArcDecisionBlocker(
      id: signal.id,
      title: signal.title,
      summary: signal.summary,
      detail: signal.detail,
      category: signal.category,
      status: signal.status,
      progressLabel: signal.progressLabel,
      action: signal.action,
      secondaryAction: signal.secondaryAction,
      sourceSystem: signal.sourceSystem,
      score: signal.score,
      tradeAssisted: signal.tradeAssisted,
    );
  }
}

@immutable
class ArcDecisionRecommendation extends ArcDecisionSignal {
  const ArcDecisionRecommendation({
    required super.id,
    required super.title,
    required super.summary,
    required super.detail,
    required super.category,
    required super.status,
    required super.progressLabel,
    required super.action,
    required super.sourceSystem,
    required super.score,
    super.secondaryAction,
    super.tradeAssisted,
  });

  factory ArcDecisionRecommendation.fromSignal(ArcDecisionSignal signal) {
    return ArcDecisionRecommendation(
      id: signal.id,
      title: signal.title,
      summary: signal.summary,
      detail: signal.detail,
      category: signal.category,
      status: signal.status,
      progressLabel: signal.progressLabel,
      action: signal.action,
      secondaryAction: signal.secondaryAction,
      sourceSystem: signal.sourceSystem,
      score: signal.score,
      tradeAssisted: signal.tradeAssisted,
    );
  }
}

@immutable
class ArcDecisionSystemStatus extends ArcDecisionSignal {
  const ArcDecisionSystemStatus({
    required super.id,
    required super.title,
    required super.summary,
    required super.detail,
    required super.category,
    required super.status,
    required super.progressLabel,
    required super.action,
    required super.sourceSystem,
    required super.score,
    super.secondaryAction,
    super.tradeAssisted,
  });

  factory ArcDecisionSystemStatus.fromSignal(ArcDecisionSignal signal) {
    return ArcDecisionSystemStatus(
      id: signal.id,
      title: signal.title,
      summary: signal.summary,
      detail: signal.detail,
      category: signal.category,
      status: signal.status,
      progressLabel: signal.progressLabel,
      action: signal.action,
      secondaryAction: signal.secondaryAction,
      sourceSystem: signal.sourceSystem,
      score: signal.score,
      tradeAssisted: signal.tradeAssisted,
    );
  }
}

@immutable
class ArcDecisionState {
  const ArcDecisionState({
    required this.primaryMission,
    required this.rankedObjectives,
    required this.blockers,
    required this.smartRecommendations,
    required this.tradeAssistedOpportunities,
    required this.resourceActions,
    required this.systemStatuses,
    required this.signals,
    required this.confidenceLabel,
    required this.summary,
  });

  final ArcDecisionMission primaryMission;
  final List<ArcDecisionObjective> rankedObjectives;
  final List<ArcDecisionBlocker> blockers;
  final List<ArcDecisionRecommendation> smartRecommendations;
  final List<ArcDecisionSignal> tradeAssistedOpportunities;
  final List<ArcDecisionSignal> resourceActions;
  final List<ArcDecisionSystemStatus> systemStatuses;
  final List<ArcDecisionSignal> signals;
  final String confidenceLabel;
  final String summary;
}
