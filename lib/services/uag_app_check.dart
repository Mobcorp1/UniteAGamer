import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Staged attestation rollout. Console enforcement remains an owner action.
class UagAppCheck {
  static const enabled = bool.fromEnvironment('UAG_APP_CHECK_ENABLED');
  static const webSiteKey = String.fromEnvironment(
    'UAG_APP_CHECK_WEB_SITE_KEY',
  );
  static bool _active = false;

  static bool supported({
    required bool web,
    required TargetPlatform platform,
  }) =>
      web ||
      platform == TargetPlatform.android ||
      platform == TargetPlatform.iOS ||
      platform == TargetPlatform.macOS;

  static Future<void> initialize() async {
    if (!enabled) return;
    if (!supported(web: kIsWeb, platform: defaultTargetPlatform) ||
        (kIsWeb && webSiteKey.isEmpty)) {
      debugPrint('App Check is not configured for this client.');
      return;
    }
    const debug = kDebugMode && bool.fromEnvironment('UAG_APP_CHECK_DEBUG');
    try {
      await FirebaseAppCheck.instance
          .activate(
            providerWeb: kIsWeb ? ReCaptchaV3Provider(webSiteKey) : null,
            providerAndroid: debug
                ? const AndroidDebugProvider()
                : const AndroidPlayIntegrityProvider(),
            providerApple: debug
                ? const AppleDebugProvider()
                : const AppleAppAttestWithDeviceCheckFallbackProvider(),
          )
          .timeout(const Duration(seconds: 10));
      _active = true;
    } catch (_) {
      // During monitoring, an attestation outage must not break account access.
      // Do not print token-bearing SDK exceptions.
      debugPrint('App Check initialization unavailable.');
    }
  }

  /// REST/callable wire-protocol clients do not attach SDK tokens themselves.
  static Future<Map<String, String>> headers() async {
    if (!_active) return const {};
    try {
      final token = await FirebaseAppCheck.instance.getToken().timeout(
        const Duration(seconds: 5),
      );
      return token == null || token.isEmpty
          ? const {}
          : {'X-Firebase-AppCheck': token};
    } catch (_) {
      debugPrint('App Check token unavailable.');
      return const {};
    }
  }
}
