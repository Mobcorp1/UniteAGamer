import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_premium_pass_entitlement.dart';

void main() {
  test('premium pass catalogue prices are fixed', () {
    expect(UagPremiumPassType.day24.pricePence, 199);
    expect(UagPremiumPassType.week7.pricePence, 349);
  });

  test('passes are reusable whenever no pass is active', () {
    expect(
      UagPremiumPassEntitlement.none.canPurchase(UagPremiumPassType.day24),
      isTrue,
    );
    expect(
      UagPremiumPassEntitlement.none.canPurchase(UagPremiumPassType.week7),
      isTrue,
    );

    final expired = UagPremiumPassEntitlement(
      type: UagPremiumPassType.day24,
      expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      usedDay24: true,
      usedWeek7: true,
    );
    expect(expired.canPurchase(UagPremiumPassType.day24), isTrue);
    expect(expired.canPurchase(UagPremiumPassType.week7), isTrue);
  });
}
