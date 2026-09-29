import 'uag_subscription_tier.dart';

enum UagOwnerCampaignPreset {
  owner20,
  owner25,
  owner50,
  christmasNextRenewalFree;

  String get label => switch (this) {
    UagOwnerCampaignPreset.owner20 => '20% off first month',
    UagOwnerCampaignPreset.owner25 => '25% off first month',
    UagOwnerCampaignPreset.owner50 => '50% off first month',
    UagOwnerCampaignPreset.christmasNextRenewalFree =>
      'Next monthly renewal free',
  };

  String get value => switch (this) {
    UagOwnerCampaignPreset.owner20 => 'owner_20',
    UagOwnerCampaignPreset.owner25 => 'owner_25',
    UagOwnerCampaignPreset.owner50 => 'owner_50',
    UagOwnerCampaignPreset.christmasNextRenewalFree =>
      'christmas_next_renewal_free',
  };

  int get discountPercent => switch (this) {
    UagOwnerCampaignPreset.owner20 => 20,
    UagOwnerCampaignPreset.owner25 => 25,
    UagOwnerCampaignPreset.owner50 => 50,
    UagOwnerCampaignPreset.christmasNextRenewalFree => 0,
  };

  int get defaultRedemptionCap => switch (this) {
    UagOwnerCampaignPreset.owner20 => 100,
    UagOwnerCampaignPreset.owner25 => 50,
    UagOwnerCampaignPreset.owner50 => 25,
    UagOwnerCampaignPreset.christmasNextRenewalFree => 250,
  };

  bool get commissionEligible => false;

  bool get nextRenewalFree =>
      this == UagOwnerCampaignPreset.christmasNextRenewalFree;

  List<String> get allowedPlanIds => const <String>[
    'essential_monthly',
    'premium_monthly',
  ];

  static UagOwnerCampaignPreset fromValue(String? value) {
    final normalized = (value ?? '').trim();
    return UagOwnerCampaignPreset.values.firstWhere(
      (preset) => preset.value == normalized,
      orElse: () => UagOwnerCampaignPreset.owner20,
    );
  }
}

class UagCommercialEconomy {
  const UagCommercialEconomy._();

  static const int essentialMonthlyPricePence = 499;
  static const int essentialAnnualPricePence = 4999;
  static const int premiumMonthlyPricePence = 899;
  static const int premiumAnnualPricePence = 8999;

  static const int freeMonthlyTrades = 5;
  static const int freeMonthlyMatchRaiderActions = 5;
  static const int essentialMonthlyTrades = 30;
  static const int essentialMonthlyMatchRaiderActions = 30;

  static const int referralFirstPurchaseDiscountPercent = 10;
  static const int creatorStandardFirstPurchaseDiscountPercent = 20;
  static const int creatorSelectedCampaignDiscountPercent = 25;
  static const int ownerMaximumFirstPurchaseDiscountPercent = 50;

  static const int founderAnnualDiscountPercent = 50;
  static const int founderAnnualLaunchPricePence = 4499;
  static const int founderMembershipCap = 100;

  static const int premiumGiftPricePence = 699;
  static const int premiumGiftDurationDays = 30;
  static const int premiumGiftClaimWindowDays = 30;
  static const int premiumGiftRecipientCooldownDays = 365;
  static const int premiumGiftSenderMonthlyCap = 5;

  static const int commissionValidationDays = 30;
  static const int payoutThresholdPence = 2500;

  static const bool allowDiscountStacking = false;

  static bool usesMonthlyAllowance(UagBillableAction action) =>
      action == UagBillableAction.trade ||
      action == UagBillableAction.matchmakingSearch;

  static String allowancePeriodLabel(UagBillableAction action) =>
      usesMonthlyAllowance(action) ? 'monthly' : 'weekly';

  static int? coreActionLimit({
    required UagSubscriptionTier tier,
    required UagBillableAction action,
  }) {
    if (action == UagBillableAction.trade) {
      return switch (tier) {
        UagSubscriptionTier.free => freeMonthlyTrades,
        UagSubscriptionTier.essential => essentialMonthlyTrades,
        UagSubscriptionTier.premium => null,
      };
    }
    if (action == UagBillableAction.matchmakingSearch) {
      return switch (tier) {
        UagSubscriptionTier.free => freeMonthlyMatchRaiderActions,
        UagSubscriptionTier.essential => essentialMonthlyMatchRaiderActions,
        UagSubscriptionTier.premium => null,
      };
    }
    return null;
  }

  static bool creatorCommissionAllowedForDiscount(int discountPercent) =>
      discountPercent > 0 &&
      discountPercent <= creatorSelectedCampaignDiscountPercent;
}
