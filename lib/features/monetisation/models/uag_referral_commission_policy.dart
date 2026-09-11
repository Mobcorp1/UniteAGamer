class UagReferralCommissionBand {
  const UagReferralCommissionBand({
    required this.minActivePaidReferrals,
    this.maxActivePaidReferrals,
    required this.baseRatePercent,
  });

  final int minActivePaidReferrals;
  final int? maxActivePaidReferrals;
  final double baseRatePercent;

  bool contains(int activePaidReferrals) =>
      activePaidReferrals >= minActivePaidReferrals &&
      (maxActivePaidReferrals == null ||
          activePaidReferrals <= maxActivePaidReferrals!);
}

class UagReferralCommissionPolicy {
  const UagReferralCommissionPolicy._();

  static const double firstPurchaseDiscountPercent = 10;
  static const double premiumBoostPercentagePoints = 2.5;
  static const int commissionValidationDays = 30;

  static const bands = <UagReferralCommissionBand>[
    UagReferralCommissionBand(
      minActivePaidReferrals: 1,
      maxActivePaidReferrals: 4,
      baseRatePercent: 5,
    ),
    UagReferralCommissionBand(
      minActivePaidReferrals: 5,
      maxActivePaidReferrals: 24,
      baseRatePercent: 7.5,
    ),
    UagReferralCommissionBand(
      minActivePaidReferrals: 25,
      maxActivePaidReferrals: 49,
      baseRatePercent: 10,
    ),
    UagReferralCommissionBand(
      minActivePaidReferrals: 50,
      maxActivePaidReferrals: 99,
      baseRatePercent: 12.5,
    ),
    UagReferralCommissionBand(minActivePaidReferrals: 100, baseRatePercent: 15),
  ];

  static double baseRatePercent(int activePaidReferrals) {
    if (activePaidReferrals <= 0) return 0;
    return bands
        .firstWhere((band) => band.contains(activePaidReferrals))
        .baseRatePercent;
  }

  static double effectiveRatePercent({
    required int activePaidReferrals,
    required bool premiumActive,
  }) {
    final base = baseRatePercent(activePaidReferrals);
    if (base <= 0) return 0;
    return base + (premiumActive ? premiumBoostPercentagePoints : 0);
  }

  static UagReferralCommissionBand? nextBand(int activePaidReferrals) {
    for (final band in bands) {
      if (activePaidReferrals < band.minActivePaidReferrals) return band;
    }
    return null;
  }
}
