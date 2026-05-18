import 'uag_plan_limits.dart';
import 'uag_subscription_tier.dart';

class UagSubscriptionPlan {
  const UagSubscriptionPlan({
    required this.tier,
    required this.name,
    required this.shortName,
    required this.positioning,
    required this.monthlyPricePence,
    required this.yearlyPricePence,
    required this.creatorOnboardingDiscountPercent,
    required this.limits,
    required this.features,
    required this.bestFor,
  });

  final UagSubscriptionTier tier;
  final String name;
  final String shortName;
  final String positioning;
  final int monthlyPricePence;
  final int yearlyPricePence;
  final int creatorOnboardingDiscountPercent;
  final UagPlanLimits limits;
  final List<String> features;
  final List<String> bestFor;

  String get monthlyPriceLabel => monthlyPricePence == 0
      ? 'Free'
      : '£${(monthlyPricePence / 100).toStringAsFixed(2)}/mo';

  String get yearlyPriceLabel => yearlyPricePence == 0
      ? 'Free'
      : '£${(yearlyPricePence / 100).toStringAsFixed(2)}/yr';

  String get adsLabel {
    if (!limits.hasAds) return 'No ads';
    if (limits.reducedAds) return 'Reduced passive ads';
    return 'Balanced passive ads + optional rewarded boosts';
  }

  static const plans = <UagSubscriptionPlan>[
    UagSubscriptionPlan(
      tier: UagSubscriptionTier.free,
      name: 'Core Raider',
      shortName: 'Free',
      positioning:
          'Useful enough to keep every player contributing to Intel, trading and Match Raider activity.',
      monthlyPricePence: 0,
      yearlyPricePence: 0,
      creatorOnboardingDiscountPercent: 0,
      limits: UagPlanLimits.free,
      features: [
        'Full Blueprint Tracker access',
        'Core UAG Raider voice item advice',
        'Intel contribution stays unlimited',
        'Trade participation with 2 active listings and 5 daily offers',
        '10 weekly trade actions, 10 Match Raider searches and 8 Intel hints',
        '3 priority targets and 2 saved raid plans',
        'Passive ads plus optional rewarded boosts only',
      ],
      bestFor: [
        'new users',
        'casual players',
        'ecosystem growth',
        'Intel and trade liquidity',
      ],
    ),
    UagSubscriptionPlan(
      tier: UagSubscriptionTier.essential,
      name: 'Active Raider',
      shortName: 'Essential',
      positioning:
          'The regular-player tier: higher limits, cleaner experience, smart alerts and stronger voice tools.',
      monthlyPricePence: 499,
      yearlyPricePence: 4999,
      creatorOnboardingDiscountPercent: 20,
      limits: UagPlanLimits.essential,
      features: [
        '10 active trade listings and 25 daily offers',
        '50 weekly trade actions and 50 Match Raider searches',
        '40 weekly Intel hints and 12 premium Intel unlocks',
        'Unlimited advanced voice commands',
        'Smart item, trade and session alerts',
        'Raid Companion presets and 6 voice profiles',
        'Reduced passive ads',
        '10% follower discounts and 10% recurring creator commission',
      ],
      bestFor: [
        'regular players',
        'squad organisers',
        'active traders',
        'users who want fewer ads',
      ],
    ),
    UagSubscriptionPlan(
      tier: UagSubscriptionTier.premium,
      name: 'Elite Raider',
      shortName: 'Premium',
      positioning:
          'The power-user tier: unlimited systems, no ads, Trader Pro analytics and full automation.',
      monthlyPricePence: 999,
      yearlyPricePence: 9999,
      creatorOnboardingDiscountPercent: 25,
      limits: UagPlanLimits.premium,
      features: [
        'Unlimited trade actions, listings and offers',
        'Unlimited Match Raider searches and session tools',
        'Unlimited Intel hints and premium Intel unlocks',
        'Trader Pro analytics and demand alerts',
        'All voice profiles, personalities and Raid Companion automation',
        'Unlimited saved raid plans and priority targets',
        'No ads',
        '20% follower discounts and 20% recurring creator commission',
      ],
      bestFor: [
        'hardcore traders',
        'creators',
        'daily grinders',
        'users who want no ads and full analytics',
      ],
    ),
  ];

  static UagSubscriptionPlan forTier(UagSubscriptionTier tier) {
    return plans.firstWhere((plan) => plan.tier == tier);
  }
}
