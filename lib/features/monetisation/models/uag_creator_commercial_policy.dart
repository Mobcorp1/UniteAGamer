enum UagCreatorRewardKind {
  essential7Day,
  essentialMonth,
  premium7Day,
  premiumMonth,
  annualPremium,
  seasonalCampaign,
}

class UagCreatorMonthlyAllocation {
  const UagCreatorMonthlyAllocation({
    this.essential7Day = 0,
    this.essentialMonth = 0,
    this.premium7Day = 0,
    this.premiumMonth = 0,
    this.annualPremiumPerQuarter = 0,
    this.seasonalCampaignAccess = false,
  });

  final int essential7Day;
  final int essentialMonth;
  final int premium7Day;
  final int premiumMonth;
  final int annualPremiumPerQuarter;
  final bool seasonalCampaignAccess;
}

class UagCreatorLevel {
  const UagCreatorLevel({
    required this.name,
    required this.minPoints,
    required this.maxPoints,
    required this.commissionBasisPoints,
    required this.allocation,
  });

  final String name;
  final double minPoints;
  final double? maxPoints;
  final int commissionBasisPoints;
  final UagCreatorMonthlyAllocation allocation;

  double get commissionPercent => commissionBasisPoints / 100;
  bool contains(double points) =>
      points >= minPoints && (maxPoints == null || points <= maxPoints!);
}

class UagCreatorCommercialPolicy {
  const UagCreatorCommercialPolicy._();

  static const double essentialPoints = 1;
  static const double premiumPoints = 1.5;
  static const int creatorPremiumPricePence = 799;
  static const int commissionValidationDays = 30;
  static const int tierGraceDays = 30;

  static const levels = <UagCreatorLevel>[
    UagCreatorLevel(
      name: 'Raider',
      minPoints: 1,
      maxPoints: 7.99,
      commissionBasisPoints: 500,
      allocation: UagCreatorMonthlyAllocation(essential7Day: 2),
    ),
    UagCreatorLevel(
      name: 'Scout',
      minPoints: 8,
      maxPoints: 14.99,
      commissionBasisPoints: 750,
      allocation: UagCreatorMonthlyAllocation(
        essential7Day: 2,
        essentialMonth: 1,
      ),
    ),
    UagCreatorLevel(
      name: 'Squad Leader',
      minPoints: 15,
      maxPoints: 24.99,
      commissionBasisPoints: 1000,
      allocation: UagCreatorMonthlyAllocation(
        essentialMonth: 2,
        premium7Day: 1,
      ),
    ),
    UagCreatorLevel(
      name: 'Commander',
      minPoints: 25,
      maxPoints: 39.99,
      commissionBasisPoints: 1250,
      allocation: UagCreatorMonthlyAllocation(
        essentialMonth: 2,
        premiumMonth: 1,
      ),
    ),
    UagCreatorLevel(
      name: 'Vanguard',
      minPoints: 40,
      maxPoints: 59.99,
      commissionBasisPoints: 1500,
      allocation: UagCreatorMonthlyAllocation(
        essentialMonth: 3,
        premiumMonth: 2,
      ),
    ),
    UagCreatorLevel(
      name: 'Elite',
      minPoints: 60,
      maxPoints: 99.99,
      commissionBasisPoints: 1750,
      allocation: UagCreatorMonthlyAllocation(
        essentialMonth: 4,
        premiumMonth: 3,
        seasonalCampaignAccess: true,
      ),
    ),
    UagCreatorLevel(
      name: 'Legend',
      minPoints: 100,
      maxPoints: null,
      commissionBasisPoints: 2000,
      allocation: UagCreatorMonthlyAllocation(
        essentialMonth: 5,
        premiumMonth: 4,
        annualPremiumPerQuarter: 1,
        seasonalCampaignAccess: true,
      ),
    ),
  ];

  static double pointsFor({required int essential, required int premium}) =>
      (essential * essentialPoints) + (premium * premiumPoints);

  static UagCreatorLevel? levelForPoints(double points) {
    if (points < 1) return null;
    return levels.firstWhere((level) => level.contains(points));
  }

  static int commissionPence({
    required int eligibleNetRevenuePence,
    required double creatorPoints,
  }) {
    final level = levelForPoints(creatorPoints);
    if (level == null || eligibleNetRevenuePence <= 0) return 0;
    return (eligibleNetRevenuePence * level.commissionBasisPoints / 10000)
        .floor();
  }

  static bool canStackDiscounts({
    required bool campaignExplicitlyAllowsStacking,
  }) => campaignExplicitlyAllowsStacking;
}
