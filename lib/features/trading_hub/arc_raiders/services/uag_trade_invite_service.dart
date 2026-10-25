import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// The server stores only the SHA256 digest of each opaque invitation token.
/// Never place a Firebase UID in the public URL or locally derive attribution.
class UagTradeInviteService {
  UagTradeInviteService._();

  static final UagTradeInviteService instance = UagTradeInviteService._();

  static const String _storedToken = 'uag_pass09_pending_trade_invite';
  static const String _endpoint =
      'https://us-central1-unite-a-gamer.cloudfunctions.net/uagTradeInviteGateway';

  final ValueNotifier<String?> pendingToken = ValueNotifier<String?>(null);
  bool _restored = false;

  static String? parse(Uri uri) {
    if (uri.scheme != 'https' ||
        !const <String>{
          'unite-a-gamer.web.app',
          'uniteagamer.com',
          'www.uniteagamer.com',
        }.contains(uri.host)) {
      return null;
    }
    if (uri.pathSegments.length != 2 || uri.pathSegments[0] != 't') {
      return null;
    }
    final token = uri.pathSegments[1];
    return RegExp(r'^[A-Za-z0-9_-]{28,96}$').hasMatch(token) ? token : null;
  }

  /// Display an authenticated, server-issued personal token only on our public
  /// custom domain. Keep old web.app invitations valid for existing recipients.
  /// Reject arbitrary redirect hosts, paths, query strings and malformed tokens.
  static String? canonicalShareUrl(String? rawUrl) {
    if (rawUrl == null) return null;
    final uri = Uri.tryParse(rawUrl);
    if (uri == null ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort) {
      return null;
    }
    final token = parse(uri);
    if (token == null) return null;
    return Uri(
      scheme: 'https',
      host: 'uniteagamer.com',
      pathSegments: <String>['t', token],
    ).toString();
  }

  Future<void> initialise() async {
    if (_restored) return;
    _restored = true;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storedToken);
    if (saved != null && RegExp(r'^[A-Za-z0-9_-]{28,96}$').hasMatch(saved)) {
      pendingToken.value = saved;
    }
    await captureRoute(Uri.base);
  }

  Future<void> captureRoute(Uri uri) async {
    final token = parse(uri);
    if (token == null) return;
    pendingToken.value = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storedToken, token);
  }

  Future<void> clearPending() async {
    pendingToken.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storedToken);
  }

  Future<Map<String, dynamic>> _post(
    String action, {
    String? token,
    String? programmeCode,
    String? referrerUid,
    String? code,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (action != 'resolve' && user == null) {
      throw StateError('Sign in to use your trading invitation.');
    }
    final jwt = action == 'resolve' ? null : await user!.getIdToken();
    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: <String, String>{
            'Content-Type': 'application/json',
            if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
          },
          body: jsonEncode(<String, String>{
            'action': action,
            'token': ?token,
            'programmeCode': ?programmeCode,
            'referrerUid': ?referrerUid,
            'code': ?code,
          }),
        )
        .timeout(const Duration(seconds: 18));
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw StateError('Unexpected trading response.');
    final payload = Map<String, dynamic>.from(decoded);
    if (response.statusCode != 200) {
      throw StateError(
        payload['error']?.toString() ?? 'Trading invitation unavailable.',
      );
    }
    return payload;
  }

  Future<Map<String, dynamic>> create({String? programmeCode}) =>
      _post('create', programmeCode: programmeCode);
  Future<Map<String, dynamic>> claimLegacy({
    required String referrerUid,
    required String code,
  }) => _post('legacyCapture', referrerUid: referrerUid, code: code);
  Future<Map<String, dynamic>> resolve(String token) =>
      _post('resolve', token: token);
  Future<Map<String, dynamic>> claim(String token) =>
      _post('claim', token: token);
  Future<Map<String, dynamic>> revoke(String token) =>
      _post('revoke', token: token);
}
