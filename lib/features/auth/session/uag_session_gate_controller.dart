import 'package:shared_preferences/shared_preferences.dart';

class UagSessionGateController {
  static const String _keepSignedInKey = 'uag_keep_signed_in';
  static const String _sessionAllowedUidKey = 'uag_session_allowed_uid';
  static const String _biometricEnabledKey = 'uag_biometric_login_enabled';
  static const String _biometricAllowedUidKey = 'uag_biometric_allowed_uid';

  static String? _runtimeAuthenticatedUid;
  static String? _runtimeBiometricUnlockedUid;
  static DateTime? _onboardingAuthHandshakeUntil;
  static DateTime? _lastBackgroundedAt;
  static const Duration _gracePeriod = Duration(minutes: 5);
  static const Duration _onboardingAuthHandshakeWindow = Duration(minutes: 2);

  const UagSessionGateController._();

  static void markOnboardingAuthHandshakeStarted({
    Duration window = _onboardingAuthHandshakeWindow,
  }) {
    _onboardingAuthHandshakeUntil = DateTime.now().add(window);
  }

  static void clearOnboardingAuthHandshake() {
    _onboardingAuthHandshakeUntil = null;
  }

  static Future<void> markAuthenticated({
    required String uid,
    required bool keepSignedIn,
  }) async {
    _runtimeAuthenticatedUid = uid;
    _runtimeBiometricUnlockedUid = uid;
    _onboardingAuthHandshakeUntil = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepSignedInKey, keepSignedIn);

    if (keepSignedIn) {
      await prefs.setString(_sessionAllowedUidKey, uid);

      final biometricsEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
      if (biometricsEnabled) {
        await prefs.setString(_biometricAllowedUidKey, uid);
      }
    } else {
      await prefs.remove(_sessionAllowedUidKey);
      await prefs.remove(_biometricAllowedUidKey);
    }
  }

  static Future<void> markBiometricUnlocked({required String uid}) async {
    _runtimeAuthenticatedUid = uid;
    _runtimeBiometricUnlockedUid = uid;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepSignedInKey, true);
    await prefs.setString(_sessionAllowedUidKey, uid);
    await prefs.setBool(_biometricEnabledKey, true);
    await prefs.setString(_biometricAllowedUidKey, uid);
  }

  static Future<void> setBiometricRelockEnabled({
    required bool enabled,
    String? uid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);

    if (!enabled) {
      _runtimeBiometricUnlockedUid = null;
      await prefs.remove(_biometricAllowedUidKey);
      return;
    }

    if (uid != null && uid.isNotEmpty) {
      _runtimeAuthenticatedUid = uid;
      _runtimeBiometricUnlockedUid = uid;
      await prefs.setBool(_keepSignedInKey, true);
      await prefs.setString(_sessionAllowedUidKey, uid);
      await prefs.setString(_biometricAllowedUidKey, uid);
    }
  }

  static Future<bool> isSessionAllowed(String uid) async {
    if (_runtimeAuthenticatedUid == uid) return true;
    if (_onboardingAuthHandshakeActive) return true;

    final prefs = await SharedPreferences.getInstance();
    final keepSignedIn = prefs.getBool(_keepSignedInKey) ?? false;
    final allowedUid = prefs.getString(_sessionAllowedUidKey);

    return keepSignedIn && allowedUid == uid;
  }

  static Future<bool> keepSignedInPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keepSignedInKey) ?? false;
  }

  static Future<void> markAuthenticatedWithStoredPreference({
    required String uid,
  }) async {
    final keepSignedIn = await keepSignedInPreference();
    await markAuthenticated(uid: uid, keepSignedIn: keepSignedIn);
  }

  static Future<bool> isBiometricRelockRequired(String uid) async {
    if (_runtimeBiometricUnlockedUid == uid &&
        _lastBackgroundedAt != null &&
        DateTime.now().difference(_lastBackgroundedAt!) < _gracePeriod) {
      return false;
    }
    if (_runtimeBiometricUnlockedUid == uid) return false;

    final prefs = await SharedPreferences.getInstance();
    final keepSignedIn = prefs.getBool(_keepSignedInKey) ?? false;
    final biometricsEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
    final sessionAllowedUid = prefs.getString(_sessionAllowedUidKey);
    final biometricAllowedUid = prefs.getString(_biometricAllowedUidKey);

    return keepSignedIn &&
        biometricsEnabled &&
        sessionAllowedUid == uid &&
        biometricAllowedUid == uid;
  }

  static void markAppBackgrounded() {
    _lastBackgroundedAt = DateTime.now();
  }

  static Future<void> clearSession() async {
    _runtimeAuthenticatedUid = null;
    _runtimeBiometricUnlockedUid = null;
    _onboardingAuthHandshakeUntil = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionAllowedUidKey);
    await prefs.remove(_biometricAllowedUidKey);
    await prefs.setBool(_keepSignedInKey, false);
  }

  static bool get _onboardingAuthHandshakeActive {
    final until = _onboardingAuthHandshakeUntil;
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    _onboardingAuthHandshakeUntil = null;
    return false;
  }
}
