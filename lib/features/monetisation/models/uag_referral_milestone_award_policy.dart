import 'uag_community_referral_policy.dart';
import 'uag_referral_reward_locker_models.dart';

class UagReferralMilestoneAward {
  const UagReferralMilestoneAward({
    required this.milestone,
    required this.rewardType,
    required this.rewardId,
  });

  final UagCommunityReferralMilestone milestone;
  final UagReferralBankedRewardType? rewardType;
  final String rewardId;
}

class UagReferralMilestoneAwardPolicy {
  const UagReferralMilestoneAwardPolicy._();

  static List<UagReferralMilestoneAward> newlyEarnedAwards({
    required int previousValidatedReferrals,
    required int newValidatedReferrals,
    required Set<int> alreadyAwardedMilestones,
    required String referrerUid,
  }) {
    if (newValidatedReferrals <= previousValidatedReferrals) {
      return const <UagReferralMilestoneAward>[];
    }

    final result = <UagReferralMilestoneAward>[];
    for (final milestone in UagCommunityReferralPolicy.milestones) {
      final threshold = milestone.validatedReferrals;
      if (threshold <= previousValidatedReferrals ||
          threshold > newValidatedReferrals ||
          alreadyAwardedMilestones.contains(threshold)) {
        continue;
      }

      UagReferralBankedRewardType? rewardType;
      switch (milestone.reward) {
        case UagCommunityReferralReward.premium7Days:
          rewardType = UagReferralBankedRewardType.premium7Days;
        case UagCommunityReferralReward.premium30Days:
          rewardType = UagReferralBankedRewardType.premium30Days;
        case UagCommunityReferralReward.creatorFastTrack:
          rewardType = null;
      }

      result.add(
        UagReferralMilestoneAward(
          milestone: milestone,
          rewardType: rewardType,
          rewardId: 'community_referral_${referrerUid}_${threshold.toString()}',
        ),
      );
    }
    return result;
  }
}
