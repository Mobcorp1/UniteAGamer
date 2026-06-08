import 'package:shared_preferences/shared_preferences.dart';

class UagSessionGateController {
  static const String _keepSignedInKey = 'uag_keep_signed_in';
  static const String _sessionAllowedUidKey = 'uag_session_allowed_uid';
  static const String _biometricEnabledKey = 'uag_biometric_login_enabled';
  static const String _biometricAllowedUidKey = 'uag_biometric_allowed_uid';

  static String? _runtimeAuthenticatedUid;
  static String? _runtimeBiometricUnlockedUid;

  const UagSessionGateController._();

  static Future<void> markAuthenticated({
    required String uid,
    required bool keepSignedIn,
  }) async {
    _runtimeAuthenticatedUid = uid;
    _runtimeBiometricUnlockedUid = uid;

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

    final prefs = await SharedPreferences.getInstance();
    final keepSignedIn = prefs.getBool(_keepSignedInKey) ?? false;
    final allowedUid = prefs.getString(_sessionAllowedUidKey);

    return keepSignedIn && allowedUid == uid;
  }

  static Future<bool> isBiometricRelockRequired(String uid) async {
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
    _runtimeBiometricUnlockedUid = null;
  }

  static Future<void> clearSession() async {
    _runtimeAuthenticatedUid = null;
    _runtimeBiometricUnlockedUid = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionAllowedUidKey);
    await prefs.remove(_biometricAllowedUidKey);
    await prefs.setBool(_keepSignedInKey, false);
  }
}
