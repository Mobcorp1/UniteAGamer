import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_community_referral_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_referral_terms_policy.dart';

void main() {
  test('normal users earn useful non-cash referral milestones', () {
    expect(UagCommunityReferralPolicy.nextMilestone(0)?.validatedReferrals, 1);
    expect(UagCommunityReferralPolicy.nextMilestone(1)?.validatedReferrals, 3);
    expect(UagCommunityReferralPolicy.nextMilestone(3)?.validatedReferrals, 5);
    expect(UagCommunityReferralPolicy.nextMilestone(5), isNull);
  });

  test('community growth bonus is capped at 2.5 percentage points', () {
    expect(UagCommunityGrowthPolicy.creatorGrowthBonusPercent(9999), 0);
    expect(UagCommunityGrowthPolicy.creatorGrowthBonusPercent(10000), .5);
    expect(UagCommunityGrowthPolicy.creatorGrowthBonusPercent(50000), 1.5);
    expect(UagCommunityGrowthPolicy.creatorGrowthBonusPercent(250000), 2.5);
    expect(UagCommunityGrowthPolicy.creatorGrowthBonusPercent(9999999), 2.5);
  });

  test(
    'terms policy explicitly rejects equity and dividend interpretation',
    () {
      expect(
        UagReferralTermsPolicy.requiredPrinciples.any(
          (line) => line.contains('equity') && line.contains('dividends'),
        ),
        isTrue,
      );
    },
  );
}
