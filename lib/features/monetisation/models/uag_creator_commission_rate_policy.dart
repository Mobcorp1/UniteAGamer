class UagCreatorCommissionRatePolicy {
  const UagCreatorCommissionRatePolicy._();

  static double baseRatePercent(double points) {
    if (points >= 100) return 20;
    if (points >= 60) return 17.5;
    if (points >= 40) return 15;
    if (points >= 25) return 12.5;
    if (points >= 15) return 10;
    if (points >= 8) return 7.5;
    if (points >= 1) return 5;
    return 0;
  }

  static double communityUpliftPercent(int qualifiedActiveUsers) {
    if (qualifiedActiveUsers >= 250000) return 2.5;
    if (qualifiedActiveUsers >= 100000) return 2.0;
    if (qualifiedActiveUsers >= 50000) return 1.5;
    if (qualifiedActiveUsers >= 25000) return 1.0;
    if (qualifiedActiveUsers >= 10000) return 0.5;
    return 0;
  }

  static double effectiveRatePercent({
    required double points,
    required int qualifiedActiveUsers,
  }) {
    final base = baseRatePercent(points);
    final uplift = communityUpliftPercent(qualifiedActiveUsers);
    return base + uplift;
  }
}
