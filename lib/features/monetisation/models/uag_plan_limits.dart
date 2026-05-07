import 'uag_subscription_tier.dart';

class UagPlanLimits {
  const UagPlanLimits({
    required this.tier,
    required this.weeklyTrades,
    required this.weeklyMatchmakingSearches,
    required this.weeklyIntelHints,
    required this.prioritySlots,
    required this.hasAds,
    required this.reducedAds,
    required this.referralDiscountPercent,
    required this.referralCommissionPercent,
    required this.monthlyReferralBonusActionCap,
    required this.payoutThresholdPence,
  });

  final UagSubscriptionTier tier;
  final int? weeklyTrades;
  final int? weeklyMatchmakingSearches;
  final int? weeklyIntelHints;
  final int prioritySlots;
  final bool hasAds;
  final bool reducedAds;
  final int referralDiscountPercent;
  final int referralCommissionPercent;
  final int monthlyReferralBonusActionCap;
  final int payoutThresholdPence;

  bool get unlimitedTrades => weeklyTrades == null;
  bool get unlimitedMatchmaking => weeklyMatchmakingSearches == null;
  bool get unlimitedIntelHints => weeklyIntelHints == null;

  int? limitFor(UagBillableAction action) {
    switch (action) {
      case UagBillableAction.trade:
        return weeklyTrades;
      case UagBillableAction.matchmakingSearch:
        return weeklyMatchmakingSearches;
      case UagBillableAction.intelHint:
        return weeklyIntelHints;
    }
  }

  static const free = UagPlanLimits(
    tier: UagSubscriptionTier.free,
    weeklyTrades: 1,
    weeklyMatchmakingSearches: 1,
    weeklyIntelHints: 1,
    prioritySlots: 1,
    hasAds: true,
    reducedAds: false,
    referralDiscountPercent: 0,
    referralCommissionPercent: 0,
    monthlyReferralBonusActionCap: 4,
    payoutThresholdPence: 2500,
  );

  static const essential = UagPlanLimits(
    tier: UagSubscriptionTier.essential,
    weeklyTrades: 5,
    weeklyMatchmakingSearches: 5,
    weeklyIntelHints: 5,
    prioritySlots: 5,
    hasAds: true,
    reducedAds: true,
    referralDiscountPercent: 10,
    referralCommissionPercent: 10,
    monthlyReferralBonusActionCap: 10,
    payoutThresholdPence: 2500,
  );

  static const premium = UagPlanLimits(
    tier: UagSubscriptionTier.premium,
    weeklyTrades: null,
    weeklyMatchmakingSearches: null,
    weeklyIntelHints: null,
    prioritySlots: 99,
    hasAds: false,
    reducedAds: false,
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
