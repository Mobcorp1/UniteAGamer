import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_commission_rate_policy.dart';

void main() {
  test('creator base commission follows agreed points bands', () {
    expect(UagCreatorCommissionRatePolicy.baseRatePercent(1), 7.5);
    expect(UagCreatorCommissionRatePolicy.baseRatePercent(8), 10);
    expect(UagCreatorCommissionRatePolicy.baseRatePercent(15), 12.5);
    expect(UagCreatorCommissionRatePolicy.baseRatePercent(25), 15);
    expect(UagCreatorCommissionRatePolicy.baseRatePercent(40), 17.5);
    expect(UagCreatorCommissionRatePolicy.baseRatePercent(60), 20);
    expect(UagCreatorCommissionRatePolicy.baseRatePercent(100), 20);
  });

  test('community uplift follows agreed targets and caps at 2.5', () {
    expect(UagCreatorCommissionRatePolicy.communityUpliftPercent(9999), 0);
    expect(UagCreatorCommissionRatePolicy.communityUpliftPercent(10000), .5);
    expect(UagCreatorCommissionRatePolicy.communityUpliftPercent(25000), 1);
    expect(UagCreatorCommissionRatePolicy.communityUpliftPercent(50000), 1.5);
    expect(UagCreatorCommissionRatePolicy.communityUpliftPercent(100000), 2);
    expect(UagCreatorCommissionRatePolicy.communityUpliftPercent(250000), 2.5);
    expect(UagCreatorCommissionRatePolicy.communityUpliftPercent(900000), 2.5);
  });

  test('top creator receives community uplift on entire base rate', () {
    expect(
      UagCreatorCommissionRatePolicy.effectiveRatePercent(
        points: 100,
        qualifiedActiveUsers: 250000,
      ),
      22.5,
    );
  });
}
