import 'package:flutter/foundation.dart';

/// Central consent gate for UAG advertising.
///
/// This is a production-safety layer: real ads must not be served until consent
/// handling is completed and this controller reports ads can be requested.
class UagAdConsentController extends ChangeNotifier {
  UagAdConsentController._();

  static final UagAdConsentController instance = UagAdConsentController._();

  bool _hasCompletedConsentFlow = false;
  bool _canRequestAds = false;
  bool _isInUkOrGdprRegion = true;

  bool get hasCompletedConsentFlow => _hasCompletedConsentFlow;
  bool get canRequestAds => _canRequestAds;
  bool get isInUkOrGdprRegion => _isInUkOrGdprRegion;

  /// Safe default for development builds: test ads may load, production ads must
  /// remain blocked until consent implementation is completed.
  Future<void> initialiseForDevelopment() async {
    _isInUkOrGdprRegion = true;
    _hasCompletedConsentFlow = false;
    _canRequestAds = false;
    notifyListeners();
  }

  /// Temporary manual unlock for internal testing only. Do not use for release.
  void allowTestAdsForInternalBuilds() {
    _canRequestAds = true;
    notifyListeners();
  }

  void resetConsentState() {
    _hasCompletedConsentFlow = false;
    _canRequestAds = false;
    notifyListeners();
  }
}
