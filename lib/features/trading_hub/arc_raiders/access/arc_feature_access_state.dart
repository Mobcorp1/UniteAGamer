enum ArcFeatureKey {
  tradersHub,
  scrappyTracker,
  raidPlanner,
  playLikeAPro,
  voiceAssist,
  smartTradeAssist,
  automationSystems,
  adminConsole,
}

class ArcFeatureAccessState {
  final Map<ArcFeatureKey, bool> featureEnabled;

  const ArcFeatureAccessState({required this.featureEnabled});

  factory ArcFeatureAccessState.defaults() {
    return const ArcFeatureAccessState(
      featureEnabled: {
        ArcFeatureKey.tradersHub: true,
        ArcFeatureKey.scrappyTracker: true,
        ArcFeatureKey.raidPlanner: true,
        ArcFeatureKey.playLikeAPro: true,
        ArcFeatureKey.voiceAssist: true,
        ArcFeatureKey.smartTradeAssist: false,
        ArcFeatureKey.automationSystems: false,
        ArcFeatureKey.adminConsole: false,
      },
    );
  }

  bool isEnabled(ArcFeatureKey key) {
    return featureEnabled[key] ?? false;
  }

  ArcFeatureAccessState copyWithFeature({
    required ArcFeatureKey key,
    required bool enabled,
  }) {
    return ArcFeatureAccessState(
      featureEnabled: {...featureEnabled, key: enabled},
    );
  }

  ArcFeatureAccessState copyWithMap(Map<ArcFeatureKey, bool> updates) {
    return ArcFeatureAccessState(
      featureEnabled: {...featureEnabled, ...updates},
    );
  }
}
