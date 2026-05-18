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

  String get publicName {
    switch (this) {
      case UagPlanTier.free:
        return 'Core Raider';
      case UagPlanTier.essential:
        return 'Active Raider';
      case UagPlanTier.premium:
        return 'Elite Raider';
    }
  }

  static UagPlanTier fromId(String? value) {
    switch ((value ?? '').toLowerCase().trim()) {
      case 'essential':
      case 'active_raider':
      case 'active-raider':
        return UagPlanTier.essential;
      case 'premium':
      case 'elite':
      case 'elite_raider':
      case 'elite-raider':
        return UagPlanTier.premium;
      case 'free':
      case 'core':
      case 'core_raider':
      case 'core-raider':
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
  String get monthlyPriceLabel => monthlyPricePence == 0
      ? '£0'
      : '£${(monthlyPricePence / 100).toStringAsFixed(2)}';
  String get yearlyPriceLabel => yearlyPricePence == 0
      ? '£0'
      : '£${(yearlyPricePence / 100).toStringAsFixed(2)}';
}

class UagPlans {
  const UagPlans._();

  static const free = UagPlanDefinition(
    tier: UagPlanTier.free,
    monthlyPricePence: 0,
    yearlyPricePence: 0,
    weeklyTrades: 10,
    weeklyMatchSearches: 10,
    weeklyIntelHints: 8,
    prioritySlots: 3,
    creatorDiscountPercent: 0,
    creatorCommissionPercent: 0,
    charityProfitPercent: 0,
    adsLabel: 'Passive ads + optional rewarded boosts',
    benefits: [
      'Full Blueprint Tracker access',
      'Core UAG Raider voice item advice',
      'Unlimited Intel contribution',
      '2 active listings and 5 daily offers',
      '10 weekly trade actions',
      '10 weekly Match Raider searches',
      '8 weekly Intel hints and 3 priority targets',
      'No forced ads during voice assistant or active sessions',
    ],
  );

  static const essential = UagPlanDefinition(
    tier: UagPlanTier.essential,
    monthlyPricePence: 499,
    yearlyPricePence: 4999,
    weeklyTrades: 50,
    weeklyMatchSearches: 50,
    weeklyIntelHints: 40,
    prioritySlots: 10,
    creatorDiscountPercent: 10,
    creatorCommissionPercent: 10,
    charityProfitPercent: 10,
    adsLabel: 'Reduced passive ads',
    benefits: [
      '10 active trade listings and 25 daily offers',
      '50 weekly trade actions and 50 Match Raider searches',
      '40 weekly Intel hints and 12 premium Intel unlocks',
      'Unlimited advanced voice commands',
      'Smart trade, item and session alerts',
      'Raid Companion presets and enhanced voice profiles',
      '10% follower discounts and 10% recurring creator commission',
      '10% of net platform profit goes into the Essential Impact Pot',
    ],
  );

  static const premium = UagPlanDefinition(
    tier: UagPlanTier.premium,
    monthlyPricePence: 999,
    yearlyPricePence: 9999,
    weeklyTrades: -1,
    weeklyMatchSearches: -1,
    weeklyIntelHints: -1,
    prioritySlots: -1,
    creatorDiscountPercent: 20,
    creatorCommissionPercent: 20,
    charityProfitPercent: 20,
    adsLabel: 'No ads',
    benefits: [
      'Unlimited listings, offers, trades and sessions',
      'Unlimited Match Raider searches',
      'Unlimited Intel hints and premium Intel unlocks',
      'Trader Pro analytics and demand alerts',
      'All UAG Raider voice profiles and personalities',
      'Unlimited Raid Companion automation and saved raid plans',
      'No ads anywhere',
      '20% follower discounts and 20% recurring creator commission',
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

  bool get hasUnlimitedAccess =>
      isAdmin || isDev || tier == UagPlanTier.premium;
  bool get isPaid =>
      tier == UagPlanTier.essential || tier == UagPlanTier.premium;
  UagPlanDefinition get plan => UagPlans.byTier(tier);

  factory UagEntitlement.fromUserDoc(String uid, Map<String, dynamic> data) {
    final monetisation =
        (data['monetisation'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final tier = UagPlanTierX.fromId(
      (data['subscriptionTier'] ??
              monetisation['tier'] ??
              data['tier'] ??
              data['planTier'])
          ?.toString(),
    );
    final periodValue =
        monetisation['currentPeriodEnd'] ??
        data['currentPeriodEnd'] ??
        data['subscriptionCurrentPeriodEnd'];
    return UagEntitlement(
      uid: uid,
      tier: tier,
      subscriptionStatus:
          (data['subscriptionStatus'] ??
                  monetisation['subscriptionStatus'] ??
                  'inactive')
              .toString(),
      isAdmin: data['isAdmin'] == true,
      isDev: data['isDev'] == true,
      stripeCustomerId:
          (monetisation['stripeCustomerId'] ?? data['stripeCustomerId'])
              ?.toString(),
      stripeSubscriptionId:
          (monetisation['stripeSubscriptionId'] ?? data['stripeSubscriptionId'])
              ?.toString(),
      currentPeriodEnd: periodValue is Timestamp ? periodValue.toDate() : null,
      referralCode: (data['referralCode'] ?? monetisation['referralCode'])
          ?.toString(),
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
      tradesUsed:
          (data['tradesUsed'] as num?)?.toInt() ??
          (data['tradeActions'] as num?)?.toInt() ??
          0,
      matchSearchesUsed:
          (data['matchSearchesUsed'] as num?)?.toInt() ??
          (data['matchRaiderSearches'] as num?)?.toInt() ??
          0,
      intelHintsUsed:
          (data['intelHintsUsed'] as num?)?.toInt() ??
          (data['intelUnlocks'] as num?)?.toInt() ??
          0,
      extraActionsAvailable:
          (data['extraActionsAvailable'] as num?)?.toInt() ?? 0,
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

  factory UagImpactPotSnapshot.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final last = data['lastAllocatedAt'];
    return UagImpactPotSnapshot(
      id: doc.id,
      label: (data['label'] ?? doc.id).toString(),
      monthlyPence: (data['monthlyPence'] as num?)?.toInt() ?? 0,
      allTimePence: (data['allTimePence'] as num?)?.toInt() ?? 0,
      contributingUsers: (data['contributingUsers'] as num?)?.toInt() ?? 0,
      lastAllocatedAt: last is Timestamp ? last.toDate() : null,
    );
  }
}
