# Pass 78 - AdMob Tactical Banner Foundation

## AdMob IDs

- Android App ID: ca-app-pub-2994575443987525~1687376946
- Production Banner Ad Unit ID: ca-app-pub-2994575443987525/8387986436
- Development Test Banner Ad Unit ID: ca-app-pub-3940256099942544/6300978111

## Safety

The app stores the production IDs, but UagAdMobConfig.useProductionAds is currently alse.
Local builds will request Google test banner ads until production ads are deliberately enabled.

## Created

- lib/features/monetisation/ads/uag_admob_config.dart
- lib/features/monetisation/ads/uag_tactical_banner_ad.dart

## Updated

- pubspec.yaml
- pubspec.lock
- ndroid/app/src/main/AndroidManifest.xml
- lib/main.dart

## Next pass

Integrate UagTacticalBannerAd into the shared ARC shell with free/premium gating and dock-aware spacing.