import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_decision_engine_models.dart';

class ArcCommandCentreViewMapper {
  const ArcCommandCentreViewMapper._();

  static ArcCommandPriority priority(ArcDecisionMission mission) {
    return ArcCommandPriority(
      title: mission.title,
      explanation: mission.summary,
      progressLabel: mission.progressLabel,
      statusTag: _decisionStatusTag(mission),
      detail: mission.detail,
      status: mission.status,
      primaryAction: mission.action.toCommandAction(),
      secondaryAction: mission.secondaryAction?.toCommandAction(),
    );
  }

  static List<ArcCommandSnapshotMetric> snapshots(
    ArcDecisionState decisionState,
  ) {
    return decisionState.systemStatuses
        .map(
          (status) => ArcCommandSnapshotMetric(
            label: status.title,
            value: status.progressLabel,
            detail: status.summary,
            status: status.status,
          ),
        )
        .toList(growable: false);
  }

  static List<ArcCommandObjective> objectives(ArcDecisionState decisionState) {
    return decisionState.rankedObjectives
        .map(
          (objective) => ArcCommandObjective(
            title: objective.title,
            reason: objective.summary,
            statusLabel: _decisionStatusTag(objective),
            progressText: objective.progressLabel,
            status: objective.status,
            action: objective.action.toCommandAction(),
          ),
        )
        .toList(growable: false);
  }

  static List<ArcCommandAlert> alerts(ArcDecisionState decisionState) {
    return decisionState.blockers
        .map(
          (blocker) => ArcCommandAlert(
            title: blocker.title,
            body: blocker.detail,
            statusLabel: _decisionStatusTag(blocker),
            status: blocker.status,
            action: blocker.action.toCommandAction(),
          ),
        )
        .toList(growable: false);
  }

  static List<ArcCommandRecommendation> recommendations(
    ArcDecisionState decisionState,
  ) {
    return decisionState.smartRecommendations
        .map(
          (recommendation) => ArcCommandRecommendation(
            title: recommendation.title,
            body: recommendation.detail,
            action: recommendation.action.toCommandAction(),
          ),
        )
        .take(4)
        .toList(growable: false);
  }

  static List<ArcCommandResourceStatus> resources(
    ArcDecisionState decisionState,
  ) {
    final resourceActions = decisionState.resourceActions;
    if (resourceActions.isNotEmpty) {
      return resourceActions
          .take(4)
          .map(
            (signal) => ArcCommandResourceStatus(
              name: _resourceNameFromDecision(signal),
              ownedLabel: signal.sourceSystem,
              requiredLabel: signal.progressLabel,
              status: signal.status,
            ),
          )
          .toList(growable: false);
    }

    final resourceStatus = decisionState.systemStatuses.where(
      (status) =>
          status.category == ArcDecisionCategory.resources ||
          status.category == ArcDecisionCategory.inventory,
    );
    if (resourceStatus.isNotEmpty) {
      return resourceStatus
          .take(4)
          .map(
            (status) => ArcCommandResourceStatus(
              name: status.title,
              ownedLabel: status.progressLabel,
              requiredLabel: status.summary,
              status: status.status,
            ),
          )
          .toList(growable: false);
    }

    return const [
      ArcCommandResourceStatus(
        name: 'Resources',
        ownedLabel: 'Not tracked yet',
        requiredLabel: 'Track resources',
        status: ArcCommandStatus.neutral,
      ),
    ];
  }

  static String _decisionStatusTag(ArcDecisionSignal signal) {
    if (signal.status == ArcCommandStatus.ready) return 'Ready';
    if (signal.category == ArcDecisionCategory.criticalBlocker) {
      return 'Critical';
    }
    if (signal.confidence < 45) return 'Low confidence';
    if (signal.tradeAssisted) return 'Trade assisted';
    return signal.score.urgencyLabel;
  }

  static String _resourceNameFromDecision(ArcDecisionSignal signal) {
    return signal.title
        .replaceFirst(RegExp(r'^(Farm|Secure|Trade Surplus)\s+'), '')
        .trim();
  }
}
