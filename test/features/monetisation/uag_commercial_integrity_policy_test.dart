import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_commercial_integrity_policy.dart';

void main() {
  test('reward activation blocks overlap and Premium waste', () {
    expect(
      UagCommercialIntegrityPolicy.canActivateBankedReward(
        hasActiveLockerReward: false,
        effectivePremiumActive: false,
      ),
      isTrue,
    );
    expect(
      UagCommercialIntegrityPolicy.canActivateBankedReward(
        hasActiveLockerReward: true,
        effectivePremiumActive: false,
      ),
      isFalse,
    );
    expect(
      UagCommercialIntegrityPolicy.canActivateBankedReward(
        hasActiveLockerReward: false,
        effectivePremiumActive: true,
      ),
      isFalse,
    );
  });

  test('refund and chargeback require original event identity', () {
    expect(
      UagCommercialIntegrityPolicy.requiresOriginalEvent('refund'),
      isTrue,
    );
    expect(
      UagCommercialIntegrityPolicy.requiresOriginalEvent('chargeback'),
      isTrue,
    );
    expect(
      UagCommercialIntegrityPolicy.requiresOriginalEvent('renewal'),
      isFalse,
    );
  });

  test('counters never reconcile below zero', () {
    expect(UagCommercialIntegrityPolicy.safeDecrement(0), 0);
    expect(UagCommercialIntegrityPolicy.safeDecrement(1), 0);
    expect(UagCommercialIntegrityPolicy.safeDecrement(5), 4);
    expect(UagCommercialIntegrityPolicy.nonNegative(-100), 0);
  });
}
