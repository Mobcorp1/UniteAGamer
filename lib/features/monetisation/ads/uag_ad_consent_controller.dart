import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'uag_admob_config.dart';

/// UMP is the authority for whether an ad request is permitted.
class UagAdConsentController extends ChangeNotifier {
  UagAdConsentController._();
  static final instance = UagAdConsentController._();
  bool _hasCompletedConsentFlow = false;
  bool _canRequestAds = false;
  bool _privacyOptionsRequired = false;
  Future<void>? _inFlight;
  String? _error;

  bool get hasCompletedConsentFlow => _hasCompletedConsentFlow;
  bool get canRequestAds => _canRequestAds;
  bool get privacyOptionsRequired => _privacyOptionsRequired;
  String? get error => _error;
  // Region detection belongs to UMP; retained for existing callers.
  bool get isInUkOrGdprRegion => _privacyOptionsRequired;

  Future<void> initialise() {
    if (!UagAdMobConfig.isAndroid) {
      return Future<void>.value();
    }
    return _inFlight ??= _collect().whenComplete(() => _inFlight = null);
  }

  Future<void> _collect() async {
    final result = Completer<void>();
    _error = null;
    Future<void> finish(FormError? error) async {
      try {
        _error = error?.message;
        _canRequestAds = await ConsentInformation.instance.canRequestAds();
        _hasCompletedConsentFlow = _canRequestAds || error == null;
        _privacyOptionsRequired =
            await ConsentInformation.instance
                .getPrivacyOptionsRequirementStatus() ==
            PrivacyOptionsRequirementStatus.required;
        notifyListeners();
        if (!result.isCompleted) {
          result.complete();
        }
      } catch (error, stack) {
        if (!result.isCompleted) {
          result.completeError(error, stack);
        }
      }
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired(
        (error) => unawaited(finish(error)),
      ),
      (error) => unawaited(finish(error)),
    );
    await result.future;
  }

  Future<void> showPrivacyOptions() async {
    if (!UagAdMobConfig.isAndroid || !_privacyOptionsRequired) {
      return;
    }
    final done = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((error) async {
      try {
        _error = error?.message;
        _canRequestAds = await ConsentInformation.instance.canRequestAds();
        _hasCompletedConsentFlow = true;
        _privacyOptionsRequired =
            await ConsentInformation.instance
                .getPrivacyOptionsRequirementStatus() ==
            PrivacyOptionsRequirementStatus.required;
        notifyListeners();
        done.complete();
      } catch (error, stack) {
        done.completeError(error, stack);
      }
    });
    await done.future;
  }

  Future<void> initialiseForDevelopment() => initialise();
  void allowTestAdsForInternalBuilds() {
    if (kReleaseMode) {
      return;
    }
    _canRequestAds = true;
    notifyListeners();
  }

  void resetConsentState() {
    if (kReleaseMode) {
      return;
    }
    _hasCompletedConsentFlow = false;
    _canRequestAds = false;
    notifyListeners();
  }
}
