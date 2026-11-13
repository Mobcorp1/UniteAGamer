import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_referral_commission_policy.dart';

void main() {
  test('community cash ladder follows active paid referral bands', () {
    expect(UagReferralCommissionPolicy.baseRatePercent(0), 0);
    expect(UagReferralCommissionPolicy.baseRatePercent(1), 5);
    expect(UagReferralCommissionPolicy.baseRatePercent(5), 7.5);
    expect(UagReferralCommissionPolicy.baseRatePercent(25), 10);
    expect(UagReferralCommissionPolicy.baseRatePercent(50), 12.5);
    expect(UagReferralCommissionPolicy.baseRatePercent(100), 15);
  });

  test('Premium adds 2.5 percentage points to an earned base rate', () {
    expect(
      UagReferralCommissionPolicy.effectiveRatePercent(
        activePaidReferrals: 5,
        premiumActive: true,
      ),
      10,
    );
    expect(
      UagReferralCommissionPolicy.effectiveRatePercent(
        activePaidReferrals: 0,
        premiumActive: true,
      ),
      0,
    );
  });

  test('referred customer first purchase discount is fixed at 10 percent', () {
    expect(UagReferralCommissionPolicy.firstPurchaseDiscountPercent, 10);
  });
}
