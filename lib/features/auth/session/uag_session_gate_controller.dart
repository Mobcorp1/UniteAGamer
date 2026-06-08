import 'package:shared_preferences/shared_preferences.dart';

class UagSessionGateController {
  static const String _keepSignedInKey = 'uag_keep_signed_in';
  static const String _sessionAllowedUidKey = 'uag_session_allowed_uid';

  static String? _runtimeAuthenticatedUid;

  const UagSessionGateController._();

  static Future<void> markAuthenticated({
    required String uid,
    required bool keepSignedIn,
  }) async {
    _runtimeAuthenticatedUid = uid;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepSignedInKey, keepSignedIn);

    if (keepSignedIn) {
      await prefs.setString(_sessionAllowedUidKey, uid);
    } else {
      await prefs.remove(_sessionAllowedUidKey);
    }
  }

  static Future<bool> isSessionAllowed(String uid) async {
    if (_runtimeAuthenticatedUid == uid) return true;

    final prefs = await SharedPreferences.getInstance();
    final keepSignedIn = prefs.getBool(_keepSignedInKey) ?? false;
    final allowedUid = prefs.getString(_sessionAllowedUidKey);

    return keepSignedIn && allowedUid == uid;
  }

  static Future<void> clearSession() async {
    _runtimeAuthenticatedUid = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionAllowedUidKey);
    await prefs.setBool(_keepSignedInKey, false);
  }
}
