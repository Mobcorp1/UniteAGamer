import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UagCheckoutException implements Exception {
  const UagCheckoutException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UagGiftRedemptionResult {
  const UagGiftRedemptionResult({
    required this.alreadyRedeemed,
    this.expiresAt,
  });

  final bool alreadyRedeemed;
  final DateTime? expiresAt;
}

class UagCheckoutService {
  UagCheckoutService({FirebaseAuth? auth, http.Client? client})
    : _auth = auth ?? FirebaseAuth.instance,
      _client = client ?? http.Client();

  final FirebaseAuth _auth;
  final http.Client _client;

  Future<void> startCheckout({
    required String planId,
    String? referralCode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const UagCheckoutException('Sign in before starting checkout.');
    }

    final idToken = await _verifiedIdToken(user);

    final response = await _client.post(
      _functionUri('createUagCheckoutSession'),
      headers: _headers(idToken),
      body: jsonEncode(<String, dynamic>{
        'planId': planId,
        if (referralCode != null && referralCode.trim().isNotEmpty)
          'referralCode': referralCode.trim(),
        'successUrl': _returnUri(checkoutState: 'success').toString(),
        'cancelUrl': _returnUri(checkoutState: 'cancelled').toString(),
      }),
    );

    final payload = _decodePayload(response);
    _throwForFailure(
      response,
      payload,
      fallback: 'Checkout could not be started. Try again.',
    );

    final checkoutUrl = payload['checkoutUrl']?.toString().trim() ?? '';
    final uri = Uri.tryParse(checkoutUrl);
    if (uri == null || !uri.hasScheme) {
      throw const UagCheckoutException(
        'Checkout did not return a valid payment link.',
      );
    }

    final launched = await launchUrl(
      uri,
      mode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_self' : null,
    );
    if (!launched) {
      throw const UagCheckoutException('Could not open secure checkout.');
    }
  }

  Future<UagGiftRedemptionResult> redeemGift(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty) {
      throw const UagCheckoutException('Enter a UAG gift code.');
    }
    final user = _auth.currentUser;
    if (user == null) {
      throw const UagCheckoutException('Sign in before redeeming a gift.');
    }
    final idToken = await _verifiedIdToken(user);

    final response = await _client.post(
      _functionUri('redeemUagGift'),
      headers: _headers(idToken),
      body: jsonEncode(<String, dynamic>{'code': code}),
    );
    final payload = _decodePayload(response);
    _throwForFailure(
      response,
      payload,
      fallback: 'Gift could not be redeemed. Try again.',
    );

    return UagGiftRedemptionResult(
      alreadyRedeemed: payload['alreadyRedeemed'] == true,
      expiresAt: DateTime.tryParse(payload['expiresAt']?.toString() ?? ''),
    );
  }

  Future<void> openCustomerPortal() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const UagCheckoutException('Sign in before managing billing.');
    }
    final idToken = await _verifiedIdToken(user);

    final response = await _client.post(
      _functionUri('createUagCustomerPortalSession'),
      headers: _headers(idToken),
      body: jsonEncode(<String, dynamic>{'returnUrl': _returnUri().toString()}),
    );

    final payload = _decodePayload(response);
    _throwForFailure(
      response,
      payload,
      fallback: 'Subscription management could not be opened. Try again.',
    );

    final portalUrl = payload['portalUrl']?.toString().trim() ?? '';
    final uri = Uri.tryParse(portalUrl);
    if (uri == null || !uri.hasScheme) {
      throw const UagCheckoutException(
        'Billing portal did not return a valid link.',
      );
    }
    final launched = await launchUrl(
      uri,
      mode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_self' : null,
    );
    if (!launched) {
      throw const UagCheckoutException(
        'Could not open subscription management.',
      );
    }
  }

  Future<String> _verifiedIdToken(User user) async {
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const UagCheckoutException(
        'Your sign-in session could not be verified. Sign in again and retry.',
      );
    }
    return idToken;
  }

  Map<String, String> _headers(String idToken) => <String, String>{
    'Authorization': 'Bearer $idToken',
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _decodePayload(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return const <String, dynamic>{};
  }

  void _throwForFailure(
    http.Response response,
    Map<String, dynamic> payload, {
    required String fallback,
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final message = payload['error']?.toString().trim() ?? '';
    throw UagCheckoutException(message.isNotEmpty ? message : fallback);
  }

  Uri _functionUri(String functionName) {
    final projectId = Firebase.app().options.projectId;
    return Uri.parse(
      'https://us-central1-$projectId.cloudfunctions.net/$functionName',
    );
  }

  Uri _returnUri({String? checkoutState}) {
    final base = kIsWeb
        ? Uri.base
        : Uri.parse('https://unite-a-gamer.web.app/');
    final query = <String, String>{...base.queryParameters};
    if (checkoutState != null) {
      query['checkout'] = checkoutState;
    }
    return base.replace(path: '/', queryParameters: query, fragment: '');
  }
}
