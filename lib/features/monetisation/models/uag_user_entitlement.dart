import 'package:cloud_firestore/cloud_firestore.dart';

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
  UagPlanLimits get limits => hasAdminBypass
      ? UagPlanLimits.premium
      : UagPlanLimits.forTier(tier);

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

    final tier = UagSubscriptionTier.fromValue(
      data['subscriptionTier'] as String? ?? data['tier'] as String?,
    );
    final limits = UagPlanLimits.forTier(tier);

    return UagUserEntitlement(
      uid: uid,
      tier: tier,
      subscriptionStatus: (data['subscriptionStatus'] as String?) ?? 'inactive',
      isAdmin: data['isAdmin'] == true,
      isDev: data['isDev'] == true,
      referralCode: data['referralCode'] as String?,
      availableBalancePence: (data['referralAvailableBalancePence'] as num?)?.toInt() ?? 0,
      pendingBalancePence: (data['referralPendingBalancePence'] as num?)?.toInt() ?? 0,
      totalEarnedPence: (data['referralTotalEarnedPence'] as num?)?.toInt() ?? 0,
      referralDiscountPercent: (data['referralDiscountPercent'] as num?)?.toInt() ?? limits.referralDiscountPercent,
      referralCommissionPercent: (data['referralCommissionPercent'] as num?)?.toInt() ?? limits.referralCommissionPercent,
      currentPeriodEnd: parseDate(data['subscriptionCurrentPeriodEnd']),
    );
  }
}
