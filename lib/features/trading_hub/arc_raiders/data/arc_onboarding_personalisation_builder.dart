import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_user_personalisation_profile.dart';

ArcUserPersonalisationProfile buildArcOnboardingPersonalisation({
  required ArcPersonalisationGoal primaryGoal,
  Set<ArcPersonalisationGoal> secondaryGoals = const {},
  DateTime? completedAt,
}) {
  final goals = <ArcPersonalisationGoal>{primaryGoal, ...secondaryGoals};
  final interests =
      <ArcPersonalisationFeature, ArcPersonalisationInterestLevel>{};

  void raise(
    ArcPersonalisationFeature feature,
    ArcPersonalisationInterestLevel level,
  ) {
    final current = interests[feature];
    if (current == null || level.weight > current.weight) {
      interests[feature] = level;
    }
  }

  void applyGoal(
    ArcPersonalisationGoal goal,
    ArcPersonalisationInterestLevel level,
  ) {
    for (final feature in arcOnboardingFeaturesForGoal(goal)) {
      raise(feature, level);
    }
  }

  applyGoal(primaryGoal, ArcPersonalisationInterestLevel.primary);
  for (final goal in secondaryGoals) {
    if (goal != primaryGoal) {
      applyGoal(goal, ArcPersonalisationInterestLevel.high);
    }
  }

  return ArcUserPersonalisationProfile(
    completed: true,
    completedAt: completedAt ?? DateTime.now(),
    source: 'progressive_onboarding_v4',
    goals: goals,
    featureInterests: interests,
    commandCentre: ArcCommandCentrePreferenceSet(
      density: ArcCommandCentreDensity.compact,
      dailyMissions: true,
      recommendations: true,
      riskWarnings: true,
      tradeActivity: goals.contains(ArcPersonalisationGoal.tradeBlueprints),
      socialActivity: goals.contains(ArcPersonalisationGoal.findSquads),
      progressionCards:
          goals.contains(ArcPersonalisationGoal.completeBlueprints) ||
          goals.contains(ArcPersonalisationGoal.progressQuests) ||
          goals.contains(ArcPersonalisationGoal.upgradeBench) ||
          goals.contains(ArcPersonalisationGoal.trackResources),
      upcomingAvailability: goals.contains(ArcPersonalisationGoal.findSquads),
      trackerSummaries: true,
      raidPreparation: goals.contains(ArcPersonalisationGoal.planRaids),
      systemShortcuts: true,
    ),
    squadPreference: ArcSoloSquadPreference.flexible,
    notificationCategories: arcDefaultPersonalisationNotificationCategories,
    reduceNoise: true,
  );
}

Set<ArcPersonalisationFeature> arcOnboardingFeaturesForGoal(
  ArcPersonalisationGoal goal,
) {
  switch (goal) {
    case ArcPersonalisationGoal.exploreEverything:
      return const {
        ArcPersonalisationFeature.blueprintTracker,
        ArcPersonalisationFeature.raidIntelligence,
        ArcPersonalisationFeature.questTracker,
        ArcPersonalisationFeature.trading,
      };
    case ArcPersonalisationGoal.completeBlueprints:
      return const {
        ArcPersonalisationFeature.blueprintTracker,
        ArcPersonalisationFeature.blueprintIntelligence,
        ArcPersonalisationFeature.blueprintWatches,
        ArcPersonalisationFeature.raidIntelligence,
      };
    case ArcPersonalisationGoal.tradeBlueprints:
      return const {
        ArcPersonalisationFeature.trading,
        ArcPersonalisationFeature.smartTrade,
        ArcPersonalisationFeature.communications,
      };
    case ArcPersonalisationGoal.buildFavouriteLoadout:
      return const {ArcPersonalisationFeature.favouriteLoadout};
    case ArcPersonalisationGoal.progressQuests:
      return const {
        ArcPersonalisationFeature.questTracker,
        ArcPersonalisationFeature.scrappyTracker,
      };
    case ArcPersonalisationGoal.upgradeBench:
      return const {
        ArcPersonalisationFeature.benchTracker,
        ArcPersonalisationFeature.scrappyTracker,
      };
    case ArcPersonalisationGoal.trackResources:
      return const {
        ArcPersonalisationFeature.scrappyTracker,
        ArcPersonalisationFeature.nomadicTrader,
      };
    case ArcPersonalisationGoal.planRaids:
      return const {
        ArcPersonalisationFeature.raidPlanner,
        ArcPersonalisationFeature.raidIntelligence,
        ArcPersonalisationFeature.huntTargets,
      };
    case ArcPersonalisationGoal.findSquads:
      return const {
        ArcPersonalisationFeature.matchRider,
        ArcPersonalisationFeature.availability,
        ArcPersonalisationFeature.favouriteRiders,
      };
    case ArcPersonalisationGoal.followOperations:
      return const {ArcPersonalisationFeature.operations};
    case ArcPersonalisationGoal.manageCosmetics:
      return const {
        ArcPersonalisationFeature.rewardVault,
        ArcPersonalisationFeature.operations,
      };
    case ArcPersonalisationGoal.receiveCommunityIntel:
      return const {
        ArcPersonalisationFeature.communityIntel,
        ArcPersonalisationFeature.raidIntelligence,
      };
    case ArcPersonalisationGoal.improveReputation:
      return const {ArcPersonalisationFeature.profile};
  }
}

String arcOnboardingRecommendedSystem(ArcPersonalisationGoal goal) {
  switch (goal) {
    case ArcPersonalisationGoal.completeBlueprints:
      return 'blueprintTracker';
    case ArcPersonalisationGoal.tradeBlueprints:
      return 'trading';
    case ArcPersonalisationGoal.buildFavouriteLoadout:
      return 'favouriteLoadout';
    case ArcPersonalisationGoal.progressQuests:
      return 'questTracker';
    case ArcPersonalisationGoal.upgradeBench:
      return 'benchTracker';
    case ArcPersonalisationGoal.trackResources:
      return 'scrappyTracker';
    case ArcPersonalisationGoal.planRaids:
      return 'raidIntelligence';
    case ArcPersonalisationGoal.findSquads:
      return 'matchRider';
    case ArcPersonalisationGoal.followOperations:
      return 'operations';
    case ArcPersonalisationGoal.manageCosmetics:
      return 'rewardVault';
    case ArcPersonalisationGoal.receiveCommunityIntel:
      return 'communityIntel';
    case ArcPersonalisationGoal.improveReputation:
      return 'profile';
    case ArcPersonalisationGoal.exploreEverything:
      return 'commandCentre';
  }
}
