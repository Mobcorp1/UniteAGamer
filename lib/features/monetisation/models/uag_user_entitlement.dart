import 'package:cloud_firestore/cloud_firestore.dart';

import 'uag_ad_policy.dart';
import 'uag_beta_founder_pricing.dart';
import 'uag_creator_temporary_entitlement.dart';
import 'uag_entitlement_test_mode.dart';
import 'uag_match_intelligence_copy.dart';
import 'uag_plan_limits.dart';
import 'uag_premium_pass_entitlement.dart';
import 'uag_subscription_tier.dart';
import 'uag_supporter_entitlement.dart';

class UagUserEntitlement {
  const UagUserEntitlement({
    required this.uid,
    required this.tier,
    required this.subscriptionStatus,
    required this.isAdmin,
    required this.isDev,
    required this.referralCode,
    required this.availableBalancePence,
    required this.pendingBalancePence,
    required this.totalEarnedPence,
    required this.referralDiscountPercent,
    required this.referralCommissionPercent,
    this.supporter = UagSupporterEntitlement.none,
    this.betaFounderStatus = UagBetaFounderStatus.none,
    this.premiumPass = UagPremiumPassEntitlement.none,
    this.creatorRewardEntitlements = const <UagCreatorTemporaryEntitlement>[],
    this.currentPeriodEnd,
    this.testMode = UagEntitlementTestMode.real,
  });

  final String uid;
  final UagSubscriptionTier tier;
  final String subscriptionStatus;
  final bool isAdmin;
  final bool isDev;
  final String? referralCode;
  final int availableBalancePence;
  final int pendingBalancePence;
  final int totalEarnedPence;
  final int referralDiscountPercent;
  final int referralCommissionPercent;
  final UagSupporterEntitlement supporter;
  final UagBetaFounderStatus betaFounderStatus;
  final UagPremiumPassEntitlement premiumPass;
  final List<UagCreatorTemporaryEntitlement> creatorRewardEntitlements;
  final DateTime? currentPeriodEnd;
  final UagEntitlementTestMode testMode;

  bool get hasAdminBypass => isAdmin || isDev;

  /// True when an admin/dev is intentionally simulating a customer tier.
  /// Security identity remains unchanged; only commercial behaviour is
  /// overridden.
  bool get hasTestOverride =>
      hasAdminBypass && testMode != UagEntitlementTestMode.real;

  /// Admin/dev bypass is commercial only while REAL mode is active.
  bool get hasCommercialAdminBypass => hasAdminBypass && !hasTestOverride;

  bool get hasActiveCoreSubscription {
    final status = subscriptionStatus.trim().toLowerCase();
    return status == 'active' || status == 'trialing';
  }

  bool get hasActivePremiumPass => premiumPass.active;
  bool get hasActiveCreatorReward =>
      creatorRewardEntitlements.any((grant) => grant.active);
  DateTime? get nextCreatorRewardExpiryAt =>
      nextCreatorRewardExpiry(creatorRewardEntitlements);

  /// Canonical tier for every commercial decision in the app.
  ///
  /// Firestore/admin security must continue to use [isAdmin]/[isDev]. Ads,
  /// limits, paid gates and premium-pass behaviour must use this value.
  UagSubscriptionTier get effectiveTier {
    if (hasTestOverride) {
      return switch (testMode) {
        UagEntitlementTestMode.free => UagSubscriptionTier.free,
        UagEntitlementTestMode.essential => UagSubscriptionTier.essential,
        UagEntitlementTestMode.premium ||
        UagEntitlementTestMode.pass24Hour ||
        UagEntitlementTestMode.pass7Day => UagSubscriptionTier.premium,
        UagEntitlementTestMode.real => tier,
      };
    }

    if (hasCommercialAdminBypass || hasActivePremiumPass) {
      return UagSubscriptionTier.premium;
    }
    final activeCoreTier = hasActiveCoreSubscription
        ? tier
        : UagSubscriptionTier.free;
    return highestCreatorRewardTier(creatorRewardEntitlements, activeCoreTier);
  }

  bool get isPaid => effectiveTier.isPaid;
  bool get isPremiumLike => effectiveTier == UagSubscriptionTier.premium;
  bool get hasSupporter => supporter.active;
  bool get hasFoundingSupporter =>
      supporter.active && supporter.foundingSupporter;
  bool get hasBetaPricing => betaFounderStatus.hasBetaPricing;
  bool get hasFoundingRaiderRate => betaFounderStatus.hasFoundingRaiderRate;
  bool get isWallOfLegendsInducted => betaFounderStatus.wallOfLegendsInducted;
  int get futureSupporterDiscountPercent =>
      supporter.hasFutureDiscount ? supporter.discountPercent : 0;

  UagPlanLimits get limits => UagPlanLimits.forTier(effectiveTier);
  UagAdPolicy get adPolicy => UagAdPolicy.forTier(effectiveTier);
  UagMatchIntelligenceTierCopy get matchIntelligence =>
      UagMatchIntelligenceCopy.forTier(effectiveTier);

  bool get canShowAds => adPolicy.hasAnyAds;
  bool get canUseTraderProAnalytics => limits.hasTraderProAnalytics;
  bool get canUseAdvancedVoicePersonalities =>
      limits.hasAdvancedVoicePersonalities;
  bool get canUseSmartAlerts => limits.hasSmartAlerts;
  bool get canUseUnlimitedSessions => limits.hasUnlimitedSessions;
  bool get canDisableAds => limits.canDisableAds;

  factory UagUserEntitlement.fromUserDoc({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final monetisation =
        (data['monetisation'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final tier = UagSubscriptionTier.fromValue(
      data['subscriptionTier'] as String? ??
          data['tier'] as String? ??
          data['planTier'] as String? ??
          monetisation['tier']?.toString(),
    );
    final limits = UagPlanLimits.forTier(tier);

    return UagUserEntitlement(
      uid: uid,
      tier: tier,
      subscriptionStatus:
          (data['subscriptionStatus'] as String?) ??
          monetisation['subscriptionStatus']?.toString() ??
          'inactive',
      isAdmin: data['isAdmin'] == true,
      isDev: data['isDev'] == true,
      referralCode:
          data['referralCode'] as String? ??
          monetisation['referralCode']?.toString(),
      availableBalancePence:
          (data['referralAvailableBalancePence'] as num?)?.toInt() ??
          (monetisation['availableBalancePence'] as num?)?.toInt() ??
          0,
      pendingBalancePence:
          (data['referralPendingBalancePence'] as num?)?.toInt() ??
          (monetisation['pendingBalancePence'] as num?)?.toInt() ??
          0,
      totalEarnedPence:
          (data['referralTotalEarnedPence'] as num?)?.toInt() ??
          (monetisation['totalEarnedPence'] as num?)?.toInt() ??
          0,
      referralDiscountPercent:
          (data['referralDiscountPercent'] as num?)?.toInt() ??
          (monetisation['referralDiscountPercent'] as num?)?.toInt() ??
          limits.referralDiscountPercent,
      referralCommissionPercent:
          (data['referralCommissionPercent'] as num?)?.toInt() ??
          (monetisation['referralCommissionPercent'] as num?)?.toInt() ??
          limits.referralCommissionPercent,
      betaFounderStatus: UagBetaFounderStatus.fromUserDoc(data),
      supporter: UagSupporterEntitlement.fromMap(
        (monetisation['supporter'] as Map?)?.cast<String, dynamic>() ??
            (data['supporter'] as Map?)?.cast<String, dynamic>(),
      ),
      premiumPass: UagPremiumPassEntitlement.fromMap(
        (monetisation['premiumPass'] as Map?)?.cast<String, dynamic>() ??
            (data['premiumPass'] as Map?)?.cast<String, dynamic>(),
      ),
      creatorRewardEntitlements: _parseCreatorRewardEntitlements(
        data['creatorRewardEntitlements'],
      ),
      currentPeriodEnd: parseDate(
        data['subscriptionCurrentPeriodEnd'] ??
            monetisation['currentPeriodEnd'],
      ),
      testMode: UagEntitlementTestMode.fromValue(
        ((data['entitlementTest'] as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{})['mode']
            ?.toString(),
      ),
    );
  }
}

List<UagCreatorTemporaryEntitlement> _parseCreatorRewardEntitlements(
  dynamic raw,
) {
  if (raw is! Map) return const <UagCreatorTemporaryEntitlement>[];
  final grants = <UagCreatorTemporaryEntitlement>[];
  for (final entry in raw.entries) {
    final value = entry.value;
    if (value is! Map) continue;
    grants.add(
      UagCreatorTemporaryEntitlement.fromMap(
        entry.key.toString(),
        Map<String, dynamic>.from(value),
      ),
    );
  }
  return List<UagCreatorTemporaryEntitlement>.unmodifiable(grants);
}
