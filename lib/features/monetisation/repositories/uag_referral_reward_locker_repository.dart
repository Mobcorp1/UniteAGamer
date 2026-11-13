import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/uag_referral_reward_locker_models.dart';

class UagReferralRewardLockerRepository {
  UagReferralRewardLockerRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _lockerState(String uid) =>
      _firestore.collection('uag_referral_reward_lockers').doc(uid);

  CollectionReference<Map<String, dynamic>> _locker(String uid) =>
      _lockerState(uid).collection('rewards');

  Stream<List<UagReferralBankedReward>> watchMyLocker() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(const <UagReferralBankedReward>[]);
    }
    return _locker(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => UagReferralBankedReward.fromMap(<String, dynamic>{
                  ...doc.data(),
                  'id': doc.id,
                }),
              )
              .toList(growable: false),
        );
  }

  Future<void> bankReward({
    required String uid,
    required String rewardId,
    required UagReferralBankedRewardType type,
    required String sourceRef,
  }) async {
    final actor = _auth.currentUser;
    if (actor == null) {
      throw StateError('Sign in to award referral rewards.');
    }

    final ref = _locker(uid).doc(rewardId);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (existing.exists) return;
      transaction.set(ref, <String, dynamic>{
        'id': rewardId,
        'uid': uid,
        'type': type.name,
        'status': UagReferralRewardStatus.banked.name,
        'source': 'community_referral',
        'sourceRef': sourceRef,
        'earnedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'awardedByUid': actor.uid,
      });
    });
  }

  Future<void> activateReward({
    required String rewardId,
    required bool underlyingPremiumActive,
  }) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Sign in to activate referral rewards.');
    if (underlyingPremiumActive) {
      throw StateError(
        'Premium is already active. Keep this reward banked and use it later.',
      );
    }

    final requestId = '${uid}_$rewardId';
    final requestRef = _firestore
        .collection('uag_referral_reward_activation_requests')
        .doc(requestId);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(requestRef);
      if (existing.exists) {
        final status = existing.data()?['status']?.toString() ?? '';
        if (status == 'completed') return;
        if (status == 'pending') return;
      }
      transaction.set(requestRef, <String, dynamic>{
        'id': requestId,
        'uid': uid,
        'rewardId': rewardId,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Stream<Map<String, dynamic>> watchActivationRequest(String rewardId) {
    final uid = currentUid;
    if (uid == null) return Stream.value(const <String, dynamic>{});
    return _firestore
        .collection('uag_referral_reward_activation_requests')
        .doc('${uid}_$rewardId')
        .snapshots()
        .map((snapshot) => snapshot.data() ?? const <String, dynamic>{});
  }

  Future<void> sweepExpiredRewards() async {
    // Expiry is authoritative server-side. This remains intentionally a no-op
    // on the client so users cannot mutate reward lifecycle state themselves.
  }
}
