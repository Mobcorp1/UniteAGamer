import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/feature_access_gate.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_profile_completion_evaluator.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/raid_planner/screens/raid_planner_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_blueprint_watches_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trading_listing_queues_screen.dart';

void main() {
  group('ArcCommandCentreEngine route wiring', () {
    test('weekly raid checklist opens the real Raid Planner route', () {
      final state = ArcCommandCentreEngine.build(
        blueprintStates: const {},
        savedLoadouts: const [],
      );

      final weeklyRaid = state.checklist.singleWhere(
        (item) => item.id == 'weekly-raid',
      );

      expect(weeklyRaid.action.label, 'Raid Planner');
      expect(weeklyRaid.action.intent, ArcCommandActionIntent.route);
      expect(weeklyRaid.action.routeName, RaidPlannerScreen.routeName);
      expect(weeklyRaid.action.placeholderMessage, isNull);
    });

    test('trade objective queue and watch signals are actionable', () {
      final state = ArcCommandCentreEngine.build(
        blueprintStates: const {},
        savedLoadouts: const [],
        tradeActivity: const ArcCommandTradeActivity(
          communityListings: 0,
          myListings: 1,
          activeMyListings: 0,
          pendingOffers: 0,
          acceptedOffers: 0,
          activeSessions: 0,
          readySessions: 0,
          unreadNotifications: 0,
          activeBlueprintWatches: 1,
          matchedBlueprintWatches: 1,
          activeListingQueues: 1,
          releasableListingQueues: 1,
        ),
      );

      expect(
        state.tradeSummary.lookingFor.join(' '),
        contains('blueprint watch match'),
      );
      expect(state.tradeSummary.offering.join(' '), contains('queue release'));
      expect(
        state.tradeSummary.actions.map((action) => action.routeName),
        containsAll([
          TradingBlueprintWatchesScreen.routeName,
          TradingListingQueuesScreen.routeName,
        ]),
      );
      expect(
        state.objectives.map((objective) => objective.action.routeName),
        contains(TradingListingQueuesScreen.routeName),
      );
    });

    test('incomplete profile becomes the top current priority', () {
      final state = ArcCommandCentreEngine.build(
        blueprintStates: const {},
        savedLoadouts: const [],
        profileCompletion: const ArcProfileCompletionResult(
          missingFields: [
            ArcProfileCompletionMissingField(
              id: 'embarkId',
              label: 'Embark ID',
              routeName: ArcProfileCompletionEvaluator.profileSetupRouteName,
              section: 'identity',
            ),
          ],
        ),
      );

      expect(state.priority.title, 'Complete Your Hub Profile');
      expect(state.objectives.first.title, 'Complete Your Hub Profile');
      expect(
        state.objectives
            .where(
              (objective) => objective.title == 'Complete Your Hub Profile',
            )
            .length,
        1,
      );
      expect(
        state.objectives.first.action.routeName,
        ArcProfileCompletionEvaluator.profileSetupRouteName,
      );
    });

    test('complete profile does not inject setup objectives', () {
      final state = ArcCommandCentreEngine.build(
        blueprintStates: const {},
        savedLoadouts: const [],
        profileCompletion: ArcProfileCompletionResult.completeResult,
      );

      expect(
        state.objectives.map((objective) => objective.title),
        isNot(contains('Complete Your Hub Profile')),
      );
      expect(state.priority.title, isNot('Complete Your Hub Profile'));
    });

    test('interested Coming Soon features become actionable status cards', () {
      final state = ArcCommandCentreEngine.build(
        blueprintStates: const {},
        savedLoadouts: const [],
        personalisation: const ArcUserPersonalisationProfile(
          featureInterests:
              <ArcPersonalisationFeature, ArcPersonalisationInterestLevel>{
                ArcPersonalisationFeature.raidIntelligence:
                    ArcPersonalisationInterestLevel.primary,
              },
        ),
        featureAvailability: const <String, FeatureAvailability>{
          FeatureAccessFlag.intelExplorer: FeatureAvailability.comingSoon,
        },
      );

      final recommendation = state.recommendations.singleWhere(
        (item) => item.title == 'Raid Intelligence Coming Soon',
      );
      expect(recommendation.action.intent, ArcCommandActionIntent.comingSoon);
      expect(recommendation.action.featureTitle, 'Raid Intelligence');
      expect(recommendation.action.placeholderMessage, contains('cannot be'));
    });
  });
}
