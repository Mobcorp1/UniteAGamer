import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/feature_access_gate.dart';
import 'package:uag_arc_raiders_hub/features/notifications/data/uag_personalised_notification_mapper.dart';
import 'package:uag_arc_raiders_hub/features/notifications/models/uag_notification_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_command_centre_relevance_mapper.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_feature_registry.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_command_centre_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_user_personalisation_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/screens/trader_hub_screen.dart';

void main() {
  group('ArcUserPersonalisationProfile', () {
    test('round-trips typed preferences and ignores unknown enum strings', () {
      final profile = ArcUserPersonalisationProfile.fromMap({
        'schemaVersion': 1,
        'completed': true,
        'source': 'test',
        'goals': ['tradeBlueprints', 'not_a_goal'],
        'featureInterests': {
          'trading': 'primary',
          'ratRadar': 'primary',
          'unknownFeature': 'primary',
        },
        'commandCentre': {'density': 'balanced'},
        'squadPreference': 'duo',
        'notificationCategories': ['tradeActivity', 'futureRatRiskWarnings'],
        'showFutureSystems': false,
      });

      expect(profile.completed, isTrue);
      expect(profile.goals, contains(ArcPersonalisationGoal.tradeBlueprints));
      expect(
        profile.interestFor(ArcPersonalisationFeature.trading),
        ArcPersonalisationInterestLevel.primary,
      );
      expect(
        profile.interestFor(ArcPersonalisationFeature.ratRadar),
        ArcPersonalisationInterestLevel.off,
      );
      expect(profile.commandCentre.density, ArcCommandCentreDensity.balanced);
      expect(profile.squadPreference, ArcSoloSquadPreference.duo);
      expect(
        profile.includesNotificationCategory(
          ArcPersonalisationNotificationCategory.futureRatRiskWarnings,
        ),
        isFalse,
      );
      expect(profile.toMap()['schemaVersion'], 1);
    });

    test('round-trips Raider progression context safely', () {
      final profile = ArcUserPersonalisationProfile.fromMap(
        const <String, dynamic>{
          'schemaVersion': 1,
          'completed': true,
          'goals': <String>['completeBlueprints'],
          'progressStage': 'freshExpedition',
          'blueprintOwnership': 'none',
          'questProgress': 'continuing',
        },
      );

      expect(profile.progressStage, ArcRaiderProgressStage.freshExpedition);
      expect(
        profile.blueprintOwnership,
        ArcBlueprintOwnershipState.none,
      );
      expect(profile.questProgress, ArcQuestProgressState.continuing);
      expect(profile.hasProgressionContext, isTrue);
      expect(profile.toMap()['progressStage'], 'freshExpedition');
      expect(profile.toMap()['blueprintOwnership'], 'none');
      expect(profile.toMap()['questProgress'], 'continuing');
    });

    test('specific saved goals override legacy show-everything conflicts', () {
      final profile = ArcUserPersonalisationProfile.fromMap(
        const <String, dynamic>{
          'completed': true,
          'goals': <String>['exploreEverything', 'progressQuests'],
        },
      );

      expect(profile.goals, <ArcPersonalisationGoal>{
        ArcPersonalisationGoal.progressQuests,
      });
      expect(
        profile.interestFor(ArcPersonalisationFeature.trading),
        ArcPersonalisationInterestLevel.off,
      );
    });

    test('infers safe legacy interests without completing existing users', () {
      final profile = ArcUserPersonalisationProfile.inferFromLegacy(
        userData: {
          'arcOnboarding': {
            'currentPriority': ['Blueprint collection'],
            'playStyles': ['Trade swaps'],
          },
        },
        hasLoadout: true,
      );

      expect(profile.completed, isFalse);
      expect(profile.source, 'legacy_migration');
      expect(
        profile.interestFor(ArcPersonalisationFeature.blueprintTracker),
        ArcPersonalisationInterestLevel.high,
      );
      expect(
        profile.interestFor(ArcPersonalisationFeature.trading),
        ArcPersonalisationInterestLevel.high,
      );
      expect(
        profile.interestFor(ArcPersonalisationFeature.favouriteLoadout),
        ArcPersonalisationInterestLevel.high,
      );
      expect(
        profile.goals,
        isNot(contains(ArcPersonalisationGoal.exploreEverything)),
      );
      expect(
        profile.interestFor(ArcPersonalisationFeature.matchRider),
        ArcPersonalisationInterestLevel.off,
      );
    });

    test(
      'migrates the saved onboarding primary goal without show-all noise',
      () {
        final profile = ArcUserPersonalisationProfile.inferFromLegacy(
          userData: const <String, dynamic>{
            'arcOnboarding': <String, dynamic>{'primaryGoal': 'progressQuests'},
          },
        );

        expect(profile.goals, <ArcPersonalisationGoal>{
          ArcPersonalisationGoal.progressQuests,
        });
        expect(
          profile.interestFor(ArcPersonalisationFeature.questTracker),
          ArcPersonalisationInterestLevel.high,
        );
        expect(
          profile.interestFor(ArcPersonalisationFeature.trading),
          ArcPersonalisationInterestLevel.off,
        );
      },
    );

    test(
      'single specific goal is treated as an explicit focused preference',
      () {
        const profile = ArcUserPersonalisationProfile(
          goals: <ArcPersonalisationGoal>{
            ArcPersonalisationGoal.tradeBlueprints,
          },
          reduceNoise: true,
        );

        expect(profile.hasExplicitPreferences, isTrue);
        expect(
          profile.interestFor(ArcPersonalisationFeature.trading),
          isNot(ArcPersonalisationInterestLevel.off),
        );
        expect(
          profile.interestFor(ArcPersonalisationFeature.matchRider),
          ArcPersonalisationInterestLevel.off,
        );
      },
    );

    test('documents canonical Firestore path', () {
      expect(
        ArcUserPersonalisationRepository.profilePath('user-123'),
        'users/user-123/personalisation/profile',
      );
    });
  });

  group('focused onboarding visibility', () {
    test('completed focused profiles turn unrelated neutral systems off', () {
      const profile = ArcUserPersonalisationProfile(
        completed: true,
        goals: <ArcPersonalisationGoal>{
          ArcPersonalisationGoal.completeBlueprints,
        },
        featureInterests:
            <ArcPersonalisationFeature, ArcPersonalisationInterestLevel>{
              ArcPersonalisationFeature.blueprintTracker:
                  ArcPersonalisationInterestLevel.primary,
            },
        reduceNoise: true,
      );

      expect(
        profile.interestFor(ArcPersonalisationFeature.blueprintTracker),
        ArcPersonalisationInterestLevel.primary,
      );
      expect(
        profile.interestFor(ArcPersonalisationFeature.trading),
        ArcPersonalisationInterestLevel.off,
      );
      expect(
        profile.interestFor(ArcPersonalisationFeature.profile),
        ArcPersonalisationInterestLevel.normal,
      );
    });

    test('show me everything keeps the catalogue discoverable', () {
      const profile = ArcUserPersonalisationProfile(
        completed: true,
        goals: <ArcPersonalisationGoal>{
          ArcPersonalisationGoal.exploreEverything,
        },
        reduceNoise: true,
      );

      expect(
        profile.interestFor(ArcPersonalisationFeature.trading),
        ArcPersonalisationInterestLevel.normal,
      );
      expect(
        profile.interestFor(ArcPersonalisationFeature.matchRider),
        ArcPersonalisationInterestLevel.normal,
      );
    });
  });

  group('ArcCommandCentreRelevanceMapper', () {
    test(
      'promotes high-interest objectives without hiding critical blockers',
      () {
        final state = _commandState();
        final personalisation = const ArcUserPersonalisationProfile(
          goals: {ArcPersonalisationGoal.tradeBlueprints},
          featureInterests: {
            ArcPersonalisationFeature.trading:
                ArcPersonalisationInterestLevel.primary,
            ArcPersonalisationFeature.blueprintTracker:
                ArcPersonalisationInterestLevel.low,
          },
        );

        final mapped = ArcCommandCentreRelevanceMapper.apply(
          state: state,
          personalisation: personalisation,
        );

        expect(mapped.objectives.first.title, 'Create a Trade Listing');
        expect(mapped.priority.title, 'Create a Trade Listing');
        expect(mapped.alerts.first.title, 'Profile Setup Blocking');
      },
    );

    test('suppresses unrelated active noise for focused users', () {
      final state = _commandStateWithActiveTrade();
      const personalisation = ArcUserPersonalisationProfile(
        completed: true,
        goals: <ArcPersonalisationGoal>{
          ArcPersonalisationGoal.completeBlueprints,
        },
        featureInterests:
            <ArcPersonalisationFeature, ArcPersonalisationInterestLevel>{
              ArcPersonalisationFeature.blueprintTracker:
                  ArcPersonalisationInterestLevel.primary,
            },
        reduceNoise: true,
      );

      final mapped = ArcCommandCentreRelevanceMapper.apply(
        state: state,
        personalisation: personalisation,
      );

      expect(
        mapped.objectives.map((item) => item.title),
        isNot(contains('Active Trade Session')),
      );
    });
  });

  group('Play Like A Pro registry', () {
    test('registers Play Like A Pro as its own beta feature', () {
      final entry = ArcFeatureRegistry.byId('play_like_a_pro');
      expect(entry, isNotNull);
      expect(
        entry!.personalisationFeature,
        ArcPersonalisationFeature.playLikeAPro,
      );
      expect(entry.lifecycle, ArcFeatureLifecycle.beta);
      expect(entry.isRoutable, isTrue);
    });
  });
  group('feature registry diagnostics', () {
    test('keeps Rat surfaces dormant even when personalisation names them', () {
      const personalisation = ArcUserPersonalisationProfile(
        showFutureSystems: true,
        featureInterests: {
          ArcPersonalisationFeature.ratRadar:
              ArcPersonalisationInterestLevel.primary,
        },
      );

      final diagnostics = ArcFeatureVisibilityDiagnosticsEngine.build(
        personalisation: personalisation,
      );
      final ratRadar = diagnostics.firstWhere(
        (diagnostic) => diagnostic.entry.id == 'rat_radar',
      );

      expect(ratRadar.visible, isFalse);
      expect(ratRadar.reason, contains('Dormant future'));
      expect(
        ArcFeatureRegistry.entries
            .where((entry) => entry.isDormant)
            .every((entry) => !entry.isRoutable),
        isTrue,
      );
    });

    test('summarises the closed beta tracker configuration', () {
      const personalisation = ArcUserPersonalisationProfile(
        featureInterests: {
          ArcPersonalisationFeature.blueprintTracker:
              ArcPersonalisationInterestLevel.primary,
          ArcPersonalisationFeature.benchTracker:
              ArcPersonalisationInterestLevel.high,
          ArcPersonalisationFeature.scrappyTracker:
              ArcPersonalisationInterestLevel.high,
        },
      );

      final snapshot = ArcFeatureVisibilityDiagnosticsEngine.snapshot(
        personalisation: personalisation,
        featureAvailability: const {
          'canAccessBlueprintTracker': FeatureAvailability.live,
          'canAccessBenchTracker': FeatureAvailability.comingSoon,
          'canAccessScrappyTracker': FeatureAvailability.hidden,
        },
      );

      expect(snapshot.summary.liveCount, greaterThan(0));
      expect(snapshot.summary.comingSoonCount, greaterThan(0));
      expect(snapshot.summary.hiddenCount, greaterThan(0));
      expect(
        snapshot.summary.coreJourney.map((status) => status.label),
        containsAll(<String>[
          'Blueprint Tracker',
          'Bench Tracker',
          'Scrappy Tracker',
        ]),
      );
      expect(
        snapshot.summary.coreJourney
            .firstWhere((status) => status.label == 'Bench Tracker')
            .status,
        'Coming Soon',
      );
    });

    test('warns when all supported beta trackers are hidden', () {
      final snapshot = ArcFeatureVisibilityDiagnosticsEngine.snapshot(
        personalisation: ArcUserPersonalisationProfile.defaults,
        featureAvailability: const {
          'canAccessBlueprintTracker': FeatureAvailability.hidden,
          'canAccessBenchTracker': FeatureAvailability.hidden,
          'canAccessScrappyTracker': FeatureAvailability.hidden,
        },
      );

      expect(
        snapshot.summary.warnings,
        contains(
          'Command Centre is available but all supported beta tracker systems are hidden.',
        ),
      );
      expect(
        snapshot.summary.warnings,
        contains(
          'Blueprint Tracker is not Live. Closed Beta 2 expects it to be available.',
        ),
      );
    });
  });

  group('personalised notification mapper', () {
    test('maps canonical notification categories explainably', () {
      expect(
        UagPersonalisedNotificationMapper.categoryFor(
          UagNotificationType.tradeOffer,
        ),
        ArcPersonalisationNotificationCategory.tradeActivity,
      );
      expect(
        UagPersonalisedNotificationMapper.categoryFor(
          UagNotificationType.watchMatch,
        ),
        ArcPersonalisationNotificationCategory.listingMatches,
      );
    });
  });
}

const _openBlueprints = ArcCommandAction(
  label: 'Open Tracker',
  routeName: BlueprintGridScreen.routeName,
);

const _openTrading = ArcCommandAction(
  label: 'Create Listing',
  routeName: TraderHubScreen.routeName,
);

ArcCommandCentreState _commandState() {
  return ArcCommandCentreState(
    priority: const ArcCommandPriority(
      title: 'Stable',
      explanation: 'No urgent blockers.',
      progressLabel: 'Ready',
      statusTag: 'Stable',
      detail: 'Default priority.',
      status: ArcCommandStatus.success,
      primaryAction: _openBlueprints,
    ),
    snapshots: const [],
    objectives: const [
      ArcCommandObjective(
        title: 'Check Blueprint Tracker',
        reason: 'Review missing blueprints.',
        statusLabel: 'Optional',
        progressText: '2 missing',
        status: ArcCommandStatus.neutral,
        action: _openBlueprints,
      ),
      ArcCommandObjective(
        title: 'Create a Trade Listing',
        reason: 'Use duplicate blueprints for collection progress.',
        statusLabel: 'Recommended',
        progressText: '1 duplicate',
        status: ArcCommandStatus.neutral,
        action: _openTrading,
      ),
    ],
    alerts: const [
      ArcCommandAlert(
        title: 'Profile Setup Blocking',
        body: 'Profile still needs a field.',
        statusLabel: 'Required',
        status: ArcCommandStatus.critical,
        action: _openBlueprints,
      ),
    ],
    recommendations: const [],
    checklist: const [],
    resources: const [],
    tradeSummary: const ArcCommandTradeSummary(
      lookingFor: [],
      offering: [],
      actions: [],
    ),
    blueprintSummary: _panel('Blueprint Summary'),
    questSummary: _panel('Quest Summary'),
    benchSummary: _panel('Bench Summary'),
    operationsSummary: _panel('Operations Summary'),
    weeklyTraderSummary: _panel('Weekly Trader Summary'),
    resourceSummary: _panel('Resource Summary'),
    raidIntelligenceSummary: _panel('Raid Intelligence Summary'),
    decisionSummary: _panel('Decision Summary'),
    communitySummary: _panel('Community Summary'),
    statisticsSummary: _panel('Statistics Summary'),
  );
}

ArcCommandCentreState _commandStateWithActiveTrade() {
  final base = _commandState();
  return ArcCommandCentreState(
    priority: base.priority,
    snapshots: base.snapshots,
    objectives: <ArcCommandObjective>[
      ...base.objectives,
      const ArcCommandObjective(
        title: 'Active Trade Session',
        reason: 'A trade is currently active.',
        statusLabel: 'Active',
        progressText: 'In progress',
        status: ArcCommandStatus.active,
        action: _openTrading,
      ),
    ],
    alerts: base.alerts,
    recommendations: base.recommendations,
    checklist: base.checklist,
    resources: base.resources,
    tradeSummary: base.tradeSummary,
    blueprintSummary: base.blueprintSummary,
    questSummary: base.questSummary,
    benchSummary: base.benchSummary,
    operationsSummary: base.operationsSummary,
    weeklyTraderSummary: base.weeklyTraderSummary,
    resourceSummary: base.resourceSummary,
    raidIntelligenceSummary: base.raidIntelligenceSummary,
    decisionSummary: base.decisionSummary,
    communitySummary: base.communitySummary,
    statisticsSummary: base.statisticsSummary,
    onboardingFocus: base.onboardingFocus,
  );
}

ArcCommandSummaryPanel _panel(String title) {
  return ArcCommandSummaryPanel(
    title: title,
    statusLabel: 'Stable',
    body: 'Ready',
    details: const ['Ready'],
    status: ArcCommandStatus.success,
    action: _openBlueprints,
  );
}
