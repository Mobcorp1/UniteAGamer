import 'uag_commercial_economy.dart';
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

  // Legacy field names are retained to avoid breaking older consumers.
  // Trade and Match Raider counters now reset monthly in UagEntitlementService.
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

  int? get monthlyTrades => weeklyTrades;
  int? get monthlyMatchmakingSearches => weeklyMatchmakingSearches;

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
    weeklyTrades: UagCommercialEconomy.freeMonthlyTrades,
    weeklyMatchmakingSearches:
        UagCommercialEconomy.freeMonthlyMatchRaiderActions,
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
    referralDiscountPercent:
        UagCommercialEconomy.referralFirstPurchaseDiscountPercent,
    referralCommissionPercent: 0,
    monthlyReferralBonusActionCap: 8,
    payoutThresholdPence: UagCommercialEconomy.payoutThresholdPence,
  );

  static const essential = UagPlanLimits(
    tier: UagSubscriptionTier.essential,
    weeklyTrades: UagCommercialEconomy.essentialMonthlyTrades,
    weeklyMatchmakingSearches:
        UagCommercialEconomy.essentialMonthlyMatchRaiderActions,
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
    hasRewardedAdBoosts: false,
    hasTraderProAnalytics: false,
    hasAdvancedVoicePersonalities: true,
    hasSmartAlerts: true,
    hasUnlimitedSessions: false,
    referralDiscountPercent:
        UagCommercialEconomy.referralFirstPurchaseDiscountPercent,
    referralCommissionPercent: 0,
    monthlyReferralBonusActionCap: 25,
    payoutThresholdPence: UagCommercialEconomy.payoutThresholdPence,
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
    referralDiscountPercent:
        UagCommercialEconomy.referralFirstPurchaseDiscountPercent,
    referralCommissionPercent: 0,
    monthlyReferralBonusActionCap: 999,
    payoutThresholdPence: UagCommercialEconomy.payoutThresholdPence,
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
