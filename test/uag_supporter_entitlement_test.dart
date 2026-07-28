import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_ad_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_plan.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_tier.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_supporter_entitlement.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_user_entitlement.dart';

void main() {
  group('supporter programme', () {
    test('default founding supporter config stays in approved price range', () {
      const config = UagSupporterProgrammeConfig.defaultConfig;

      expect(config.monthlyPricePence, 399);
      expect(config.priceIsWithinApprovedRange, isTrue);
      expect(config.futureDiscount.minimumPercent, 10);
      expect(config.futureDiscount.recommendedPercent, 15);
      expect(config.futureDiscount.maximumPercent, 20);
      expect(config.futureDiscount.requiresCommercialApproval, isTrue);
    });

    test(
      'supporter can combine with free without unlocking premium limits',
      () {
        final entitlement = UagUserEntitlement.fromUserDoc(
          uid: 'user-1',
          data: const <String, dynamic>{
            'subscriptionTier': 'free',
            'supporter': {
              'active': true,
              'foundingSupporter': true,
              'status': 'active',
              'monthlyPricePence': 399,
              'discountPercent': 15,
            },
          },
        );

        expect(entitlement.hasSupporter, isTrue);
        expect(entitlement.hasFoundingSupporter, isTrue);
        expect(entitlement.futureSupporterDiscountPercent, 15);
        expect(entitlement.isPremiumLike, isFalse);
        expect(entitlement.tier, UagSubscriptionTier.free);
      },
    );

    test('essential is ad-free and premium price is aligned', () {
      expect(UagAdPolicy.essential.hasAnyAds, isFalse);
      expect(
        UagSubscriptionPlan.forTier(UagSubscriptionTier.essential).adsLabel,
        'No ads',
      );
      expect(
        UagSubscriptionPlan.forTier(
          UagSubscriptionTier.premium,
        ).monthlyPricePence,
        799,
      );
    });
  });
}
