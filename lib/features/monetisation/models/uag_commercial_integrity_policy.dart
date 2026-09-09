class UagCommercialIntegrityPolicy {
  const UagCommercialIntegrityPolicy._();

  static int safeDecrement(int current) => current <= 0 ? 0 : current - 1;

  static bool canActivateBankedReward({
    required bool hasActiveLockerReward,
    required bool effectivePremiumActive,
  }) => !hasActiveLockerReward && !effectivePremiumActive;

  static bool requiresOriginalEvent(String eventType) =>
      eventType == 'refund' || eventType == 'chargeback';

  static int nonNegative(int value) => value < 0 ? 0 : value;
}
