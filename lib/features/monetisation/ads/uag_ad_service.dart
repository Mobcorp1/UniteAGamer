import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/uag_ad_policy.dart';
import '../services/uag_entitlement_service.dart';
import 'uag_ad_runtime_settings.dart';
import 'uag_admob_config.dart';

class UagAdService extends ChangeNotifier with WidgetsBindingObserver {
  UagAdService._();

  static final UagAdService instance = UagAdService._();

  static const Duration _appOpenMaxAge = Duration(hours: 4);
  static const Duration _coldStartWindow = Duration(seconds: 5);
  static const String _sessionCountKey = 'uag_ad_session_count_v1';

  final UagEntitlementService _entitlements = UagEntitlementService();
  final UagAdSettingsRepository _settingsRepository = UagAdSettingsRepository();

  StreamSubscription<User?>? _authSub;
  StreamSubscription? _entitlementSub;
  StreamSubscription<UagAdRuntimeSettings>? _settingsSub;

  UagAdRuntimeSettings _settings = UagAdRuntimeSettings.defaults;
  UagAdPolicy _policy = UagAdPolicy.free;
  bool _signedIn = false;
  bool _initialised = false;
  bool _fullScreenShowing = false;
  bool _pausedSinceLastResume = false;
  int _sessionCount = 0;
  int _eligibleTransitions = 0;
  String? _currentRoute;
  DateTime? _initialisedAt;
  DateTime? _lastInterstitialShownAt;
  DateTime? _lastAppOpenShownAt;

  AppOpenAd? _appOpenAd;
  DateTime? _appOpenLoadedAt;
  bool _appOpenLoading = false;
  InterstitialAd? _interstitialAd;
  bool _interstitialLoading = false;

  UagAdRuntimeSettings get settings => _settings;
  UagAdPolicy get policy => _policy;
  bool get initialised => _initialised;
  bool get signedIn => _signedIn;
  String? get currentRoute => _currentRoute;

  bool get canShowBanner =>
      _initialised &&
      _signedIn &&
      _settings.adsEnabled &&
      _settings.bannerEnabled &&
      _policy.showBannerAds &&
      !_routeBlocksAds(_currentRoute);

  Future<void> initialise() async {
    if (_initialised || kIsWeb || !UagAdMobConfig.isAndroid) return;
    _initialised = true;
    _initialisedAt = DateTime.now();
    WidgetsBinding.instance.addObserver(this);

    final prefs = await SharedPreferences.getInstance();
    _sessionCount = (prefs.getInt(_sessionCountKey) ?? 0) + 1;
    await prefs.setInt(_sessionCountKey, _sessionCount);

    await MobileAds.instance.initialize();
    _listenSettings();
    _listenAuth();
    notifyListeners();
  }

  void _listenSettings() {
    _settingsSub?.cancel();
    _settingsSub = _settingsRepository.watch().listen(
      (value) {
        _settings = value;
        _disposeAdsThatAreNoLongerEligible();
        _preloadEligibleFullScreenAds();
        notifyListeners();
      },
      onError: (_) {
        _settings = UagAdRuntimeSettings.defaults;
        _preloadEligibleFullScreenAds();
        notifyListeners();
      },
    );
  }

  void _listenAuth() {
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _signedIn = user != null;
      _entitlementSub?.cancel();
      _entitlementSub = null;
      if (user == null) {
        _policy = UagAdPolicy.free;
        _disposeFullScreenAds();
        notifyListeners();
        return;
      }
      _entitlementSub = _entitlements.watchMyEntitlement().listen(
        (entitlement) {
          _policy = entitlement.hasAdminBypass
              ? UagAdPolicy.premium
              : entitlement.adPolicy;
          _disposeAdsThatAreNoLongerEligible();
          _preloadEligibleFullScreenAds();
          notifyListeners();
        },
        onError: (_) {
          _policy = UagAdPolicy.free;
          _preloadEligibleFullScreenAds();
          notifyListeners();
        },
      );
    });
  }

  void onRouteChanged(String? routeName) {
    _currentRoute = routeName;
    notifyListeners();
  }

  void recordMeaningfulNavigation(String? routeName) {
    _currentRoute = routeName;
    if (!_canUseInterstitials || _routeBlocksAds(routeName)) {
      notifyListeners();
      return;
    }
    _eligibleTransitions += 1;
    if (_eligibleTransitions >= _settings.interstitialEveryTransitions) {
      unawaited(_showInterstitialIfReady());
    }
    notifyListeners();
  }

  bool get _canUseInterstitials =>
      _initialised &&
      _signedIn &&
      _settings.adsEnabled &&
      _settings.interstitialEnabled &&
      _policy.showInterstitialAds;

  bool get _canUseAppOpen =>
      _initialised &&
      _signedIn &&
      _settings.adsEnabled &&
      _settings.appOpenEnabled &&
      _policy.showAppOpenAds &&
      _sessionCount >= _settings.minimumSessionsBeforeAppOpen;

  void _preloadEligibleFullScreenAds() {
    if (_canUseAppOpen) _loadAppOpen();
    if (_canUseInterstitials) _loadInterstitial();
  }

  void _loadInterstitial() {
    if (_interstitialAd != null ||
        _interstitialLoading ||
        !_canUseInterstitials) {
      return;
    }
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: UagAdMobConfig.interstitialAdUnitId(
        productionAdsEnabled: _settings.productionAdsEnabled,
        forceTestAds: _settings.forceTestAds,
      ),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialLoading = false;
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (_) {
          _interstitialLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<void> _showInterstitialIfReady() async {
    if (!_canUseInterstitials || _fullScreenShowing) return;
    if (_routeBlocksAds(_currentRoute)) return;
    final last = _lastInterstitialShownAt;
    if (last != null &&
        DateTime.now().difference(last).inSeconds <
            _settings.interstitialCooldownSeconds) {
      return;
    }
    final ad = _interstitialAd;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitialAd = null;
    _fullScreenShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        _fullScreenShowing = false;
        _lastInterstitialShownAt = DateTime.now();
        _eligibleTransitions = 0;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (shownAd, _) {
        shownAd.dispose();
        _fullScreenShowing = false;
        _loadInterstitial();
      },
    );
    ad.show();
  }

  void _loadAppOpen() {
    if (_appOpenAd != null || _appOpenLoading || !_canUseAppOpen) return;
    _appOpenLoading = true;
    AppOpenAd.load(
      adUnitId: UagAdMobConfig.appOpenAdUnitId(
        productionAdsEnabled: _settings.productionAdsEnabled,
        forceTestAds: _settings.forceTestAds,
      ),
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenLoading = false;
          _appOpenAd = ad;
          _appOpenLoadedAt = DateTime.now();
          if (_isInsideColdStartWindow && !_routeIsMainContent(_currentRoute)) {
            unawaited(_showAppOpenIfReady());
          }
        },
        onAdFailedToLoad: (_) {
          _appOpenLoading = false;
          _appOpenAd = null;
          _appOpenLoadedAt = null;
        },
      ),
    );
  }

  bool get _isInsideColdStartWindow {
    final start = _initialisedAt;
    return start != null &&
        DateTime.now().difference(start) <= _coldStartWindow;
  }

  Future<void> _showAppOpenIfReady() async {
    if (!_canUseAppOpen || _fullScreenShowing) return;
    final last = _lastAppOpenShownAt;
    if (last != null &&
        DateTime.now().difference(last).inMinutes <
            _settings.appOpenForegroundCooldownMinutes) {
      return;
    }
    final loadedAt = _appOpenLoadedAt;
    if (loadedAt == null ||
        DateTime.now().difference(loadedAt) > _appOpenMaxAge) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _appOpenLoadedAt = null;
      _loadAppOpen();
      return;
    }
    final ad = _appOpenAd;
    if (ad == null) {
      _loadAppOpen();
      return;
    }
    _appOpenAd = null;
    _appOpenLoadedAt = null;
    _fullScreenShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        _fullScreenShowing = false;
        _lastAppOpenShownAt = DateTime.now();
        _loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (shownAd, _) {
        shownAd.dispose();
        _fullScreenShowing = false;
        _loadAppOpen();
      },
    );
    ad.show();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedSinceLastResume = true;
      return;
    }
    if (state == AppLifecycleState.resumed && _pausedSinceLastResume) {
      _pausedSinceLastResume = false;
      unawaited(_showAppOpenIfReady());
    }
  }

  bool _routeBlocksAds(String? routeName) {
    final route = (routeName ?? '').toLowerCase();
    if (route.isEmpty || route == '/') return false;
    const blockedFragments = <String>[
      'auth',
      'login',
      'register',
      'onboarding',
      'consent',
      'terms',
      'privacy',
      'legal',
      'contract',
      'monetisation',
      'subscription',
      'checkout',
      'payment',
      'profile-setup',
      'availability',
      'camera',
      'scanner',
      'create-listing',
      'feedback',
      'admin',
      'report',
    ];
    return blockedFragments.any(route.contains);
  }

  bool _routeIsMainContent(String? routeName) {
    final route = (routeName ?? '').toLowerCase();
    if (route.isEmpty || route == '/') return false;
    return !_routeBlocksAds(routeName) && !route.contains('entry');
  }

  void _disposeAdsThatAreNoLongerEligible() {
    if (!_canUseInterstitials) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
    }
    if (!_canUseAppOpen) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _appOpenLoadedAt = null;
    }
  }

  void _disposeFullScreenAds() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _appOpenLoadedAt = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    _entitlementSub?.cancel();
    _settingsSub?.cancel();
    _disposeFullScreenAds();
    super.dispose();
  }
}

class UagAdNavigationObserver extends NavigatorObserver {
  UagAdNavigationObserver._();

  static final UagAdNavigationObserver instance = UagAdNavigationObserver._();

  String? _name(Route<dynamic>? route) => route?.settings.name;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    UagAdService.instance.recordMeaningfulNavigation(_name(route));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    UagAdService.instance.onRouteChanged(_name(previousRoute));
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    UagAdService.instance.onRouteChanged(_name(newRoute));
  }
}
