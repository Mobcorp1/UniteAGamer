import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_commercial_policy.dart';

void main() {
  test('creator points weight Essential and Premium correctly', () {
    expect(UagCreatorCommercialPolicy.pointsFor(essential: 6, premium: 4), 12);
  });

  test('commission ladder resolves all agreed boundaries', () {
    expect(UagCreatorCommercialPolicy.levelForPoints(1)?.commissionPercent, 7.5);
    expect(
      UagCreatorCommercialPolicy.levelForPoints(8)?.commissionPercent,
      10,
    );
    expect(
      UagCreatorCommercialPolicy.levelForPoints(15)?.commissionPercent,
      12.5,
    );
    expect(
      UagCreatorCommercialPolicy.levelForPoints(25)?.commissionPercent,
      15,
    );
    expect(
      UagCreatorCommercialPolicy.levelForPoints(40)?.commissionPercent,
      17.5,
    );
    expect(
      UagCreatorCommercialPolicy.levelForPoints(60)?.commissionPercent,
      20,
    );
    expect(
      UagCreatorCommercialPolicy.levelForPoints(100)?.commissionPercent,
      20,
    );
  });

  test('commission is paid on eligible net revenue', () {
    expect(
      UagCreatorCommercialPolicy.commissionPence(
        eligibleNetRevenuePence: 10000,
        creatorPoints: 25,
      ),
      1500,
    );
  });

  test('legend allocation has quarterly annual giveaway', () {
    final legend = UagCreatorCommercialPolicy.levelForPoints(100)!;
    expect(legend.allocation.premiumMonth, 4);
    expect(legend.allocation.annualPremiumPerQuarter, 1);
    expect(legend.allocation.seasonalCampaignAccess, isTrue);
  });
}
