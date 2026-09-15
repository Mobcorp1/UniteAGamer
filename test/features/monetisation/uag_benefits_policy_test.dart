import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_community_referral_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_commission_rate_policy.dart';

void main() {
  test('community reward milestones remain the agreed launch ladder', () {
    final milestones = UagCommunityReferralPolicy.milestones;
    expect(milestones.length, 3);
    expect(milestones[0].validatedReferrals, 1);
    expect(milestones[0].label, '7 days Premium');
    expect(milestones[1].validatedReferrals, 3);
    expect(milestones[1].label, '1 month Premium');
    expect(milestones[2].validatedReferrals, 5);
    expect(milestones[2].label, 'Creator Programme fast-track review');
    expect(UagCommunityReferralPolicy.retentionValidationDays, 30);
  });

  test('creator commission ladder and community uplift remain bounded', () {
    expect(UagCreatorCommissionRatePolicy.baseRatePercent(1), 7.5);
    expect(UagCreatorCommissionRatePolicy.baseRatePercent(8), 10);
    expect(UagCreatorCommissionRatePolicy.baseRatePercent(15), 12.5);
    expect(UagCreatorCommissionRatePolicy.baseRatePercent(25), 15);
    expect(UagCreatorCommissionRatePolicy.baseRatePercent(40), 17.5);
    expect(UagCreatorCommissionRatePolicy.baseRatePercent(60), 20);
    expect(UagCreatorCommissionRatePolicy.baseRatePercent(100), 20);
    expect(UagCreatorCommissionRatePolicy.communityUpliftPercent(250000), 2.5);
    expect(
      UagCreatorCommissionRatePolicy.effectiveRatePercent(
        points: 100,
        qualifiedActiveUsers: 250000,
      ),
      22.5,
    );
  });
}
