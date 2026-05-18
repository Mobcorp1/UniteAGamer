import 'package:cloud_firestore/cloud_firestore.dart';

import 'uag_ad_policy.dart';
import 'uag_plan_limits.dart';
import 'uag_subscription_tier.dart';

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
    this.currentPeriodEnd,
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
  final DateTime? currentPeriodEnd;

  bool get hasAdminBypass => isAdmin || isDev;
  bool get isPaid => hasAdminBypass || tier.isPaid;
  bool get isPremiumLike =>
      hasAdminBypass || tier == UagSubscriptionTier.premium;

  UagPlanLimits get limits =>
      hasAdminBypass ? UagPlanLimits.premium : UagPlanLimits.forTier(tier);

  UagAdPolicy get adPolicy =>
      hasAdminBypass ? UagAdPolicy.premium : UagAdPolicy.forTier(tier);

  bool get canShowAds => adPolicy.hasAnyAds;
  bool get canUseTraderProAnalytics =>
      hasAdminBypass || limits.hasTraderProAnalytics;
  bool get canUseAdvancedVoicePersonalities =>
      hasAdminBypass || limits.hasAdvancedVoicePersonalities;
  bool get canUseSmartAlerts => hasAdminBypass || limits.hasSmartAlerts;
  bool get canUseUnlimitedSessions =>
      hasAdminBypass || limits.hasUnlimitedSessions;
  bool get canDisableAds => hasAdminBypass || limits.canDisableAds;

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
      currentPeriodEnd: parseDate(
        data['subscriptionCurrentPeriodEnd'] ??
            monetisation['currentPeriodEnd'],
      ),
    );
  }
}
