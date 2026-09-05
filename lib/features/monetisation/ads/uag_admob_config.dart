import 'package:flutter/foundation.dart';

class UagAdMobConfig {
  const UagAdMobConfig._();

  static const String androidAppId = 'ca-app-pub-2994575443987525~1687376946';

  static const String androidProductionBannerAdUnitId =
      'ca-app-pub-2994575443987525/8387986436';
  static const String androidProductionAppOpenAdUnitId =
      'ca-app-pub-2994575443987525/2869619147';
  static const String androidProductionInterstitialAdUnitId =
      'ca-app-pub-2994575443987525/8892102017';

  static const String androidTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String androidTestAppOpenAdUnitId =
      'ca-app-pub-3940256099942544/9257395921';
  static const String androidTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Production inventory is available only to an Android RELEASE build and
  /// only when the remote admin switch explicitly enables it.
  static bool useProductionInventory({
    required bool productionAdsEnabled,
    required bool forceTestAds,
  }) => isAndroid && kReleaseMode && productionAdsEnabled && !forceTestAds;

  static String bannerAdUnitId({
    required bool productionAdsEnabled,
    required bool forceTestAds,
  }) =>
      useProductionInventory(
        productionAdsEnabled: productionAdsEnabled,
        forceTestAds: forceTestAds,
      )
      ? androidProductionBannerAdUnitId
      : androidTestBannerAdUnitId;

  static String appOpenAdUnitId({
    required bool productionAdsEnabled,
    required bool forceTestAds,
  }) =>
      useProductionInventory(
        productionAdsEnabled: productionAdsEnabled,
        forceTestAds: forceTestAds,
      )
      ? androidProductionAppOpenAdUnitId
      : androidTestAppOpenAdUnitId;

  static String interstitialAdUnitId({
    required bool productionAdsEnabled,
    required bool forceTestAds,
  }) =>
      useProductionInventory(
        productionAdsEnabled: productionAdsEnabled,
        forceTestAds: forceTestAds,
      )
      ? androidProductionInterstitialAdUnitId
      : androidTestInterstitialAdUnitId;
}
