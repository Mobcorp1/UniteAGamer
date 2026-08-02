import 'package:uag_arc_raiders_hub/features/profile/screens/profile_settings_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_hunt_targets_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_availability_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_match_rider_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_profile_setup_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_progress_trackers_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/operations_command_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/scrappy_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_blueprint_watches_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_create_listing_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart';

class ArcCommandCentreRelevanceMapper {
  const ArcCommandCentreRelevanceMapper._();

  static ArcCommandCentreState apply({
    required ArcCommandCentreState state,
    required ArcUserPersonalisationProfile personalisation,
  }) {
    final objectives = _rankAndFilter(
      state.objectives,
      personalisation,
      featureForObjective,
      (item) => item.status,
    );
    final alerts = _rankAndFilter(
      state.alerts,
      personalisation,
      featureForAlert,
      (item) => item.status,
    );
    final recommendations = _rankAndFilter(
      state.recommendations,
      personalisation,
      featureForRecommendation,
      (_) => ArcCommandStatus.neutral,
    );
    final snapshots = _rankAndFilter(
      state.snapshots,
      personalisation,
      featureForSnapshot,
      (item) => item.status,
    );

    return ArcCommandCentreState(
      priority: _priorityFor(state.priority, objectives, personalisation),
      snapshots: snapshots,
      objectives: objectives,
      alerts: alerts,
      recommendations: recommendations,
      checklist: _rankChecklist(state.checklist, personalisation),
      resources: state.resources,
      tradeSummary: state.tradeSummary,
      blueprintSummary: state.blueprintSummary,
      questSummary: state.questSummary,
      benchSummary: state.benchSummary,
      operationsSummary: state.operationsSummary,
      weeklyTraderSummary: state.weeklyTraderSummary,
      resourceSummary: state.resourceSummary,
      raidIntelligenceSummary: state.raidIntelligenceSummary,
      decisionSummary: state.decisionSummary,
      communitySummary: state.communitySummary,
      statisticsSummary: state.statisticsSummary,
      onboardingFocus: state.onboardingFocus,
    );
  }

  static ArcPersonalisationFeature featureForAction(ArcCommandAction action) {
    final route = action.routeName ?? '';
    if (route == ArcProfileSetupScreen.routeName ||
        route == ProfileSettingsScreen.routeName) {
      return ArcPersonalisationFeature.profile;
    }
    if (route == ArcAvailabilityScreen.routeName) {
      return ArcPersonalisationFeature.availability;
    }
    if (route == BlueprintGridScreen.routeName) {
      return ArcPersonalisationFeature.blueprintTracker;
    }
    if (route == FavouriteLoadoutScreen.routeName) {
      return ArcPersonalisationFeature.favouriteLoadout;
    }
    if (route == ArcProgressTrackersScreen.routeName ||
        route == ScrappyGridScreen.routeName) {
      return ArcPersonalisationFeature.scrappyTracker;
    }
    if (route == ScrappyGridScreen.questRouteName) {
      return ArcPersonalisationFeature.questTracker;
    }
    if (route == ScrappyGridScreen.benchRouteName) {
      return ArcPersonalisationFeature.benchTracker;
    }
    if (route == TraderHubScreen.routeName ||
        route == TradingCreateListingScreen.routeName ||
        route == SmartTradeAssistScreen.routeName) {
      return ArcPersonalisationFeature.trading;
    }
    if (route == TradingBlueprintWatchesScreen.routeName) {
      return ArcPersonalisationFeature.blueprintWatches;
    }
    if (route == TradingNotificationsScreen.routeName) {
      return ArcPersonalisationFeature.communications;
    }
    if (route == ArcMatchRiderScreen.routeName) {
      return ArcPersonalisationFeature.matchRider;
    }
    if (route == RaidPlannerScreen.routeName) {
      return ArcPersonalisationFeature.raidPlanner;
    }
    if (route == RaidPlannerHuntTargetsScreen.routeName) {
      return ArcPersonalisationFeature.huntTargets;
    }
    if (route == ArcRaidIntelligenceScreen.routeName) {
      return ArcPersonalisationFeature.raidIntelligence;
    }
    if (route == OperationsCommandScreen.routeName) {
      return ArcPersonalisationFeature.operations;
    }
    if (route == '/trading-hub/arc-raiders/command-centre' ||
        route == '/my-hub') {
      return ArcPersonalisationFeature.profile;
    }
    return _featureForText('${action.label} ${action.placeholderMessage}');
  }

  static ArcPersonalisationFeature featureForObjective(
    ArcCommandObjective objective,
  ) {
    final actionFeature = featureForAction(objective.action);
    if (actionFeature != ArcPersonalisationFeature.profile) {
      return actionFeature;
    }
    return _featureForText(
      '${objective.title} ${objective.reason} ${objective.statusLabel}',
    );
  }

  static ArcPersonalisationFeature featureForAlert(ArcCommandAlert alert) {
    final actionFeature = featureForAction(alert.action);
    if (actionFeature != ArcPersonalisationFeature.profile) {
      return actionFeature;
    }
    return _featureForText('${alert.title} ${alert.body} ${alert.statusLabel}');
  }

  static ArcPersonalisationFeature featureForRecommendation(
    ArcCommandRecommendation recommendation,
  ) {
    final actionFeature = featureForAction(recommendation.action);
    if (actionFeature != ArcPersonalisationFeature.profile) {
      return actionFeature;
    }
    return _featureForText('${recommendation.title} ${recommendation.body}');
  }

  static ArcPersonalisationFeature featureForSnapshot(
    ArcCommandSnapshotMetric metric,
  ) {
    return _featureForText('${metric.label} ${metric.detail}');
  }

  static ArcPersonalisationFeature _featureForText(String value) {
    final text = value.toLowerCase();
    if (text.contains('blueprint') || text.contains('collection')) {
      return ArcPersonalisationFeature.blueprintTracker;
    }
    if (text.contains('trade') ||
        text.contains('listing') ||
        text.contains('offer') ||
        text.contains('queue')) {
      return ArcPersonalisationFeature.trading;
    }
    if (text.contains('match') ||
        text.contains('squad') ||
        text.contains('rider')) {
      return ArcPersonalisationFeature.matchRider;
    }
    if (text.contains('loadout') ||
        text.contains('weapon') ||
        text.contains('attachment')) {
      return ArcPersonalisationFeature.favouriteLoadout;
    }
    if (text.contains('quest')) {
      return ArcPersonalisationFeature.questTracker;
    }
    if (text.contains('bench') ||
        text.contains('upgrade') ||
        text.contains('station')) {
      return ArcPersonalisationFeature.benchTracker;
    }
    if (text.contains('resource') ||
        text.contains('scrappy') ||
        text.contains('farm')) {
      return ArcPersonalisationFeature.scrappyTracker;
    }
    if (text.contains('raid') || text.contains('map')) {
      return ArcPersonalisationFeature.raidIntelligence;
    }
    if (text.contains('operation') || text.contains('reward')) {
      return ArcPersonalisationFeature.operations;
    }
    if (text.contains('trader') || text.contains('nomadic')) {
      return ArcPersonalisationFeature.nomadicTrader;
    }
    if (text.contains('notification') || text.contains('communication')) {
      return ArcPersonalisationFeature.communications;
    }
    return ArcPersonalisationFeature.profile;
  }

  static ArcCommandPriority _priorityFor(
    ArcCommandPriority current,
    List<ArcCommandObjective> rankedObjectives,
    ArcUserPersonalisationProfile personalisation,
  ) {
    if (current.status == ArcCommandStatus.critical) return current;
    if (rankedObjectives.isEmpty) return current;

    final currentFeature = featureForAction(current.primaryAction);
    final currentWeight = personalisation.interestFor(currentFeature).weight;
    final topObjective = rankedObjectives.first;
    final topFeature = featureForObjective(topObjective);
    final topWeight = personalisation.interestFor(topFeature).weight;
    if (topWeight <= currentWeight ||
        topObjective.status == ArcCommandStatus.success) {
      return current;
    }
    return ArcCommandPriority(
      title: topObjective.title,
      explanation: topObjective.reason,
      progressLabel: topObjective.progressText,
      statusTag: topObjective.statusLabel,
      detail:
          'Prioritised from your saved ${topFeature.label.toLowerCase()} preference.',
      status: topObjective.status,
      primaryAction: topObjective.action,
      secondaryAction: current.primaryAction,
    );
  }

  static List<ArcCommandChecklistItem> _rankChecklist(
    List<ArcCommandChecklistItem> checklist,
    ArcUserPersonalisationProfile personalisation,
  ) {
    final items = [...checklist];
    items.sort((left, right) {
      final leftScore =
          personalisation.interestFor(featureForAction(left.action)).weight +
          (left.doneByDefault ? -20 : 0);
      final rightScore =
          personalisation.interestFor(featureForAction(right.action)).weight +
          (right.doneByDefault ? -20 : 0);
      return rightScore.compareTo(leftScore);
    });
    return items;
  }

  static List<T> _rankAndFilter<T>(
    List<T> items,
    ArcUserPersonalisationProfile personalisation,
    ArcPersonalisationFeature Function(T item) featureFor,
    ArcCommandStatus Function(T item) statusFor,
  ) {
    final indexed = <_RankedCommandItem<T>>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final status = statusFor(item);
      final feature = featureFor(item);
      final level = personalisation.interestFor(feature);
      if (personalisation.reduceNoise && !level.isVisible && _canHide(status)) {
        continue;
      }
      indexed.add(
        _RankedCommandItem<T>(
          item: item,
          index: i,
          score: _statusWeight(status) + level.weight,
        ),
      );
    }
    indexed.sort((left, right) {
      final scoreCompare = right.score.compareTo(left.score);
      if (scoreCompare != 0) return scoreCompare;
      return left.index.compareTo(right.index);
    });
    return indexed.map((entry) => entry.item).toList(growable: false);
  }

  static bool _canHide(ArcCommandStatus status) {
    return status == ArcCommandStatus.neutral ||
        status == ArcCommandStatus.success;
  }

  static int _statusWeight(ArcCommandStatus status) {
    switch (status) {
      case ArcCommandStatus.critical:
        return 1000;
      case ArcCommandStatus.warning:
        return 800;
      case ArcCommandStatus.ready:
        return 700;
      case ArcCommandStatus.active:
        return 500;
      case ArcCommandStatus.neutral:
        return 100;
      case ArcCommandStatus.success:
        return 0;
    }
  }
}

class _RankedCommandItem<T> {
  const _RankedCommandItem({
    required this.item,
    required this.index,
    required this.score,
  });

  final T item;
  final int index;
  final int score;
}
