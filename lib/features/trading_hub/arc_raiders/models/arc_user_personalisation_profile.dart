import 'package:cloud_firestore/cloud_firestore.dart';

enum ArcPersonalisationInterestLevel { off, low, normal, high, primary }

enum ArcPersonalisationGoal {
  exploreEverything,
  completeBlueprints,
  tradeBlueprints,
  buildFavouriteLoadout,
  progressQuests,
  upgradeBench,
  trackResources,
  planRaids,
  findSquads,
  followOperations,
  manageCosmetics,
  receiveCommunityIntel,
  improveReputation,
}

enum ArcPersonalisationFeature {
  profile,
  availability,
  blueprintTracker,
  blueprintIntelligence,
  blueprintWatches,
  trading,
  smartTrade,
  matchRider,
  favouriteRiders,
  privateRiders,
  questTracker,
  benchTracker,
  scrappyTracker,
  raidPlanner,
  huntTargets,
  raidIntelligence,
  communityIntel,
  communications,
  notifications,
  voiceAssistant,
  playLikeAPro,
  favouriteLoadout,
  playerLockerPro,
  operations,
  rewardVault,
  nomadicTrader,
  reportARat,
  huntARat,
  ratRadar,
  giftSubscriptions,
  settings,
}

enum ArcCommandCentreDensity { compact, balanced, detailed }

enum ArcSoloSquadPreference { solo, duo, squad, flexible }

enum ArcPersonalisationNotificationCategory {
  tradeActivity,
  listingMatches,
  blueprintWatches,
  favouriteRiderActivity,
  matchRiderActivity,
  availabilityReminders,
  questProgress,
  benchProgress,
  scrappyProgress,
  raidIntelligence,
  systemAnnouncements,
  futureBountyActivity,
  futureRatRiskWarnings,
}

const arcDefaultPersonalisationNotificationCategories =
    <ArcPersonalisationNotificationCategory>{
      ArcPersonalisationNotificationCategory.tradeActivity,
      ArcPersonalisationNotificationCategory.listingMatches,
      ArcPersonalisationNotificationCategory.blueprintWatches,
      ArcPersonalisationNotificationCategory.matchRiderActivity,
      ArcPersonalisationNotificationCategory.availabilityReminders,
      ArcPersonalisationNotificationCategory.questProgress,
      ArcPersonalisationNotificationCategory.benchProgress,
      ArcPersonalisationNotificationCategory.scrappyProgress,
      ArcPersonalisationNotificationCategory.raidIntelligence,
      ArcPersonalisationNotificationCategory.systemAnnouncements,
    };

extension ArcPersonalisationInterestLevelX on ArcPersonalisationInterestLevel {
  int get weight {
    switch (this) {
      case ArcPersonalisationInterestLevel.off:
        return -100;
      case ArcPersonalisationInterestLevel.low:
        return -10;
      case ArcPersonalisationInterestLevel.normal:
        return 0;
      case ArcPersonalisationInterestLevel.high:
        return 25;
      case ArcPersonalisationInterestLevel.primary:
        return 50;
    }
  }

  bool get isVisible => this != ArcPersonalisationInterestLevel.off;
  bool get isHighSignal =>
      this == ArcPersonalisationInterestLevel.high ||
      this == ArcPersonalisationInterestLevel.primary;
}

extension ArcPersonalisationGoalX on ArcPersonalisationGoal {
  String get label {
    switch (this) {
      case ArcPersonalisationGoal.exploreEverything:
        return 'Explore Everything';
      case ArcPersonalisationGoal.completeBlueprints:
        return 'Complete Blueprints';
      case ArcPersonalisationGoal.tradeBlueprints:
        return 'Trade Blueprints';
      case ArcPersonalisationGoal.buildFavouriteLoadout:
        return 'Build Favourite Loadout';
      case ArcPersonalisationGoal.progressQuests:
        return 'Progress Quests';
      case ArcPersonalisationGoal.upgradeBench:
        return 'Upgrade Bench';
      case ArcPersonalisationGoal.trackResources:
        return 'Track Resources';
      case ArcPersonalisationGoal.planRaids:
        return 'Plan Raids';
      case ArcPersonalisationGoal.findSquads:
        return 'Find Squads';
      case ArcPersonalisationGoal.followOperations:
        return 'Follow Operations';
      case ArcPersonalisationGoal.manageCosmetics:
        return 'Manage Cosmetics';
      case ArcPersonalisationGoal.receiveCommunityIntel:
        return 'Receive Community Intel';
      case ArcPersonalisationGoal.improveReputation:
        return 'Improve Reputation';
    }
  }
}

extension ArcPersonalisationFeatureX on ArcPersonalisationFeature {
  String get label {
    switch (this) {
      case ArcPersonalisationFeature.profile:
        return 'Profile';
      case ArcPersonalisationFeature.availability:
        return 'Availability';
      case ArcPersonalisationFeature.blueprintTracker:
        return 'Blueprint Tracker';
      case ArcPersonalisationFeature.blueprintIntelligence:
        return 'Blueprint Intelligence';
      case ArcPersonalisationFeature.blueprintWatches:
        return 'Blueprint Watches';
      case ArcPersonalisationFeature.trading:
        return 'Trading';
      case ArcPersonalisationFeature.smartTrade:
        return 'Smart Trade';
      case ArcPersonalisationFeature.matchRider:
        return 'Match Raider';
      case ArcPersonalisationFeature.favouriteRiders:
        return 'Favourite Raiders';
      case ArcPersonalisationFeature.privateRiders:
        return 'Private Raiders';
      case ArcPersonalisationFeature.questTracker:
        return 'Quest Tracker';
      case ArcPersonalisationFeature.benchTracker:
        return 'Bench Tracker';
      case ArcPersonalisationFeature.scrappyTracker:
        return 'Scrappy Tracker';
      case ArcPersonalisationFeature.raidPlanner:
        return 'Raid Planner';
      case ArcPersonalisationFeature.huntTargets:
        return 'Hunt Targets';
      case ArcPersonalisationFeature.raidIntelligence:
        return 'Raid Intelligence';
      case ArcPersonalisationFeature.communityIntel:
        return 'Community Intel';
      case ArcPersonalisationFeature.communications:
        return 'Communications';
      case ArcPersonalisationFeature.notifications:
        return 'Notifications';
      case ArcPersonalisationFeature.voiceAssistant:
        return 'Voice Assistant';
      case ArcPersonalisationFeature.playLikeAPro:
        return 'Play Like A Pro';
      case ArcPersonalisationFeature.favouriteLoadout:
        return 'Favourite Loadout';
      case ArcPersonalisationFeature.playerLockerPro:
        return 'Player Locker Pro';
      case ArcPersonalisationFeature.operations:
        return 'Operations';
      case ArcPersonalisationFeature.rewardVault:
        return 'Reward Vault';
      case ArcPersonalisationFeature.nomadicTrader:
        return 'Nomadic Trader';
      case ArcPersonalisationFeature.reportARat:
        return 'Report A Rat';
      case ArcPersonalisationFeature.huntARat:
        return 'Hunt A Rat';
      case ArcPersonalisationFeature.ratRadar:
        return 'Rat Radar';
      case ArcPersonalisationFeature.giftSubscriptions:
        return 'Gift Subscriptions';
      case ArcPersonalisationFeature.settings:
        return 'Settings';
    }
  }

  bool get isFutureOnly =>
      this == ArcPersonalisationFeature.reportARat ||
      this == ArcPersonalisationFeature.huntARat ||
      this == ArcPersonalisationFeature.ratRadar ||
      this == ArcPersonalisationFeature.giftSubscriptions;
}

class ArcCommandCentrePreferenceSet {
  const ArcCommandCentrePreferenceSet({
    this.density = ArcCommandCentreDensity.compact,
    this.dailyMissions = true,
    this.recommendations = true,
    this.riskWarnings = true,
    this.tradeActivity = true,
    this.socialActivity = true,
    this.progressionCards = true,
    this.upcomingAvailability = true,
    this.trackerSummaries = true,
    this.raidPreparation = true,
    this.systemShortcuts = true,
  });

  final ArcCommandCentreDensity density;
  final bool dailyMissions;
  final bool recommendations;
  final bool riskWarnings;
  final bool tradeActivity;
  final bool socialActivity;
  final bool progressionCards;
  final bool upcomingAvailability;
  final bool trackerSummaries;
  final bool raidPreparation;
  final bool systemShortcuts;

  static const defaults = ArcCommandCentrePreferenceSet();

  Map<String, dynamic> toMap() {
    return {
      'density': density.name,
      'dailyMissions': dailyMissions,
      'recommendations': recommendations,
      'riskWarnings': riskWarnings,
      'tradeActivity': tradeActivity,
      'socialActivity': socialActivity,
      'progressionCards': progressionCards,
      'upcomingAvailability': upcomingAvailability,
      'trackerSummaries': trackerSummaries,
      'raidPreparation': raidPreparation,
      'systemShortcuts': systemShortcuts,
    };
  }

  static ArcCommandCentrePreferenceSet fromMap(Object? value) {
    if (value is! Map) return defaults;
    final map = value.cast<String, dynamic>();
    return ArcCommandCentrePreferenceSet(
      density: _enumByName(
        ArcCommandCentreDensity.values,
        map['density'],
        ArcCommandCentreDensity.compact,
      ),
      dailyMissions: _boolValue(map['dailyMissions'], true),
      recommendations: _boolValue(map['recommendations'], true),
      riskWarnings: _boolValue(map['riskWarnings'], true),
      tradeActivity: _boolValue(map['tradeActivity'], true),
      socialActivity: _boolValue(map['socialActivity'], true),
      progressionCards: _boolValue(map['progressionCards'], true),
      upcomingAvailability: _boolValue(map['upcomingAvailability'], true),
      trackerSummaries: _boolValue(map['trackerSummaries'], true),
      raidPreparation: _boolValue(map['raidPreparation'], true),
      systemShortcuts: _boolValue(map['systemShortcuts'], true),
    );
  }

  ArcCommandCentrePreferenceSet copyWith({
    ArcCommandCentreDensity? density,
    bool? dailyMissions,
    bool? recommendations,
    bool? riskWarnings,
    bool? tradeActivity,
    bool? socialActivity,
    bool? progressionCards,
    bool? upcomingAvailability,
    bool? trackerSummaries,
    bool? raidPreparation,
    bool? systemShortcuts,
  }) {
    return ArcCommandCentrePreferenceSet(
      density: density ?? this.density,
      dailyMissions: dailyMissions ?? this.dailyMissions,
      recommendations: recommendations ?? this.recommendations,
      riskWarnings: riskWarnings ?? this.riskWarnings,
      tradeActivity: tradeActivity ?? this.tradeActivity,
      socialActivity: socialActivity ?? this.socialActivity,
      progressionCards: progressionCards ?? this.progressionCards,
      upcomingAvailability: upcomingAvailability ?? this.upcomingAvailability,
      trackerSummaries: trackerSummaries ?? this.trackerSummaries,
      raidPreparation: raidPreparation ?? this.raidPreparation,
      systemShortcuts: systemShortcuts ?? this.systemShortcuts,
    );
  }
}

class ArcUserPersonalisationProfile {
  const ArcUserPersonalisationProfile({
    this.schemaVersion = currentSchemaVersion,
    this.completed = false,
    this.completedAt,
    this.migratedAt,
    this.updatedAt,
    this.source = 'default',
    this.goals = const <ArcPersonalisationGoal>{
      ArcPersonalisationGoal.exploreEverything,
    },
    this.featureInterests =
        const <ArcPersonalisationFeature, ArcPersonalisationInterestLevel>{},
    this.commandCentre = ArcCommandCentrePreferenceSet.defaults,
    this.squadPreference = ArcSoloSquadPreference.flexible,
    this.notificationCategories =
        arcDefaultPersonalisationNotificationCategories,
    this.archetypeIds = const <String>{},
    this.playStyleIds = const <String>{},
    this.showFutureSystems = false,
    this.reduceNoise = true,
  });

  static const int currentSchemaVersion = 1;
  static const defaults = ArcUserPersonalisationProfile();

  final int schemaVersion;
  final bool completed;
  final DateTime? completedAt;
  final DateTime? migratedAt;
  final DateTime? updatedAt;
  final String source;
  final Set<ArcPersonalisationGoal> goals;
  final Map<ArcPersonalisationFeature, ArcPersonalisationInterestLevel>
  featureInterests;
  final ArcCommandCentrePreferenceSet commandCentre;
  final ArcSoloSquadPreference squadPreference;
  final Set<ArcPersonalisationNotificationCategory> notificationCategories;
  final Set<String> archetypeIds;
  final Set<String> playStyleIds;
  final bool showFutureSystems;
  final bool reduceNoise;

  bool get isCurrentSchema => schemaVersion >= currentSchemaVersion;
  bool get hasExplicitPreferences =>
      completed || featureInterests.isNotEmpty || goals.length > 1;

  ArcPersonalisationInterestLevel interestFor(
    ArcPersonalisationFeature feature,
  ) {
    if (feature.isFutureOnly && !showFutureSystems) {
      return ArcPersonalisationInterestLevel.off;
    }
    final explicit = featureInterests[feature];
    if (explicit != null) return explicit;
    final inferred = _inferredInterestFor(feature, goals);
    if (inferred != null) return inferred;
    return ArcPersonalisationInterestLevel.normal;
  }

  bool includesNotificationCategory(
    ArcPersonalisationNotificationCategory category,
  ) {
    if ((category ==
                ArcPersonalisationNotificationCategory.futureBountyActivity ||
            category ==
                ArcPersonalisationNotificationCategory.futureRatRiskWarnings) &&
        !showFutureSystems) {
      return false;
    }
    return notificationCategories.contains(category);
  }

  ArcUserPersonalisationProfile copyWith({
    int? schemaVersion,
    bool? completed,
    DateTime? completedAt,
    DateTime? migratedAt,
    DateTime? updatedAt,
    String? source,
    Set<ArcPersonalisationGoal>? goals,
    Map<ArcPersonalisationFeature, ArcPersonalisationInterestLevel>?
    featureInterests,
    ArcCommandCentrePreferenceSet? commandCentre,
    ArcSoloSquadPreference? squadPreference,
    Set<ArcPersonalisationNotificationCategory>? notificationCategories,
    Set<String>? archetypeIds,
    Set<String>? playStyleIds,
    bool? showFutureSystems,
    bool? reduceNoise,
  }) {
    return ArcUserPersonalisationProfile(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      migratedAt: migratedAt ?? this.migratedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      goals: goals ?? this.goals,
      featureInterests: featureInterests ?? this.featureInterests,
      commandCentre: commandCentre ?? this.commandCentre,
      squadPreference: squadPreference ?? this.squadPreference,
      notificationCategories:
          notificationCategories ?? this.notificationCategories,
      archetypeIds: archetypeIds ?? this.archetypeIds,
      playStyleIds: playStyleIds ?? this.playStyleIds,
      showFutureSystems: showFutureSystems ?? this.showFutureSystems,
      reduceNoise: reduceNoise ?? this.reduceNoise,
    );
  }

  ArcUserPersonalisationProfile withInterest(
    ArcPersonalisationFeature feature,
    ArcPersonalisationInterestLevel level,
  ) {
    return copyWith(featureInterests: {...featureInterests, feature: level});
  }

  ArcUserPersonalisationProfile merge(ArcUserPersonalisationProfile other) {
    return copyWith(
      schemaVersion: currentSchemaVersion,
      completed: completed || other.completed,
      completedAt: other.completedAt ?? completedAt,
      migratedAt: other.migratedAt ?? migratedAt,
      updatedAt: other.updatedAt ?? updatedAt,
      source: other.source == 'default' ? source : other.source,
      goals: {...goals, ...other.goals},
      featureInterests: {...featureInterests, ...other.featureInterests},
      commandCentre: other.commandCentre,
      squadPreference: other.squadPreference,
      notificationCategories: {
        ...notificationCategories,
        ...other.notificationCategories,
      },
      archetypeIds: {...archetypeIds, ...other.archetypeIds},
      playStyleIds: {...playStyleIds, ...other.playStyleIds},
      showFutureSystems: showFutureSystems || other.showFutureSystems,
      reduceNoise: other.reduceNoise,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schemaVersion': schemaVersion,
      'completed': completed,
      'completedAt': completedAt,
      'migratedAt': migratedAt,
      'updatedAt': updatedAt,
      'source': source,
      'goals': goals.map((goal) => goal.name).toList(growable: false),
      'featureInterests': {
        for (final entry in featureInterests.entries)
          entry.key.name: entry.value.name,
      },
      'commandCentre': commandCentre.toMap(),
      'squadPreference': squadPreference.name,
      'notificationCategories': notificationCategories
          .map((category) => category.name)
          .toList(growable: false),
      'archetypeIds': archetypeIds.toList(growable: false),
      'playStyleIds': playStyleIds.toList(growable: false),
      'showFutureSystems': showFutureSystems,
      'reduceNoise': reduceNoise,
    };
  }

  static ArcUserPersonalisationProfile fromMap(Object? value) {
    if (value is! Map) return defaults;
    final map = value.cast<String, dynamic>();
    final interests =
        <ArcPersonalisationFeature, ArcPersonalisationInterestLevel>{};
    final rawInterests = map['featureInterests'];
    if (rawInterests is Map) {
      for (final entry in rawInterests.entries) {
        final feature = _nullableEnumByName(
          ArcPersonalisationFeature.values,
          entry.key,
        );
        final level = _nullableEnumByName(
          ArcPersonalisationInterestLevel.values,
          entry.value,
        );
        if (feature != null && level != null) {
          interests[feature] = level;
        }
      }
    }
    return ArcUserPersonalisationProfile(
      schemaVersion: _intValue(map['schemaVersion'], currentSchemaVersion),
      completed: _boolValue(map['completed'], false),
      completedAt: _dateTimeValue(map['completedAt']),
      migratedAt: _dateTimeValue(map['migratedAt']),
      updatedAt: _dateTimeValue(map['updatedAt']),
      source: _stringValue(map['source'], 'default'),
      goals: _enumSetByName(
        ArcPersonalisationGoal.values,
        map['goals'],
        defaults.goals,
      ),
      featureInterests: interests,
      commandCentre: ArcCommandCentrePreferenceSet.fromMap(
        map['commandCentre'],
      ),
      squadPreference: _enumByName(
        ArcSoloSquadPreference.values,
        map['squadPreference'],
        ArcSoloSquadPreference.flexible,
      ),
      notificationCategories: _enumSetByName(
        ArcPersonalisationNotificationCategory.values,
        map['notificationCategories'],
        arcDefaultPersonalisationNotificationCategories,
      ),
      archetypeIds: _stringSetValue(map['archetypeIds']),
      playStyleIds: _stringSetValue(map['playStyleIds']),
      showFutureSystems: _boolValue(map['showFutureSystems'], false),
      reduceNoise: _boolValue(map['reduceNoise'], true),
    );
  }

  static ArcUserPersonalisationProfile inferFromLegacy({
    required Map<String, dynamic> userData,
    bool hasBlueprintData = false,
    bool hasTradeEvidence = false,
    bool hasScrappyData = false,
    bool hasProgressionData = false,
    bool hasLoadout = false,
  }) {
    final goals = <ArcPersonalisationGoal>{
      ArcPersonalisationGoal.exploreEverything,
    };
    final interests =
        <ArcPersonalisationFeature, ArcPersonalisationInterestLevel>{};
    final arcOnboarding = _mapValue(userData['arcOnboarding']);
    final basicProfile = _mapValue(userData['basicProfile']);
    final traderProfile = _mapValue(userData['traderProfile']);
    final profileFields = <String>[
      ..._stringListValue(arcOnboarding['currentPriority']),
      ..._stringListValue(arcOnboarding['playStyles']),
      ..._stringListValue(arcOnboarding['sessionIntent']),
      ..._stringListValue(basicProfile['currentPriority']),
      ..._stringListValue(basicProfile['playStyles']),
      ..._stringListValue(traderProfile['preferredTradeTypes']),
    ].map((value) => value.toLowerCase()).toList(growable: false);

    void addGoal(ArcPersonalisationGoal goal) => goals.add(goal);
    void raise(
      ArcPersonalisationFeature feature, [
      ArcPersonalisationInterestLevel level =
          ArcPersonalisationInterestLevel.high,
    ]) {
      final current = interests[feature];
      if (current == null || level.weight > current.weight) {
        interests[feature] = level;
      }
    }

    for (final value in profileFields) {
      if (value.contains('blueprint') || value.contains('collection')) {
        addGoal(ArcPersonalisationGoal.completeBlueprints);
        raise(ArcPersonalisationFeature.blueprintTracker);
        raise(ArcPersonalisationFeature.blueprintIntelligence);
      }
      if (value.contains('trade') || value.contains('swap')) {
        addGoal(ArcPersonalisationGoal.tradeBlueprints);
        raise(ArcPersonalisationFeature.trading);
        raise(ArcPersonalisationFeature.smartTrade);
      }
      if (value.contains('quest')) {
        addGoal(ArcPersonalisationGoal.progressQuests);
        raise(ArcPersonalisationFeature.questTracker);
      }
      if (value.contains('bench') || value.contains('workshop')) {
        addGoal(ArcPersonalisationGoal.upgradeBench);
        raise(ArcPersonalisationFeature.benchTracker);
      }
      if (value.contains('loadout') || value.contains('weapon')) {
        addGoal(ArcPersonalisationGoal.buildFavouriteLoadout);
        raise(ArcPersonalisationFeature.favouriteLoadout);
      }
      if (value.contains('squad') ||
          value.contains('match') ||
          value.contains('rider')) {
        addGoal(ArcPersonalisationGoal.findSquads);
        raise(ArcPersonalisationFeature.matchRider);
        raise(ArcPersonalisationFeature.availability);
      }
      if (value.contains('resource') || value.contains('farm')) {
        addGoal(ArcPersonalisationGoal.trackResources);
        raise(ArcPersonalisationFeature.scrappyTracker);
      }
      if (value.contains('raid') || value.contains('map')) {
        addGoal(ArcPersonalisationGoal.planRaids);
        raise(ArcPersonalisationFeature.raidPlanner);
        raise(ArcPersonalisationFeature.raidIntelligence);
      }
    }

    if (hasBlueprintData) {
      addGoal(ArcPersonalisationGoal.completeBlueprints);
      raise(ArcPersonalisationFeature.blueprintTracker);
    }
    if (hasTradeEvidence) {
      addGoal(ArcPersonalisationGoal.tradeBlueprints);
      raise(ArcPersonalisationFeature.trading);
      raise(ArcPersonalisationFeature.communications);
    }
    if (hasScrappyData) {
      addGoal(ArcPersonalisationGoal.trackResources);
      raise(ArcPersonalisationFeature.scrappyTracker);
    }
    if (hasProgressionData) {
      addGoal(ArcPersonalisationGoal.progressQuests);
      addGoal(ArcPersonalisationGoal.upgradeBench);
      raise(ArcPersonalisationFeature.questTracker);
      raise(ArcPersonalisationFeature.benchTracker);
    }
    if (hasLoadout) {
      addGoal(ArcPersonalisationGoal.buildFavouriteLoadout);
      raise(ArcPersonalisationFeature.favouriteLoadout);
    }

    final archetypes = {
      ..._stringListValue(arcOnboarding['archetypes']),
      ..._stringListValue(basicProfile['archetypes']),
      ..._stringListValue(traderProfile['archetypes']),
    };

    final playStyles = {
      ..._stringListValue(arcOnboarding['playStyles']),
      ..._stringListValue(basicProfile['playStyles']),
    };

    return ArcUserPersonalisationProfile(
      completed: false,
      source: 'legacy_migration',
      goals: goals,
      featureInterests: interests,
      archetypeIds: archetypes,
      playStyleIds: playStyles,
      migratedAt: DateTime.now(),
    );
  }

  static ArcPersonalisationInterestLevel? _inferredInterestFor(
    ArcPersonalisationFeature feature,
    Set<ArcPersonalisationGoal> goals,
  ) {
    if (goals.contains(ArcPersonalisationGoal.exploreEverything)) {
      return ArcPersonalisationInterestLevel.normal;
    }
    final featureGoals = _goalFeatureMap[feature] ?? const {};
    if (featureGoals.any(goals.contains)) {
      return ArcPersonalisationInterestLevel.high;
    }
    return null;
  }

  static const Map<ArcPersonalisationFeature, Set<ArcPersonalisationGoal>>
  _goalFeatureMap = {
    ArcPersonalisationFeature.blueprintTracker: {
      ArcPersonalisationGoal.completeBlueprints,
    },
    ArcPersonalisationFeature.blueprintIntelligence: {
      ArcPersonalisationGoal.completeBlueprints,
    },
    ArcPersonalisationFeature.blueprintWatches: {
      ArcPersonalisationGoal.completeBlueprints,
      ArcPersonalisationGoal.tradeBlueprints,
    },
    ArcPersonalisationFeature.trading: {ArcPersonalisationGoal.tradeBlueprints},
    ArcPersonalisationFeature.smartTrade: {
      ArcPersonalisationGoal.tradeBlueprints,
    },
    ArcPersonalisationFeature.favouriteLoadout: {
      ArcPersonalisationGoal.buildFavouriteLoadout,
    },
    ArcPersonalisationFeature.questTracker: {
      ArcPersonalisationGoal.progressQuests,
    },
    ArcPersonalisationFeature.benchTracker: {
      ArcPersonalisationGoal.upgradeBench,
    },
    ArcPersonalisationFeature.scrappyTracker: {
      ArcPersonalisationGoal.trackResources,
      ArcPersonalisationGoal.upgradeBench,
      ArcPersonalisationGoal.progressQuests,
    },
    ArcPersonalisationFeature.raidPlanner: {ArcPersonalisationGoal.planRaids},
    ArcPersonalisationFeature.huntTargets: {ArcPersonalisationGoal.planRaids},
    ArcPersonalisationFeature.raidIntelligence: {
      ArcPersonalisationGoal.planRaids,
      ArcPersonalisationGoal.receiveCommunityIntel,
    },
    ArcPersonalisationFeature.communityIntel: {
      ArcPersonalisationGoal.receiveCommunityIntel,
    },
    ArcPersonalisationFeature.matchRider: {ArcPersonalisationGoal.findSquads},
    ArcPersonalisationFeature.favouriteRiders: {
      ArcPersonalisationGoal.findSquads,
    },
    ArcPersonalisationFeature.privateRiders: {
      ArcPersonalisationGoal.findSquads,
    },
    ArcPersonalisationFeature.operations: {
      ArcPersonalisationGoal.followOperations,
      ArcPersonalisationGoal.manageCosmetics,
    },
    ArcPersonalisationFeature.rewardVault: {
      ArcPersonalisationGoal.manageCosmetics,
      ArcPersonalisationGoal.followOperations,
    },
    ArcPersonalisationFeature.profile: {
      ArcPersonalisationGoal.improveReputation,
    },
    ArcPersonalisationFeature.communications: {
      ArcPersonalisationGoal.tradeBlueprints,
      ArcPersonalisationGoal.findSquads,
    },
  };
}

T _enumByName<T extends Enum>(List<T> values, Object? value, T fallback) {
  return _nullableEnumByName(values, value) ?? fallback;
}

T? _nullableEnumByName<T extends Enum>(List<T> values, Object? value) {
  final normalized = value?.toString().trim();
  if (normalized == null || normalized.isEmpty) return null;
  for (final item in values) {
    if (item.name == normalized) return item;
  }
  return null;
}

Set<T> _enumSetByName<T extends Enum>(
  List<T> values,
  Object? raw,
  Set<T> fallback,
) {
  final output = <T>{};
  for (final item in _stringListValue(raw)) {
    final value = _nullableEnumByName(values, item);
    if (value != null) output.add(value);
  }
  return output.isEmpty ? fallback : output;
}

Map<String, dynamic> _mapValue(Object? value) {
  if (value is Map) return value.cast<String, dynamic>();
  return const <String, dynamic>{};
}

Set<String> _stringSetValue(Object? value) {
  return _stringListValue(value).toSet();
}

List<String> _stringListValue(Object? value) {
  if (value is Iterable) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  final single = value?.toString().trim();
  if (single == null || single.isEmpty) return const <String>[];
  return <String>[single];
}

String _stringValue(Object? value, String fallback) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

bool _boolValue(Object? value, bool fallback) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return fallback;
}

int _intValue(Object? value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _dateTimeValue(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  return DateTime.tryParse(value.toString());
}
