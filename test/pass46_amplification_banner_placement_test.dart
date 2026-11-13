import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_ad_placement_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_ad_policy.dart';

void main() {
  test('Amplification has an explicit banner placement but no full-screen ads', () {
    const route = '/trading-hub/arc-raiders/amplification';
    expect(UagAdPlacementPolicy.permitsBanner(route), isTrue);
    expect(UagAdPlacementPolicy.bannerPlacementId(route), isNotNull);
    expect(UagAdPlacementPolicy.permitsInterstitial(route), isFalse);
    expect(UagAdPlacementPolicy.permitsAppOpen(route), isFalse);
  });
  test('Unnamed and unknown routes stay blocked', () {
    expect(UagAdPlacementPolicy.permitsBanner(null), isFalse);
    expect(UagAdPlacementPolicy.permitsBanner(''), isFalse);
    expect(UagAdPlacementPolicy.permitsBanner('/unapproved'), isFalse);
  });
  test('Amplification policy still respects ad-free entitlements', () {
    const route = '/trading-hub/arc-raiders/amplification';
    expect(UagAdPlacementPolicy.canShowBanner(route, UagAdPolicy.premium), isFalse);
    expect(UagAdPlacementPolicy.canShowBanner(route, UagAdPolicy.free), isTrue);
  });
  test('Consent requirements remain active for release builds', () {
    expect(UagAdPlacementPolicy.permitsAdRequests(
      isReleaseBuild: true,
      hasCompletedConsentFlow: false,
      canRequestAds: false,
    ), isFalse);
    expect(UagAdPlacementPolicy.permitsAdRequests(
      isReleaseBuild: true,
      hasCompletedConsentFlow: true,
      canRequestAds: false,
    ), isFalse);
  });
}
