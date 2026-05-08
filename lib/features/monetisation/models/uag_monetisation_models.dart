import 'package:cloud_firestore/cloud_firestore.dart';

enum UagPlanTier { free, essential, premium }

extension UagPlanTierX on UagPlanTier {
  String get id {
    switch (this) {
      case UagPlanTier.free:
        return 'free';
      case UagPlanTier.essential:
        return 'essential';
      case UagPlanTier.premium:
        return 'premium';
    }
  }

  String get label {
    switch (this) {
      case UagPlanTier.free:
        return 'Free';
      case UagPlanTier.essential:
        return 'Essential';
      case UagPlanTier.premium:
        return 'Premium';
    }
  }

  static UagPlanTier fromId(String? value) {
    switch ((value ?? '').toLowerCase().trim()) {
      case 'essential':
        return UagPlanTier.essential;
      case 'premium':
        return UagPlanTier.premium;
      case 'free':
      default:
        return UagPlanTier.free;
    }
  }
}

class UagPlanDefinition {
  const UagPlanDefinition({
    required this.tier,
    required this.monthlyPricePence,
    required this.yearlyPricePence,
    required this.weeklyTrades,
    required this.weeklyMatchSearches,
    required this.weeklyIntelHints,
    required this.prioritySlots,
    required this.creatorDiscountPercent,
    required this.creatorCommissionPercent,
    required this.charityProfitPercent,
    required this.adsLabel,
    required this.benefits,
  });

  final UagPlanTier tier;
  final int monthlyPricePence;
  final int yearlyPricePence;
  final int weeklyTrades;
  final int weeklyMatchSearches;
  final int weeklyIntelHints;
  final int prioritySlots;
  final int creatorDiscountPercent;
  final int creatorCommissionPercent;
  final int charityProfitPercent;
  final String adsLabel;
  final List<String> benefits;

  bool get isUnlimited => tier == UagPlanTier.premium;
  String get monthlyPriceLabel => monthlyPricePence == 0 ? '£0' : '£${(monthlyPricePence / 100).toStringAsFixed(2)}';
  String get yearlyPriceLabel => yearlyPricePence == 0 ? '£0' : '£${(yearlyPricePence / 100).toStringAsFixed(2)}';
}

class UagPlans {
  const UagPlans._();

  static const free = UagPlanDefinition(
    tier: UagPlanTier.free,
    monthlyPricePence: 0,
    yearlyPricePence: 0,
    weeklyTrades: 1,
    weeklyMatchSearches: 1,
    weeklyIntelHints: 1,
    prioritySlots: 1,
    creatorDiscountPercent: 0,
    creatorCommissionPercent: 0,
    charityProfitPercent: 0,
    adsLabel: 'Full ads',
    benefits: [
      '1 trade per week',
      '1 Match Raider search per week',
      '1 intel hint per week',
      '1 priority target slot',
      'Ads enabled',
      '+1 extra action per 5 verified free signups',
    ],
  );

  static const essential = UagPlanDefinition(
    tier: UagPlanTier.essential,
    monthlyPricePence: 599,
    yearlyPricePence: 4999,
    weeklyTrades: 5,
    weeklyMatchSearches: 5,
    weeklyIntelHints: 5,
    prioritySlots: 5,
    creatorDiscountPercent: 10,
    creatorCommissionPercent: 10,
    charityProfitPercent: 10,
    adsLabel: 'Reduced ads',
    benefits: [
      '5 trades per week',
      '5 Match Raider searches per week',
      '5 intel hints per week',
      '5 priority target slots',
      'Reduced ads',
      'Creator code: followers get 10% off',
      'Creator commission: 10% recurring on active paid referrals',
      '10% of net platform profit goes into the Essential Impact Pot',
    ],
  );

  static const premium = UagPlanDefinition(
    tier: UagPlanTier.premium,
    monthlyPricePence: 1099,
    yearlyPricePence: 9499,
    weeklyTrades: -1,
    weeklyMatchSearches: -1,
    weeklyIntelHints: -1,
    prioritySlots: -1,
    creatorDiscountPercent: 20,
    creatorCommissionPercent: 20,
    charityProfitPercent: 20,
    adsLabel: 'No ads',
    benefits: [
      'Unlimited trades',
      'Unlimited Match Raider searches',
      'Unlimited intel hints',
      'Unlimited priority tracking',
      'No ads',
      'Creator code: followers get up to 20% off',
      'Creator commission: 20% recurring on active paid referrals',
      '20% of net platform profit goes into the Premium Impact Pot',
    ],
  );

  static const all = <UagPlanDefinition>[free, essential, premium];

  static UagPlanDefinition byTier(UagPlanTier tier) {
    switch (tier) {
      case UagPlanTier.free:
        return free;
      case UagPlanTier.essential:
        return essential;
      case UagPlanTier.premium:
        return premium;
    }
  }
}

class UagEntitlement {
  const UagEntitlement({
    required this.uid,
    required this.tier,
    required this.subscriptionStatus,
    required this.isAdmin,
    required this.isDev,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.currentPeriodEnd,
    this.referralCode,
  });

  final String uid;
  final UagPlanTier tier;
  final String subscriptionStatus;
  final bool isAdmin;
  final bool isDev;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final DateTime? currentPeriodEnd;
  final String? referralCode;

  bool get hasUnlimitedAccess => isAdmin || isDev || tier == UagPlanTier.premium;
  bool get isPaid => tier == UagPlanTier.essential || tier == UagPlanTier.premium;
  UagPlanDefinition get plan => UagPlans.byTier(tier);

  factory UagEntitlement.fromUserDoc(String uid, Map<String, dynamic> data) {
    final monetisation = (data['monetisation'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final tier = UagPlanTierX.fromId(
      (monetisation['tier'] ?? data['tier'] ?? data['planTier'])?.toString(),
    );
    final periodValue = monetisation['currentPeriodEnd'] ?? data['currentPeriodEnd'];
    return UagEntitlement(
      uid: uid,
      tier: tier,
      subscriptionStatus: (monetisation['subscriptionStatus'] ?? data['subscriptionStatus'] ?? 'inactive').toString(),
      isAdmin: data['isAdmin'] == true,
      isDev: data['isDev'] == true,
      stripeCustomerId: (monetisation['stripeCustomerId'] ?? data['stripeCustomerId'])?.toString(),
      stripeSubscriptionId: (monetisation['stripeSubscriptionId'] ?? data['stripeSubscriptionId'])?.toString(),
      currentPeriodEnd: periodValue is Timestamp ? periodValue.toDate() : null,
      referralCode: (monetisation['referralCode'] ?? data['referralCode'])?.toString(),
    );
  }
}

class UagUsageSnapshot {
  const UagUsageSnapshot({
    required this.tradesUsed,
    required this.matchSearchesUsed,
    required this.intelHintsUsed,
    required this.extraActionsAvailable,
  });

  final int tradesUsed;
  final int matchSearchesUsed;
  final int intelHintsUsed;
  final int extraActionsAvailable;

  factory UagUsageSnapshot.fromMap(Map<String, dynamic> data) {
    return UagUsageSnapshot(
      tradesUsed: (data['tradesUsed'] as num?)?.toInt() ?? 0,
      matchSearchesUsed: (data['matchSearchesUsed'] as num?)?.toInt() ?? 0,
      intelHintsUsed: (data['intelHintsUsed'] as num?)?.toInt() ?? 0,
      extraActionsAvailable: (data['extraActionsAvailable'] as num?)?.toInt() ?? 0,
    );
  }
}

class UagImpactPotSnapshot {
  const UagImpactPotSnapshot({
    required this.id,
    required this.label,
    required this.monthlyPence,
    required this.allTimePence,
    required this.contributingUsers,
    this.lastAllocatedAt,
  });

  final String id;
  final String label;
  final int monthlyPence;
  final int allTimePence;
  final int contributingUsers;
  final DateTime? lastAllocatedAt;

  factory UagImpactPotSnapshot.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return UagImpactPotSnapshot(
      id: doc.id,
      label: (data['label'] ?? doc.id).toString(),
      monthlyPence: (data['monthlyPence'] as num?)?.toInt() ?? 0,
      allTimePence: (data['allTimePence'] as num?)?.toInt() ?? 0,
      contributingUsers: (data['contributingUsers'] as num?)?.toInt() ?? 0,
      lastAllocatedAt: data['lastAllocatedAt'] is Timestamp ? (data['lastAllocatedAt'] as Timestamp).toDate() : null,
    );
  }
}
