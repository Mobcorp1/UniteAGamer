import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_premium_pass_entitlement.dart';

void main() {
  test('premium pass catalogue prices are fixed', () {
    expect(UagPremiumPassType.day24.pricePence, 199);
    expect(UagPremiumPassType.week7.pricePence, 249);
  });

  test('unused introductory passes are available', () {
    expect(
      UagPremiumPassEntitlement.none.canPurchase(UagPremiumPassType.day24),
      isTrue,
    );
    expect(
      UagPremiumPassEntitlement.none.canPurchase(UagPremiumPassType.week7),
      isTrue,
    );
  });
}
