import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/uag_raider_mark_service.dart';
import 'uag_ad_service.dart';
import 'uag_ad_consent_controller.dart';
import 'uag_admob_config.dart';

class UagRewardedAdService {
  UagRewardedAdService({UagRaiderMarkService? marks})
    : _marks = marks ?? UagRaiderMarkService();
  final UagRaiderMarkService _marks;

  Future<String> watchAndEarn() async {
    final ads = UagAdService.instance;
    if (!UagAdMobConfig.isAndroid) {
      throw const UagRewardException('Rewarded ads are available on Android.');
    }
    await UagAdConsentController.instance.initialise();
    if (kReleaseMode && !UagAdConsentController.instance.canRequestAds) {
      throw const UagRewardException(
        'Advertising privacy choices must be completed first.',
      );
    }
    await ads.initialise();
    if (!ads.beginRewardedPresentation()) {
      throw const UagRewardException(
        'Rewarded ads are unavailable for this account or another ad is open.',
      );
    }
    RewardedAd? ad;
    String? sessionId;
    bool earned = false;
    try {
      final settings = ads.settings;
      final live = UagAdMobConfig.useProductionInventory(
        productionAdsEnabled: settings.productionAdsEnabled,
        forceTestAds: settings.forceTestAds,
      );
      if (live && !settings.rewardedSsvReady) {
        throw const UagRewardException('Live rewards are not enabled yet.');
      }
      final currentUid = _marks.uid;
      if (currentUid == null) {
        throw const UagRewardException('Sign in to use rewards.');
      }
      final id = UagAdMobConfig.rewardedAdUnitId(
        productionAdsEnabled: settings.productionAdsEnabled,
        forceTestAds: settings.forceTestAds,
      );
      ad = await _load(id);
      if (!ads.canUseRewardedAds || _marks.uid != currentUid) {
        throw const UagRewardException(
          'Reward eligibility changed. Please try again.',
        );
      }
      if (live) {
        final session = await _marks.prepare();
        sessionId = session['sessionId'] as String?;
        if (sessionId == null || session['adUnitId'] != id) {
          throw const UagRewardException(
            'Reward session could not be started.',
          );
        }
        await ad.setServerSideOptions(
          ServerSideVerificationOptions(
            userId: currentUid,
            customData: sessionId,
          ),
        );
      }
      if (_marks.uid != currentUid || !ads.canUseRewardedAds) {
        throw const UagRewardException(
          'Reward eligibility changed. Please try again.',
        );
      }
      final dismissed = Completer<void>();
      ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
        onAdDismissedFullScreenContent: (shown) {
          unawaited(shown.dispose());
          if (!dismissed.isCompleted) {
            dismissed.complete();
          }
        },
        onAdFailedToShowFullScreenContent: (shown, error) {
          unawaited(shown.dispose());
          if (!dismissed.isCompleted) {
            dismissed.completeError(
              const UagRewardException('The ad could not be shown. Try again.'),
            );
          }
        },
      );
      // Completion is a UI signal. Only the signed server callback grants marks.
      // Listen before show() to avoid an unhandled async failure callback.
      final shownAd = ad;
      final showFuture = shownAd.show(
        onUserEarnedReward: (_, reward) {
          earned = true;
        },
      );
      await Future.wait<void>([showFuture, dismissed.future], eagerError: true);
      ad = null;
      if (!earned) {
        return 'Ad closed before completion. No Hub Credit earned.';
      }
      if (!live) {
        return 'Test ad completed. Test ads do not add Hub Credits.';
      }
      try {
        final verified = await _marks.waitForVerification(
          sessionId!,
          currentUid,
        );
        return verified
            ? '1 Hub Credit added to your wallet.'
            : 'Reward saved to the account that watched the ad.';
      } on TimeoutException {
        return 'Ad completed. Your Hub Credit will appear when verification arrives.';
      }
    } finally {
      if (ad != null) {
        await ad.dispose();
      }
      if (sessionId != null && !earned) {
        try {
          await _marks.cancel(sessionId);
        } catch (_) {
          /* Server expiry releases the reservation. */
        }
      }
      ads.endRewardedPresentation();
    }
  }

  Future<RewardedAd> _load(String unitId) async {
    final loaded = Completer<RewardedAd>();
    bool expired = false;
    unawaited(
      RewardedAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (expired) {
              unawaited(ad.dispose());
              return;
            }
            loaded.complete(ad);
          },
          onAdFailedToLoad: (_) {
            if (!expired) {
              loaded.completeError(
                const UagRewardException(
                  'No rewarded ad is available right now. Please try again later.',
                ),
              );
            }
          },
        ),
      ).catchError((Object error) {
        if (!expired && !loaded.isCompleted) {
          loaded.completeError(error);
        }
      }),
    );
    try {
      return await loaded.future.timeout(const Duration(seconds: 45));
    } finally {
      expired = true;
    }
  }
}
