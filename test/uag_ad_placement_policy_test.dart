import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_ad_placement_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_ad_policy.dart';

void main() {
  test('release requests require completed consent and permission', () {
    for (final completed in [false, true]) {
      for (final permitted in [false, true]) {
        expect(
          UagAdPlacementPolicy.permitsAdRequests(
            isReleaseBuild: true,
            hasCompletedConsentFlow: completed,
            canRequestAds: permitted,
          ),
          completed && permitted,
        );
        expect(
          UagAdPlacementPolicy.permitsAdRequests(
            isReleaseBuild: false,
            hasCompletedConsentFlow: completed,
            canRequestAds: permitted,
          ),
          isTrue,
        );
      }
    }
  });
  test('unknown and critical routes fail closed', () {
    for (final route in <String?>[
      null,
      '',
      '/',
      '/new-screen',
      '/trading-hub/arc-raiders/profile/setup',
      '/trading-hub/arc-raiders/create',
      '/admin',
      '/contracts',
      '/checkout',
      '/trading-hub/arc-raiders/blueprints/scan',
    ]) {
      expect(UagAdPlacementPolicy.permitsBanner(route), isFalse);
      expect(UagAdPlacementPolicy.bannerPlacementId(route), isNull);
    }
  });
  test(
    'passive banner routes preserve tier policy and never auto interrupt',
    () {
      for (final route in UagAdPlacementPolicy.bannerRoutes) {
        expect(
          UagAdPlacementPolicy.canShowBanner(route, UagAdPolicy.free),
          isTrue,
        );
        expect(
          UagAdPlacementPolicy.canShowBanner(route, UagAdPolicy.essential),
          isTrue,
        );
        expect(
          UagAdPlacementPolicy.canShowBanner(route, UagAdPolicy.premium),
          isFalse,
        );
        expect(UagAdPlacementPolicy.bannerPlacementId(route), isNotNull);
        expect(UagAdPlacementPolicy.permitsInterstitial(route), isFalse);
        expect(UagAdPlacementPolicy.permitsAppOpen(route), isFalse);
      }
    },
  );
}
