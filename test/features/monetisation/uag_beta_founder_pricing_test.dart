import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_beta_founder_pricing.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_tier.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_user_entitlement.dart';

void main() {
  test('closed beta offers keep the agreed protected prices', () {
    expect(UagBetaCommercialOffer.premiumMonthly.pricePence, 699);
    expect(UagBetaCommercialOffer.premiumAnnual.pricePence, 4999);
    expect(UagBetaCommercialOffer.premiumDayPass.pricePence, 149);
    expect(UagBetaCommercialOffer.premiumWeekPass.pricePence, 249);
    expect(UagBetaCommercialOffer.foundingRaiderAnnual.pricePence, 2999);
    expect(
      UagBetaCommercialOffer.foundingRaiderAnnual.checkoutPlanId,
      'founding_raider_premium_yearly',
    );
  });

  test('founder lifetime rate is unavailable after forfeiture', () {
    final status =
        UagBetaFounderStatus.fromRecognitionDoc(const <String, dynamic>{
          'betaTester': true,
          'foundingRaider': true,
          'founderRateForfeited': true,
          'wallOfLegendsInducted': true,
        });

    expect(status.hasBetaPricing, isTrue);
    expect(status.isFoundingRaider, isTrue);
    expect(status.hasFoundingRaiderRate, isFalse);
    expect(status.wallOfLegendsInducted, isTrue);
  });

  test('pending paid tier never grants paid app access before activation', () {
    const entitlement = UagUserEntitlement(
      uid: 'test-user',
      tier: UagSubscriptionTier.premium,
      subscriptionStatus: 'pending',
      isAdmin: false,
      isDev: false,
      referralCode: null,
      availableBalancePence: 0,
      pendingBalancePence: 0,
      totalEarnedPence: 0,
      referralDiscountPercent: 0,
      referralCommissionPercent: 0,
    );

    expect(entitlement.hasActiveCoreSubscription, isFalse);
    expect(entitlement.effectiveTier, UagSubscriptionTier.free);
    expect(entitlement.isPaid, isFalse);
  });

  test('active premium tier grants premium app access', () {
    const entitlement = UagUserEntitlement(
      uid: 'test-user',
      tier: UagSubscriptionTier.premium,
      subscriptionStatus: 'active',
      isAdmin: false,
      isDev: false,
      referralCode: null,
      availableBalancePence: 0,
      pendingBalancePence: 0,
      totalEarnedPence: 0,
      referralDiscountPercent: 0,
      referralCommissionPercent: 0,
    );

    expect(entitlement.hasActiveCoreSubscription, isTrue);
    expect(entitlement.effectiveTier, UagSubscriptionTier.premium);
    expect(entitlement.isPaid, isTrue);
  });
}
