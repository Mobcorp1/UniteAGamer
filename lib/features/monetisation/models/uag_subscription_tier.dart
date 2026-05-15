enum UagSubscriptionTier {
  free,
  essential,
  premium;

  static UagSubscriptionTier fromValue(String? value) {
    switch ((value ?? '').toLowerCase().trim()) {
      case 'essential':
      case 'active_raider':
      case 'active-raider':
        return UagSubscriptionTier.essential;
      case 'premium':
      case 'elite':
      case 'elite_raider':
      case 'elite-raider':
        return UagSubscriptionTier.premium;
      case 'free':
      case 'core':
      case 'core_raider':
      case 'core-raider':
      default:
        return UagSubscriptionTier.free;
    }
  }

  String get value => name;

  String get label {
    switch (this) {
      case UagSubscriptionTier.free:
        return 'Free';
      case UagSubscriptionTier.essential:
        return 'Essential';
      case UagSubscriptionTier.premium:
        return 'Premium';
    }
  }

  String get publicName {
    switch (this) {
      case UagSubscriptionTier.free:
        return 'Core Raider';
      case UagSubscriptionTier.essential:
        return 'Active Raider';
      case UagSubscriptionTier.premium:
        return 'Elite Raider';
    }
  }

  bool get isPaid => this != UagSubscriptionTier.free;
}

enum UagBillableAction {
  trade,
  matchmakingSearch,
  intelHint,
  advancedVoiceCommand,
  premiumIntelUnlock,
  traderAnalyticsView,
  raidCompanionPreset;

  String get usageKey {
    switch (this) {
      case UagBillableAction.trade:
        return 'trades';
      case UagBillableAction.matchmakingSearch:
        return 'matchmakingSearches';
      case UagBillableAction.intelHint:
        return 'intelHints';
      case UagBillableAction.advancedVoiceCommand:
        return 'advancedVoiceCommands';
      case UagBillableAction.premiumIntelUnlock:
        return 'premiumIntelUnlocks';
      case UagBillableAction.traderAnalyticsView:
        return 'traderAnalyticsViews';
      case UagBillableAction.raidCompanionPreset:
        return 'raidCompanionPresets';
    }
  }

  String get label {
    switch (this) {
      case UagBillableAction.trade:
        return 'Trade action';
      case UagBillableAction.matchmakingSearch:
        return 'Match Raider search';
      case UagBillableAction.intelHint:
        return 'Intel hint';
      case UagBillableAction.advancedVoiceCommand:
        return 'Advanced voice command';
      case UagBillableAction.premiumIntelUnlock:
        return 'Premium intel unlock';
      case UagBillableAction.traderAnalyticsView:
        return 'Trader analytics view';
      case UagBillableAction.raidCompanionPreset:
        return 'Raid Companion preset';
    }
  }
}
