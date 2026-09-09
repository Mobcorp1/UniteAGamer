import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_referral_milestone_award_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_referral_reward_locker_models.dart';

void main() {
  test('crossing milestone 1 banks 7 day Premium reward once', () {
    final awards = UagReferralMilestoneAwardPolicy.newlyEarnedAwards(
      previousValidatedReferrals: 0,
      newValidatedReferrals: 1,
      alreadyAwardedMilestones: <int>{},
      referrerUid: 'creator123',
    );
    expect(awards, hasLength(1));
    expect(awards.single.milestone.validatedReferrals, 1);
    expect(awards.single.rewardType, UagReferralBankedRewardType.premium7Days);
  });

  test('already awarded milestone is never duplicated', () {
    final awards = UagReferralMilestoneAwardPolicy.newlyEarnedAwards(
      previousValidatedReferrals: 0,
      newValidatedReferrals: 3,
      alreadyAwardedMilestones: <int>{1},
      referrerUid: 'creator123',
    );
    expect(awards.map((a) => a.milestone.validatedReferrals), <int>[3]);
  });

  test(
    'crossing milestone 5 unlocks creator fast track without timed reward',
    () {
      final awards = UagReferralMilestoneAwardPolicy.newlyEarnedAwards(
        previousValidatedReferrals: 4,
        newValidatedReferrals: 5,
        alreadyAwardedMilestones: <int>{1, 3},
        referrerUid: 'creator123',
      );
      expect(awards, hasLength(1));
      expect(awards.single.milestone.validatedReferrals, 5);
      expect(awards.single.rewardType, isNull);
    },
  );
}
