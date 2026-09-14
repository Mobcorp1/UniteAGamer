import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_premium_pass_entitlement.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_referral_commission_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_plan.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_tier.dart';

void main() {
  test('public plans and passes use the converged commercial prices', () {
    final essential = UagSubscriptionPlan.forTier(
      UagSubscriptionTier.essential,
    );
    final premium = UagSubscriptionPlan.forTier(UagSubscriptionTier.premium);

    expect(essential.monthlyPricePence, 799);
    expect(essential.yearlyPricePence, 6999);
    expect(premium.monthlyPricePence, 999);
    expect(premium.yearlyPricePence, 8999);
    expect(UagPremiumPassType.day24.pricePence, 199);
    expect(UagPremiumPassType.week7.pricePence, 349);
  });

  test('community referral model is staggered and Premium adds 2.5 points', () {
    expect(UagReferralCommissionPolicy.firstPurchaseDiscountPercent, 10);
    expect(UagReferralCommissionPolicy.baseRatePercent(1), 5);
    expect(UagReferralCommissionPolicy.baseRatePercent(5), 7.5);
    expect(UagReferralCommissionPolicy.baseRatePercent(25), 10);
    expect(UagReferralCommissionPolicy.baseRatePercent(50), 12.5);
    expect(UagReferralCommissionPolicy.baseRatePercent(100), 15);
    expect(
      UagReferralCommissionPolicy.effectiveRatePercent(
        activePaidReferrals: 1,
        premiumActive: true,
      ),
      7.5,
    );
  });

  test(
    'customer-facing monetisation surfaces do not expose launch-model copy',
    () {
      final plans = File(
        'lib/features/monetisation/screens/monetisation_screen.dart',
      ).readAsStringSync();
      final community = File(
        'lib/features/monetisation/screens/uag_benefits_community_rewards_screen.dart',
      ).readAsStringSync();
      final creator = File(
        'lib/features/monetisation/screens/uag_creator_programme_screen.dart',
      ).readAsStringSync();

      expect(plans, isNot(contains('Launch Model')));
      expect(plans, isNot(contains('10% follower')));
      expect(plans, isNot(contains('20% follower')));
      expect(plans, contains('GROW UAG. SHARE THE VALUE'));
      expect(community, contains('COMMUNITY REWARDS'));
      expect(community, contains('COUNTRY LEADERBOARD · PLANNED'));
      expect(creator, contains('UAG CREATOR PROGRAM'));
    },
  );
}
