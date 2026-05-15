import 'uag_subscription_tier.dart';

class UagAdPolicy {
  const UagAdPolicy({
    required this.tier,
    required this.showBannerAds,
    required this.showInterstitialAds,
    required this.showRewardedAds,
    required this.allowVoiceAssistantAds,
    required this.allowMidSessionAds,
    required this.bannerPlacement,
    required this.rewardedBoosts,
  });

  final UagSubscriptionTier tier;
  final bool showBannerAds;
  final bool showInterstitialAds;
  final bool showRewardedAds;
  final bool allowVoiceAssistantAds;
  final bool allowMidSessionAds;
  final String bannerPlacement;
  final List<String> rewardedBoosts;

  bool get hasAnyAds => showBannerAds || showInterstitialAds || showRewardedAds;

  static const free = UagAdPolicy(
    tier: UagSubscriptionTier.free,
    showBannerAds: true,
    showInterstitialAds: false,
    showRewardedAds: true,
    allowVoiceAssistantAds: false,
    allowMidSessionAds: false,
    bannerPlacement: 'Bottom banner only on non-critical screens.',
    rewardedBoosts: [
      'Unlock Premium Intel Snapshot for 12 hours',
      'Unlock one extra trade listing for 24 hours',
      'Unlock one advanced route/raid-planner insight',
    ],
  );

  static const essential = UagAdPolicy(
    tier: UagSubscriptionTier.essential,
    showBannerAds: true,
    showInterstitialAds: false,
    showRewardedAds: true,
    allowVoiceAssistantAds: false,
    allowMidSessionAds: false,
    bannerPlacement: 'Reduced passive banner only; never during active voice/session flow.',
    rewardedBoosts: [
      'Optional temporary Premium Intel unlock',
      'Optional temporary Trader Pro preview',
    ],
  );

  static const premium = UagAdPolicy(
    tier: UagSubscriptionTier.premium,
    showBannerAds: false,
    showInterstitialAds: false,
    showRewardedAds: false,
    allowVoiceAssistantAds: false,
    allowMidSessionAds: false,
    bannerPlacement: 'No ads.',
    rewardedBoosts: <String>[],
  );

  static UagAdPolicy forTier(UagSubscriptionTier tier) {
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
