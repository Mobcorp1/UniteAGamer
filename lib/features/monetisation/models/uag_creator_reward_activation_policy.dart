import 'uag_creator_reward_models.dart';
import 'uag_subscription_tier.dart';

class UagCreatorRewardActivationPolicy {
  const UagCreatorRewardActivationPolicy._();

  static UagSubscriptionTier tierFor(UagCreatorRewardType type) =>
      switch (type) {
        UagCreatorRewardType.essential7Day ||
        UagCreatorRewardType.essentialMonth => UagSubscriptionTier.essential,
        UagCreatorRewardType.premium7Day ||
        UagCreatorRewardType.premiumMonth ||
        UagCreatorRewardType.annualPremium => UagSubscriptionTier.premium,
      };

  static Duration durationFor(UagCreatorRewardType type) => switch (type) {
    UagCreatorRewardType.essential7Day ||
    UagCreatorRewardType.premium7Day => const Duration(days: 7),
    UagCreatorRewardType.essentialMonth ||
    UagCreatorRewardType.premiumMonth => const Duration(days: 30),
    UagCreatorRewardType.annualPremium => const Duration(days: 365),
  };

  static DateTime expiryFor(UagCreatorRewardType type, DateTime startedAt) =>
      startedAt.toUtc().add(durationFor(type));

  static String lifecycleState({
    required DateTime startedAt,
    required DateTime expiresAt,
    DateTime? now,
  }) {
    final clock = (now ?? DateTime.now()).toUtc();
    if (clock.isBefore(startedAt.toUtc())) return 'scheduled';
    if (!clock.isBefore(expiresAt.toUtc())) return 'expired';
    return 'active';
  }
}
