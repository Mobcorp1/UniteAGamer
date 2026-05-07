enum UagSubscriptionTier {
  free,
  essential,
  premium;

  static UagSubscriptionTier fromValue(String? value) {
    switch ((value ?? '').toLowerCase().trim()) {
      case 'essential':
        return UagSubscriptionTier.essential;
      case 'premium':
        return UagSubscriptionTier.premium;
      case 'free':
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

  bool get isPaid => this != UagSubscriptionTier.free;
}

enum UagBillableAction {
  trade,
  matchmakingSearch,
  intelHint;

  String get usageKey {
    switch (this) {
      case UagBillableAction.trade:
        return 'trades';
      case UagBillableAction.matchmakingSearch:
        return 'matchmakingSearches';
      case UagBillableAction.intelHint:
        return 'intelHints';
    }
  }

  String get label {
    switch (this) {
      case UagBillableAction.trade:
        return 'Trade';
      case UagBillableAction.matchmakingSearch:
        return 'Matchmaking search';
      case UagBillableAction.intelHint:
        return 'Intel hint';
    }
  }
}
