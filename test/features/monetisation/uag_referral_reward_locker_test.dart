import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_referral_reward_locker_models.dart';

void main() {
  test('7 day reward runs for 7 days only after activation', () {
    final activated = DateTime.utc(2026, 12, 20, 10);
    final expiry = UagReferralRewardLockerPolicy.activationExpiry(
      type: UagReferralBankedRewardType.premium7Days,
      activatedAt: activated,
    );
    expect(expiry, DateTime.utc(2026, 12, 27, 10));
  });

  test('30 day reward runs for 30 days only after activation', () {
    final activated = DateTime.utc(2026, 12, 1);
    final expiry = UagReferralRewardLockerPolicy.activationExpiry(
      type: UagReferralBankedRewardType.premium30Days,
      activatedAt: activated,
    );
    expect(expiry, DateTime.utc(2026, 12, 31));
  });

  test('reward activation is blocked while Premium is already active', () {
    expect(
      UagReferralRewardLockerPolicy.canActivate(
        hasActiveLockerReward: false,
        underlyingPremiumActive: true,
      ),
      isFalse,
    );
    expect(
      UagReferralRewardLockerPolicy.canActivate(
        hasActiveLockerReward: false,
        underlyingPremiumActive: false,
      ),
      isTrue,
    );
  });
}
