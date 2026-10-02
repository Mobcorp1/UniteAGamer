import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_admob_config.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/ads/uag_ad_runtime_settings.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/services/uag_raider_mark_service.dart';

void main() {
  test('debug Android never uses production rewarded inventory', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(
      UagAdMobConfig.androidAppId,
      'ca-app-pub-2994575443987525~1687376946',
    );
    expect(
      UagAdMobConfig.androidProductionRewardedAdUnitId,
      'ca-app-pub-2994575443987525/3866328391',
    );
    expect(
      UagAdMobConfig.rewardedAdUnitId(
        productionAdsEnabled: true,
        forceTestAds: false,
      ),
      UagAdMobConfig.androidTestRewardedAdUnitId,
    );
  });
  test(
    'rewarded admin settings survive serialization without changing other ads',
    () {
      final settings = UagAdRuntimeSettings.defaults.copyWith(
        rewardedEnabled: false,
        rewardedSsvReady: true,
      );
      final roundTrip = UagAdRuntimeSettings.fromMap(settings.toMap());
      expect(roundTrip.rewardedEnabled, isFalse);
      expect(roundTrip.rewardedSsvReady, isTrue);
      expect(
        roundTrip.bannerEnabled,
        UagAdRuntimeSettings.defaults.bannerEnabled,
      );
      expect(roundTrip.forceTestAds, isTrue);
      expect(UagAdRuntimeSettings.fromMap({}).rewardedSsvReady, isFalse);
    },
  );
  test(
    'wallet rollover keeps carried marks and last completion while clearing period caps',
    () {
      final wallet = UagRaiderMarkWallet.fromMap({
        'balance': 8,
        'day': '2000-01-01',
        'month': '2000-01',
        'adsToday': 3,
        'adsThisMonth': 20,
        'redemptionsThisMonth': 4,
        'lastVerifiedAt': 1234567890000,
      });
      expect(wallet.balance, 8);
      expect(wallet.adsToday, 0);
      expect(wallet.adsThisMonth, 0);
      expect(wallet.redemptionsThisMonth, 0);
      expect(wallet.lastVerifiedAt!.millisecondsSinceEpoch, 1234567890000);
    },
  );
  test(
    'current month caps survive wallet decoding and request IDs are unique',
    () {
      final now = DateTime.now().toUtc().toIso8601String();
      final wallet = UagRaiderMarkWallet.fromMap({
        'balance': 5,
        'day': now.substring(0, 10),
        'month': now.substring(0, 7),
        'adsToday': 2,
        'adsThisMonth': 12,
        'redemptionsThisMonth': 3,
      });
      expect(wallet.adsToday, 2);
      expect(wallet.adsThisMonth, 12);
      expect(wallet.redemptionsThisMonth, 3);
      final ids = List.generate(20, (_) => UagRaiderMarkService.newRequestId());
      expect(ids.toSet().length, 20);
      expect(ids.every((id) => RegExp(r'^[a-f0-9]{32}$').hasMatch(id)), isTrue);
    },
  );
}
