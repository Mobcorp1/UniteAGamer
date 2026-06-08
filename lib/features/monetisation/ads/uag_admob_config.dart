import 'dart:io' show Platform;

class UagAdMobConfig {
  const UagAdMobConfig._();

  // Keep this false for all local development and emulator/device testing.
  // Flip to true only for a signed production release after GDPR consent is wired.
  static const bool useProductionAds = false;
  static const bool adsEnabled = true;

  static const String androidAppId = 'ca-app-pub-2994575443987525~1687376946';
  static const String androidProductionBannerAdUnitId =
      'ca-app-pub-2994575443987525/8387986436';

  static const String androidTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  static String get bannerAdUnitId {
    if (!Platform.isAndroid) return androidTestBannerAdUnitId;
    return useProductionAds
        ? androidProductionBannerAdUnitId
        : androidTestBannerAdUnitId;
  }
}
