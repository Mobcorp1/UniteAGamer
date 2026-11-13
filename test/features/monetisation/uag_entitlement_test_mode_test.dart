import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_entitlement_test_mode.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_tier.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_user_entitlement.dart';

void main() {
  UagUserEntitlement entitlement(UagEntitlementTestMode mode) =>
      UagUserEntitlement(
        uid: 'admin',
        tier: UagSubscriptionTier.premium,
        subscriptionStatus: 'active',
        isAdmin: true,
        isDev: true,
        referralCode: null,
        availableBalancePence: 0,
        pendingBalancePence: 0,
        totalEarnedPence: 0,
        referralDiscountPercent: 0,
        referralCommissionPercent: 0,
        testMode: mode,
      );

  test(
    'admin identity remains intact while FREE simulation is commercial free',
    () {
      final value = entitlement(UagEntitlementTestMode.free);
      expect(value.hasAdminBypass, isTrue);
      expect(value.hasTestOverride, isTrue);
      expect(value.hasCommercialAdminBypass, isFalse);
      expect(value.effectiveTier, UagSubscriptionTier.free);
      expect(value.adPolicy.showBannerAds, isTrue);
      expect(value.adPolicy.showInterstitialAds, isTrue);
      expect(value.isPremiumLike, isFalse);
      expect(value.canUseTraderProAnalytics, isFalse);
    },
  );

  test('essential simulation keeps banner but removes interruptive ads', () {
    final value = entitlement(UagEntitlementTestMode.essential);
    expect(value.effectiveTier, UagSubscriptionTier.essential);
    expect(value.adPolicy.showBannerAds, isTrue);
    expect(value.adPolicy.showInterstitialAds, isFalse);
    expect(value.adPolicy.showAppOpenAds, isFalse);
  });

  test('premium and pass simulations are premium-like and ad free', () {
    for (final mode in [
      UagEntitlementTestMode.premium,
      UagEntitlementTestMode.pass24Hour,
      UagEntitlementTestMode.pass7Day,
    ]) {
      final value = entitlement(mode);
      expect(value.effectiveTier, UagSubscriptionTier.premium);
      expect(value.isPremiumLike, isTrue);
      expect(value.adPolicy.hasAnyAds, isFalse);
    }
  });

  test('REAL mode preserves admin commercial premium bypass', () {
    final value = entitlement(UagEntitlementTestMode.real);
    expect(value.hasAdminBypass, isTrue);
    expect(value.hasCommercialAdminBypass, isTrue);
    expect(value.effectiveTier, UagSubscriptionTier.premium);
    expect(value.adPolicy.hasAnyAds, isFalse);
  });
}
