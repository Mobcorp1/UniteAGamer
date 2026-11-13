import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_ad_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_tier.dart';

void main() {
  test('free tier receives all standard ad formats', () {
    final policy = UagAdPolicy.forTier(UagSubscriptionTier.free);
    expect(policy.showBannerAds, isTrue);
    expect(policy.showInterstitialAds, isTrue);
    expect(policy.showAppOpenAds, isTrue);
  });

  test('essential receives banner only', () {
    final policy = UagAdPolicy.forTier(UagSubscriptionTier.essential);
    expect(policy.showBannerAds, isTrue);
    expect(policy.showInterstitialAds, isFalse);
    expect(policy.showAppOpenAds, isFalse);
  });

  test('premium is completely ad free', () {
    final policy = UagAdPolicy.forTier(UagSubscriptionTier.premium);
    expect(policy.hasAnyAds, isFalse);
  });
}
