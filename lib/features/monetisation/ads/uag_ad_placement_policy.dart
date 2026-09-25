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
  // Automatic navigation interruption therefore remains disabled.
  static bool permitsInterstitial(String? route) => false;
  static bool permitsAppOpen(String? route) => false;

  static const String blueprintImportCompleted = 'blueprint_import_completed';
  static const String favouriteLoadoutSaved = 'favourite_loadout_saved';

  static const Map<String, String> naturalBreakInterstitialRoutes =
      <String, String>{
        blueprintImportCompleted: '/trading-hub/arc-raiders/blueprints',
        favouriteLoadoutSaved: '/favourite-loadout',
      };

  static bool hasNaturalBreakPlacementForRoute(String? route) =>
      naturalBreakInterstitialRoutes.values.contains(route);

  static bool permitsNaturalBreakInterstitial(
    String placementId,
    String? route,
  ) => naturalBreakInterstitialRoutes[placementId] == route;

  static String? bannerPlacementId(String? route) =>
      permitsBanner(route) ? 'arc${route!.replaceAll('/', '_')}_banner' : null;

  static bool canShowBanner(String? route, UagAdPolicy policy) =>
      policy.showBannerAds && permitsBanner(route);
}
