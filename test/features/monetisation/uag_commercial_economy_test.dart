import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_ad_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_commercial_economy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_plan_limits.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_raider_mark_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_plan.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_tier.dart';

void main() {
  test('launch subscription prices are locked', () {
    expect(UagSubscriptionPlan.forTier(UagSubscriptionTier.essential).monthlyPricePence, 499);
    expect(UagSubscriptionPlan.forTier(UagSubscriptionTier.essential).yearlyPricePence, 4999);
    expect(UagSubscriptionPlan.forTier(UagSubscriptionTier.premium).monthlyPricePence, 899);
    expect(UagSubscriptionPlan.forTier(UagSubscriptionTier.premium).yearlyPricePence, 8999);
  });

  test('trade and Match Raider limits use the agreed monthly values', () {
    expect(UagPlanLimits.free.monthlyTrades, 5);
    expect(UagPlanLimits.free.monthlyMatchmakingSearches, 5);
    expect(UagPlanLimits.essential.monthlyTrades, 30);
    expect(UagPlanLimits.essential.monthlyMatchmakingSearches, 30);
    expect(UagPlanLimits.premium.unlimitedTrades, isTrue);
    expect(UagPlanLimits.premium.unlimitedMatchmaking, isTrue);
    expect(
      UagCommercialEconomy.usesMonthlyAllowance(UagBillableAction.trade),
      isTrue,
    );
    expect(
      UagCommercialEconomy.usesMonthlyAllowance(
        UagBillableAction.matchmakingSearch,
      ),
      isTrue,
    );
    expect(
      UagCommercialEconomy.usesMonthlyAllowance(UagBillableAction.intelHint),
      isFalse,
    );
  });

  test('Founding Premium and gift economics are capped', () {
    expect(UagCommercialEconomy.founderAnnualLaunchPricePence, 4499);
    expect(UagCommercialEconomy.founderMembershipCap, 100);
    expect(UagCommercialEconomy.premiumGiftPricePence, 699);
    expect(UagCommercialEconomy.premiumGiftDurationDays, 30);
    expect(UagCommercialEconomy.premiumGiftClaimWindowDays, 30);
    expect(UagCommercialEconomy.premiumGiftRecipientCooldownDays, 365);
    expect(UagCommercialEconomy.premiumGiftSenderMonthlyCap, 5);
  });

  test('owner campaigns never stack or earn commission', () {
    expect(UagCommercialEconomy.allowDiscountStacking, isFalse);
    expect(UagOwnerCampaignPreset.owner20.discountPercent, 20);
    expect(UagOwnerCampaignPreset.owner25.discountPercent, 25);
    expect(UagOwnerCampaignPreset.owner50.discountPercent, 50);
    expect(UagOwnerCampaignPreset.owner50.commissionEligible, isFalse);
    expect(
      UagOwnerCampaignPreset.christmasNextRenewalFree.nextRenewalFree,
      isTrue,
    );
    expect(UagCommercialEconomy.creatorCommissionAllowedForDiscount(25), isTrue);
    expect(UagCommercialEconomy.creatorCommissionAllowedForDiscount(50), isFalse);
  });

  test('Raider Marks preserve a material gap to Essential', () {
    expect(UagRaiderMarkPolicy.marksPerCompletedAd, 1);
    expect(UagRaiderMarkPolicy.marksPerBonusAction, 5);
    expect(UagRaiderMarkPolicy.walletCap, 10);
    expect(UagRaiderMarkPolicy.maxRewardedAdsPerDay, 3);
    expect(UagRaiderMarkPolicy.maxRewardedAdsPerMonth, 20);
    expect(UagRaiderMarkPolicy.maxBonusRedemptionsPerMonth, 4);
    expect(UagRaiderMarkPolicy.minimumAdInterval, const Duration(minutes: 20));

    final now = DateTime.utc(2026, 9, 29);
    expect(
      UagRaiderMarkPolicy.canEarnMark(
        policy: UagAdPolicy.free,
        signedIn: true,
        consentGranted: true,
        serverGrantReady: true,
        explicitlyRequested: true,
        walletBalance: 4,
        verifiedAdsToday: 1,
        verifiedAdsThisMonth: 5,
        now: now,
        lastVerifiedAdAt: now.subtract(const Duration(minutes: 21)),
      ),
      isTrue,
    );
    expect(
      UagRaiderMarkPolicy.canRedeem(
        policy: UagAdPolicy.free,
        walletBalance: 5,
        redemptionsThisMonth: 3,
      ),
      isTrue,
    );
    expect(
      UagRaiderMarkPolicy.canRedeem(
        policy: UagAdPolicy.free,
        walletBalance: 10,
        redemptionsThisMonth: 4,
      ),
      isFalse,
    );
  });
}
