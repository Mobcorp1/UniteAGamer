import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/uag_raider_mark_policy.dart';

class UagRewardException implements Exception {
  const UagRewardException(this.message);
  final String message;
  @override
  String toString() => message;
}

class UagRaiderMarkWallet {
  const UagRaiderMarkWallet({
    this.balance = 0,
    this.adsToday = 0,
    this.adsThisMonth = 0,
    this.redemptionsThisMonth = 0,
    this.lastVerifiedAt,
  });
  final int balance;
  final int adsToday;
  final int adsThisMonth;
  final int redemptionsThisMonth;
  final DateTime? lastVerifiedAt;
  factory UagRaiderMarkWallet.fromMap(Map<String, dynamic> data) {
    final now = DateTime.now().toUtc();
    final day = now.toIso8601String().substring(0, 10);
    final month = now.toIso8601String().substring(0, 7);
    int number(String key) => (data[key] as num?)?.toInt() ?? 0;
    final last = data['lastVerifiedAt'];
    return UagRaiderMarkWallet(
      balance: number('balance'),
      adsToday: data['day'] == day ? number('adsToday') : 0,
      adsThisMonth: data['month'] == month ? number('adsThisMonth') : 0,
      redemptionsThisMonth: data['month'] == month
          ? number('redemptionsThisMonth')
          : 0,
      lastVerifiedAt: last is num && last > 0
          ? DateTime.fromMillisecondsSinceEpoch(last.toInt(), isUtc: true)
          : null,
    );
  }
}

class UagRaiderMarkService {
  UagRaiderMarkService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  String? get uid => _auth.currentUser?.uid;
  Stream<UagRaiderMarkWallet> watchWallet() {
    final current = uid;
    if (current == null) {
      return Stream.value(const UagRaiderMarkWallet());
    }
    return _firestore
        .collection('uag_reward_wallets')
        .doc(current)
        .snapshots()
        .map((s) => UagRaiderMarkWallet.fromMap(s.data() ?? {}));
  }

  Future<Map<String, dynamic>> prepare() => _post('prepareUagRewardedAd', {
    'placement': 'arc_free_intel_refresh',
    'inventory': 'live',
  });
  Future<void> cancel(String sessionId) async {
    await _post('cancelUagRewardedAd', {'sessionId': sessionId});
  }

  Future<bool> waitForVerification(String sessionId, String expectedUid) async {
    final snapshot = await _firestore
        .collection('uag_reward_sessions')
        .doc(sessionId)
        .snapshots()
        .firstWhere((s) => s.data()?['status'] == 'verified')
        .timeout(const Duration(seconds: 45));
    return uid == expectedUid && snapshot.data()?['uid'] == expectedUid;
  }

  // A retry reuses this ID so a lost HTTP response cannot spend marks twice.
  Future<void> redeem(
    UagRaiderMarkRedemptionTarget target,
    String requestId,
  ) async {
    await _post('redeemUagRaiderMarks', {
      'action': target.action.usageKey,
      'requestId': requestId,
    });
  }

  static String newRequestId() => const Uuid().v4().replaceAll('-', '');
  Future<Map<String, dynamic>> _post(
    String name,
    Map<String, dynamic> body,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const UagRewardException('Sign in to use rewards.');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw const UagRewardException('Sign in again to use rewards.');
    }
    final project = Firebase.app().options.projectId;
    final response = await http
        .post(
          Uri.https('us-central1-$project.cloudfunctions.net', '/$name'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    Map<String, dynamic> result;
    try {
      result = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw const UagRewardException(
        'Rewards are temporarily unavailable. Try again.',
      );
    }
    if (response.statusCode != 200) {
      throw UagRewardException(
        result['error']?.toString() ?? 'Reward request failed.',
      );
    }
    if (uid != user.uid) {
      throw const UagRewardException('Account changed. Open rewards again.');
    }
    return result;
  }
}
