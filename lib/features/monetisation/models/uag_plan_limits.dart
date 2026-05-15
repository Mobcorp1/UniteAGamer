import 'uag_subscription_tier.dart';

class UagPlanLimits {
  const UagPlanLimits({
    required this.tier,
    required this.weeklyTrades,
    required this.weeklyMatchmakingSearches,
    required this.weeklyIntelHints,
    required this.weeklyAdvancedVoiceCommands,
    required this.weeklyPremiumIntelUnlocks,
    required this.weeklyTraderAnalyticsViews,
    required this.weeklyRaidCompanionPresets,
    required this.activeTradeListings,
    required this.dailyTradeOffers,
    required this.prioritySlots,
    required this.savedRaidPlans,
    required this.voiceProfilesUnlocked,
    required this.hasAds,
    required this.reducedAds,
    required this.canDisableAds,
    required this.hasRewardedAdBoosts,
    required this.hasTraderProAnalytics,
    required this.hasAdvancedVoicePersonalities,
    required this.hasSmartAlerts,
    required this.hasUnlimitedSessions,
    required this.referralDiscountPercent,
    required this.referralCommissionPercent,
    required this.monthlyReferralBonusActionCap,
    required this.payoutThresholdPence,
  });

  final UagSubscriptionTier tier;
  final int? weeklyTrades;
  final int? weeklyMatchmakingSearches;
  final int? weeklyIntelHints;
  final int? weeklyAdvancedVoiceCommands;
  final int? weeklyPremiumIntelUnlocks;
  final int? weeklyTraderAnalyticsViews;
  final int? weeklyRaidCompanionPresets;
  final int? activeTradeListings;
  final int? dailyTradeOffers;
  final int prioritySlots;
  final int? savedRaidPlans;
  final int? voiceProfilesUnlocked;
  final bool hasAds;
  final bool reducedAds;
  final bool canDisableAds;
  final bool hasRewardedAdBoosts;
  final bool hasTraderProAnalytics;
  final bool hasAdvancedVoicePersonalities;
  final bool hasSmartAlerts;
  final bool hasUnlimitedSessions;
  final int referralDiscountPercent;
  final int referralCommissionPercent;
  final int monthlyReferralBonusActionCap;
  final int payoutThresholdPence;

  bool get unlimitedTrades => weeklyTrades == null;
  bool get unlimitedMatchmaking => weeklyMatchmakingSearches == null;
  bool get unlimitedIntelHints => weeklyIntelHints == null;
  bool get unlimitedActiveListings => activeTradeListings == null;
  bool get unlimitedDailyOffers => dailyTradeOffers == null;
  bool get unlimitedRaidPlans => savedRaidPlans == null;
  bool get unlimitedVoiceProfiles => voiceProfilesUnlocked == null;

  int? limitFor(UagBillableAction action) {
    switch (action) {
      case UagBillableAction.trade:
        return weeklyTrades;
      case UagBillableAction.matchmakingSearch:
        return weeklyMatchmakingSearches;
      case UagBillableAction.intelHint:
        return weeklyIntelHints;
      case UagBillableAction.advancedVoiceCommand:
        return weeklyAdvancedVoiceCommands;
      case UagBillableAction.premiumIntelUnlock:
        return weeklyPremiumIntelUnlocks;
      case UagBillableAction.traderAnalyticsView:
        return weeklyTraderAnalyticsViews;
      case UagBillableAction.raidCompanionPreset:
        return weeklyRaidCompanionPresets;
    }
  }

  static const free = UagPlanLimits(
    tier: UagSubscriptionTier.free,
    weeklyTrades: 10,
    weeklyMatchmakingSearches: 10,
    weeklyIntelHints: 8,
    weeklyAdvancedVoiceCommands: 25,
    weeklyPremiumIntelUnlocks: 2,
    weeklyTraderAnalyticsViews: 0,
    weeklyRaidCompanionPresets: 0,
    activeTradeListings: 2,
    dailyTradeOffers: 5,
    prioritySlots: 3,
    savedRaidPlans: 2,
    voiceProfilesUnlocked: 2,
    hasAds: true,
    reducedAds: false,
    canDisableAds: false,
    hasRewardedAdBoosts: true,
    hasTraderProAnalytics: false,
    hasAdvancedVoicePersonalities: false,
    hasSmartAlerts: false,
    hasUnlimitedSessions: false,
    referralDiscountPercent: 0,
    referralCommissionPercent: 0,
    monthlyReferralBonusActionCap: 8,
    payoutThresholdPence: 2500,
  );

  static const essential = UagPlanLimits(
    tier: UagSubscriptionTier.essential,
    weeklyTrades: 50,
    weeklyMatchmakingSearches: 50,
    weeklyIntelHints: 40,
    weeklyAdvancedVoiceCommands: null,
    weeklyPremiumIntelUnlocks: 12,
    weeklyTraderAnalyticsViews: 15,
    weeklyRaidCompanionPresets: 10,
    activeTradeListings: 10,
    dailyTradeOffers: 25,
    prioritySlots: 10,
    savedRaidPlans: 10,
    voiceProfilesUnlocked: 6,
    hasAds: true,
    reducedAds: true,
    canDisableAds: false,
    hasRewardedAdBoosts: true,
    hasTraderProAnalytics: false,
    hasAdvancedVoicePersonalities: true,
    hasSmartAlerts: true,
    hasUnlimitedSessions: false,
    referralDiscountPercent: 10,
    referralCommissionPercent: 10,
    monthlyReferralBonusActionCap: 25,
    payoutThresholdPence: 2500,
  );

  static const premium = UagPlanLimits(
    tier: UagSubscriptionTier.premium,
    weeklyTrades: null,
    weeklyMatchmakingSearches: null,
    weeklyIntelHints: null,
    weeklyAdvancedVoiceCommands: null,
    weeklyPremiumIntelUnlocks: null,
    weeklyTraderAnalyticsViews: null,
    weeklyRaidCompanionPresets: null,
    activeTradeListings: null,
    dailyTradeOffers: null,
    prioritySlots: 99,
    savedRaidPlans: null,
    voiceProfilesUnlocked: null,
    hasAds: false,
    reducedAds: false,
    canDisableAds: true,
    hasRewardedAdBoosts: false,
    hasTraderProAnalytics: true,
    hasAdvancedVoicePersonalities: true,
    hasSmartAlerts: true,
    hasUnlimitedSessions: true,
    referralDiscountPercent: 20,
    referralCommissionPercent: 20,
    monthlyReferralBonusActionCap: 999,
    payoutThresholdPence: 2500,
  );

  static UagPlanLimits forTier(UagSubscriptionTier tier) {
    switch (tier) {
      case UagSubscriptionTier.free:
        return free;
      case UagSubscriptionTier.essential:
        return essential;
      case UagSubscriptionTier.premium:
        return premium;
    }
  }
}
