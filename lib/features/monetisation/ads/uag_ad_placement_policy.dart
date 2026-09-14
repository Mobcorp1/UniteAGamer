import '../models/uag_ad_policy.dart';

/// Route permissions only: SDK readiness, consent and runtime switches still apply.
/// Unnamed dialogs, new routes and critical flows deliberately fail closed.
class UagAdPlacementPolicy {
  const UagAdPlacementPolicy._();

  /// Internal builds use test inventory. Release requests require the real
  /// consent flow, including its permission to request personalised or limited ads.
  static bool permitsAdRequests({
    required bool isReleaseBuild,
    required bool hasCompletedConsentFlow,
    required bool canRequestAds,
  }) => !isReleaseBuild || (hasCompletedConsentFlow && canRequestAds);

  static const bannerRoutes = <String>{
    '/trading-hub/arc-raiders',
    '/my-hub',
    '/trading-hub/arc-raiders/my-hub',
    '/trading-hub/arc-raiders/command-centre',
    '/trading-hub/arc-raiders/blueprints',
    '/trading-hub/arc-raiders/scrappy',
    '/trading-hub/arc-raiders/bench',
    '/trading-hub/arc-raiders/quests',
    '/trading-hub/arc-raiders/progress-trackers',
    '/trading-hub/arc-raiders/nomadic-trader',
    '/trading-hub/arc-raiders/intel-explorer',
    '/trading-hub/arc-raiders/market',
    '/trading-hub/arc-raiders/future-hub',
    '/trading-hub/arc-raiders/play-like-a-pro',
    '/trading-hub/arc-raiders/wall-of-legends',
  };

  static bool permitsBanner(String? route) => bannerRoutes.contains(route);

  // A navigation observer cannot distinguish browsing from an unfinished task.
  // Full-screen inventory needs an explicit, reviewed completion placement.
  static bool permitsInterstitial(String? route) => false;
  static bool permitsAppOpen(String? route) => false;

  static String? bannerPlacementId(String? route) =>
      permitsBanner(route) ? 'arc${route!.replaceAll('/', '_')}_banner' : null;

  static bool canShowBanner(String? route, UagAdPolicy policy) =>
      policy.showBannerAds && permitsBanner(route);
}
