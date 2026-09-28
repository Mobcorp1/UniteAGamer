import 'uag_ad_policy.dart';
import 'uag_subscription_tier.dart';

enum UagRaiderMarkRedemptionTarget {
  tradeAction,
  matchRaiderSearch;

  UagBillableAction get action => switch (this) {
    UagRaiderMarkRedemptionTarget.tradeAction => UagBillableAction.trade,
    UagRaiderMarkRedemptionTarget.matchRaiderSearch =>
      UagBillableAction.matchmakingSearch,
  };

  String get label => switch (this) {
    UagRaiderMarkRedemptionTarget.tradeAction => '+1 Trade Action',
    UagRaiderMarkRedemptionTarget.matchRaiderSearch =>
      '+1 Match Raider Search',
  };
}

class UagRaiderMarkPolicy {
  const UagRaiderMarkPolicy._();

  static const int marksPerCompletedAd = 1;
  static const int marksPerBonusAction = 5;
  static const int walletCap = 10;
  static const int maxRewardedAdsPerDay = 3;
  static const int maxRewardedAdsPerMonth = 20;
  static const int maxBonusRedemptionsPerMonth = 4;
  static const Duration minimumAdInterval = Duration(minutes: 20);

  static bool canEarnMark({
    required UagAdPolicy policy,
    required bool signedIn,
    required bool consentGranted,
    required bool serverGrantReady,
    required bool explicitlyRequested,
    required int walletBalance,
    required int verifiedAdsToday,
    required int verifiedAdsThisMonth,
    required DateTime now,
    DateTime? lastVerifiedAdAt,
  }) {
    if (!signedIn ||
        !consentGranted ||
        !serverGrantReady ||
        !explicitlyRequested ||
        policy.tier != UagSubscriptionTier.free ||
        !policy.showRewardedAds ||
        walletBalance < 0 ||
        walletBalance >= walletCap ||
        verifiedAdsToday < 0 ||
        verifiedAdsToday >= maxRewardedAdsPerDay ||
        verifiedAdsThisMonth < 0 ||
        verifiedAdsThisMonth >= maxRewardedAdsPerMonth) {
      return false;
    }
    return lastVerifiedAdAt == null ||
        now.difference(lastVerifiedAdAt) >= minimumAdInterval;
  }

  static bool canRedeem({
    required UagAdPolicy policy,
    required int walletBalance,
    required int redemptionsThisMonth,
  }) =>
      policy.tier == UagSubscriptionTier.free &&
      walletBalance >= marksPerBonusAction &&
      redemptionsThisMonth >= 0 &&
      redemptionsThisMonth < maxBonusRedemptionsPerMonth;

  static int walletAfterEarn(int walletBalance) =>
      (walletBalance + marksPerCompletedAd).clamp(0, walletCap);

  static int walletAfterRedeem(int walletBalance) {
    if (walletBalance < marksPerBonusAction) return walletBalance;
    return walletBalance - marksPerBonusAction;
  }
}
