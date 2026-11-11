import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_ad_runtime_settings.dart';

void main() {
  test('numeric legacy flags cannot crash ad settings rendering', () {
    final settings = UagAdRuntimeSettings.fromMap(const <String, dynamic>{
      'adsEnabled': 0.0,
      'bannerEnabled': 1.0,
      'interstitialEnabled': 0.5,
      'forceTestAds': 0.0,
    });
    expect(settings.adsEnabled, UagAdRuntimeSettings.defaults.adsEnabled);
    expect(settings.bannerEnabled, UagAdRuntimeSettings.defaults.bannerEnabled);
    expect(settings.interstitialEnabled, UagAdRuntimeSettings.defaults.interstitialEnabled);
    expect(settings.forceTestAds, UagAdRuntimeSettings.defaults.forceTestAds);
  });
}
