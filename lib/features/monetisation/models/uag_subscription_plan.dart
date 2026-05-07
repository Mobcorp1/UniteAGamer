import 'uag_plan_limits.dart';
import 'uag_subscription_tier.dart';

class UagSubscriptionPlan {
  const UagSubscriptionPlan({
    required this.tier,
    required this.name,
    required this.monthlyPricePence,
    required this.yearlyPricePence,
    required this.creatorOnboardingDiscountPercent,
    required this.limits,
    required this.features,
  });

  final UagSubscriptionTier tier;
  final String name;
  final int monthlyPricePence;
  final int yearlyPricePence;
  final int creatorOnboardingDiscountPercent;
  final UagPlanLimits limits;
  final List<String> features;

  String get monthlyPriceLabel => monthlyPricePence == 0
      ? 'Free'
      : '£${(monthlyPricePence / 100).toStringAsFixed(2)}/mo';

  String get yearlyPriceLabel => yearlyPricePence == 0
      ? 'Free'
      : '£${(yearlyPricePence / 100).toStringAsFixed(2)}/yr';

  static const plans = <UagSubscriptionPlan>[
    UagSubscriptionPlan(
      tier: UagSubscriptionTier.free,
      name: 'Free',
      monthlyPricePence: 0,
      yearlyPricePence: 0,
      creatorOnboardingDiscountPercent: 0,
      limits: UagPlanLimits.free,
      features: [
        '1 trade per week',
        '1 matchmaking search per week',
        '1 intel hint per week',
        '1 priority slot',
        'Full ad frequency',
        '+1 bonus action after every 5 free referrals',
      ],
    ),
    UagSubscriptionPlan(
      tier: UagSubscriptionTier.essential,
      name: 'Essential',
      monthlyPricePence: 599,
      yearlyPricePence: 4999,
      creatorOnboardingDiscountPercent: 30,
      limits: UagPlanLimits.essential,
      features: [
        '5 trades per week',
        '5 matchmaking searches per week',
        '5 intel hints per week',
        '5 priority slots',
        'Reduced ads',
        '10% follower discount codes',
        '10% recurring commission on paid referrals',
      ],
    ),
    UagSubscriptionPlan(
      tier: UagSubscriptionTier.premium,
      name: 'Premium',
      monthlyPricePence: 1099,
      yearlyPricePence: 9499,
      creatorOnboardingDiscountPercent: 30,
      limits: UagPlanLimits.premium,
      features: [
        'Unlimited trades',
        'Unlimited matchmaking searches',
        'Unlimited intel hints',
        'Unlimited priority tracking',
        'No ads',
        '20% follower discount codes',
        '20% recurring commission on paid referrals',
      ],
    ),
  ];

  static UagSubscriptionPlan forTier(UagSubscriptionTier tier) {
    return plans.firstWhere((plan) => plan.tier == tier);
  }
}
