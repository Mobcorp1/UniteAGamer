import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

class UagOperationActionRewardException implements Exception {
  const UagOperationActionRewardException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UagOperationCompletionState {
  const UagOperationCompletionState({
    this.completed = 0,
    this.total = 4,
    this.redeemed = false,
    this.redeemedAction,
  });

  final int completed;
  final int total;
  final bool redeemed;
  final String? redeemedAction;

  bool get ready => completed >= total && !redeemed;
}

enum UagOperationCompletionTarget {
  trade,
  matchRaider,
  raidIntelligence,
  raidPlanner;

  String get usageKey => switch (this) {
    UagOperationCompletionTarget.trade => 'trades',
    UagOperationCompletionTarget.matchRaider => 'matchmakingSearches',
    UagOperationCompletionTarget.raidIntelligence => 'premiumIntelUnlocks',
    UagOperationCompletionTarget.raidPlanner => 'raidCompanionPresets',
  };

  String get label => switch (this) {
    UagOperationCompletionTarget.trade => '+1 Trade',
    UagOperationCompletionTarget.matchRaider => '+1 Match',
    UagOperationCompletionTarget.raidIntelligence => '+1 Intel',
    UagOperationCompletionTarget.raidPlanner => '+1 Raid Run',
  };
}

class UagOperationActionRewardService {
  UagOperationActionRewardService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const monthlyRewardOperationIds = <String>{
    'monthly_trader_bronze',
    'monthly_match_raider',
    'monthly_intel_network',
    'monthly_raid_runner',
  };

  static const _targets = <String, int>{
    'monthly_trader_bronze': 5,
    'monthly_match_raider': 3,
    'monthly_intel_network': 5,
    'monthly_raid_runner': 3,
  };

  bool isCommercialRewardOperation(String operationId) =>
      monthlyRewardOperationIds.contains(operationId);

  Stream<UagOperationCompletionState> watchCurrentMonthCompletion() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(const UagOperationCompletionState());
    }
    final periodKey = _currentMonthKey();
    return _firestore
        .collection('arc_operation_progress')
        .doc(uid)
        .collection('operations')
        .snapshots()
        .map((snapshot) {
          var completed = 0;
          var redeemed = false;
          String? redeemedAction;
          for (final doc in snapshot.docs) {
            final target = _targets[doc.id];
            if (target == null) continue;
            final data = doc.data();
            if (data['periodKey']?.toString() != periodKey) continue;
            final progress = (data['progress'] as num?)?.toInt() ?? 0;
            if (progress >= target) completed++;
            if (data['completionRewardClaimed'] == true) {
              redeemed = true;
              redeemedAction = data['completionRewardAction']?.toString();
            }
          }
          return UagOperationCompletionState(
            completed: completed,
            redeemed: redeemed,
            redeemedAction: redeemedAction,
          );
        });
  }

  Future<void> claim(String operationId) async {
    if (!isCommercialRewardOperation(operationId)) return;
    await _post(
      endpoint: 'redeemUagOperationActionReward',
      body: <String, dynamic>{'operationId': operationId},
    );
  }

  Future<void> redeemCompletion(UagOperationCompletionTarget target) async {
    await _post(
      endpoint: 'redeemUagOperationCompletionReward',
      body: <String, dynamic>{'action': target.usageKey},
    );
  }

  Future<void> _post({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const UagOperationActionRewardException(
        'Sign in to claim this Operation reward.',
      );
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw const UagOperationActionRewardException(
        'Sign in again to claim this Operation reward.',
      );
    }

    final project = Firebase.app().options.projectId;
    final response = await http
        .post(
          Uri.https('us-central1-$project.cloudfunctions.net', '/$endpoint'),
          headers: <String, String>{
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
      throw const UagOperationActionRewardException(
        'Operation rewards are temporarily unavailable. Try again.',
      );
    }
    if (response.statusCode != 200) {
      throw UagOperationActionRewardException(
        result['error']?.toString() ?? 'Operation reward request failed.',
      );
    }
    if (_auth.currentUser?.uid != user.uid) {
      throw const UagOperationActionRewardException(
        'Account changed. Open Operations again before claiming.',
      );
    }
  }

  String _currentMonthKey() {
    final now = DateTime.now().toUtc();
    return '${now.year}-M${now.month.toString().padLeft(2, '0')}';
  }
}
