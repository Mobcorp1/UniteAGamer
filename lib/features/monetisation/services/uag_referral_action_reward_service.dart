import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class UagReferralActionRewardException implements Exception {
  const UagReferralActionRewardException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UagReferralActionRewardState {
  const UagReferralActionRewardState({
    this.freeQualifiedCount = 0,
    this.paidQualifiedCount = 0,
    this.earnedTokens = 0,
    this.redeemedTokens = 0,
    this.availableTokens = 0,
  });

  final int freeQualifiedCount;
  final int paidQualifiedCount;
  final int earnedTokens;
  final int redeemedTokens;
  final int availableTokens;

  int get freeProgress => freeQualifiedCount % 10;
  int get paidProgress => paidQualifiedCount % 5;

  factory UagReferralActionRewardState.fromMap(Map<String, dynamic> data) {
    int number(String key) => (data[key] as num?)?.toInt() ?? 0;
    return UagReferralActionRewardState(
      freeQualifiedCount: number('freeQualifiedCount'),
      paidQualifiedCount: number('paidQualifiedCount'),
      earnedTokens: number('earnedTokens'),
      redeemedTokens: number('redeemedTokens'),
      availableTokens: number('availableTokens'),
    );
  }
}

enum UagReferralActionRewardTarget {
  trade,
  raidPlannerRun;

  String get usageKey => switch (this) {
    UagReferralActionRewardTarget.trade => 'trades',
    UagReferralActionRewardTarget.raidPlannerRun => 'raidCompanionPresets',
  };

  String get label => switch (this) {
    UagReferralActionRewardTarget.trade => '+1 Trade Action',
    UagReferralActionRewardTarget.raidPlannerRun => '+1 Raid Planner Run',
  };
}

class UagReferralActionRewardService {
  UagReferralActionRewardService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String? get uid => _auth.currentUser?.uid;

  Stream<UagReferralActionRewardState> watchCurrentMonth() {
    final currentUid = uid;
    if (currentUid == null) {
      return Stream.value(const UagReferralActionRewardState());
    }
    return _firestore
        .collection('uag_referral_action_rewards')
        .doc(currentUid)
        .collection('months')
        .doc(_currentMonthKey())
        .snapshots()
        .map(
          (snapshot) => UagReferralActionRewardState.fromMap(
            snapshot.data() ?? const <String, dynamic>{},
          ),
        );
  }

  Future<void> redeem(
    UagReferralActionRewardTarget target, {
    required String requestId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const UagReferralActionRewardException(
        'Sign in to use referral rewards.',
      );
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw const UagReferralActionRewardException(
        'Sign in again to use referral rewards.',
      );
    }
    final project = Firebase.app().options.projectId;
    final response = await http
        .post(
          Uri.https(
            'us-central1-$project.cloudfunctions.net',
            '/redeemUagReferralActionReward',
          ),
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, dynamic>{
            'action': target.usageKey,
            'requestId': requestId,
          }),
        )
        .timeout(const Duration(seconds: 30));

    Map<String, dynamic> result;
    try {
      result = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw const UagReferralActionRewardException(
        'Referral rewards are temporarily unavailable. Try again.',
      );
    }
    if (response.statusCode != 200) {
      throw UagReferralActionRewardException(
        result['error']?.toString() ?? 'Referral reward request failed.',
      );
    }
    if (uid != user.uid) {
      throw const UagReferralActionRewardException(
        'Account changed. Open referral rewards again.',
      );
    }
  }

  static String newRequestId() => const Uuid().v4().replaceAll('-', '');

  String _currentMonthKey() {
    final now = DateTime.now().toUtc();
    return '${now.year}-M${now.month.toString().padLeft(2, '0')}';
  }
}
