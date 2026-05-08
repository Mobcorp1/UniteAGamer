import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:uag_traders_hub/features/monetisation/models/uag_monetisation_models.dart';

class UagMonetisationRepository {
  UagMonetisationRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  Stream<UagEntitlement> watchMyEntitlement() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.error(StateError('No signed-in user.'));
    }
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      return UagEntitlement.fromUserDoc(uid, snapshot.data() ?? const <String, dynamic>{});
    });
  }

  Future<UagEntitlement?> getMyEntitlement() async {
    final uid = currentUid;
    if (uid == null) return null;
    final snapshot = await _firestore.collection('users').doc(uid).get();
    return UagEntitlement.fromUserDoc(uid, snapshot.data() ?? const <String, dynamic>{});
  }

  Stream<UagUsageSnapshot> watchMyWeeklyUsage() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(const UagUsageSnapshot(
        tradesUsed: 0,
        matchSearchesUsed: 0,
        intelHintsUsed: 0,
        extraActionsAvailable: 0,
      ));
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('monetisation_usage')
        .doc(_weekKey(DateTime.now()))
        .snapshots()
        .map((snapshot) => UagUsageSnapshot.fromMap(snapshot.data() ?? const <String, dynamic>{}));
  }

  Stream<List<UagImpactPotSnapshot>> watchImpactPots() {
    return _firestore.collection('impact_pots').orderBy('sortOrder').snapshots().map(
          (snapshot) => snapshot.docs.map(UagImpactPotSnapshot.fromDoc).toList(growable: false),
        );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAdminRevenueEvents({int limit = 50}) {
    return _firestore
        .collection('monetisation_events')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAdminUsers() {
    return _firestore.collection('users').snapshots();
  }

  Future<void> ensureReferralCode(String code) async {
    final uid = currentUid;
    if (uid == null) return;
    final normalised = code.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (normalised.length < 4) {
      throw ArgumentError('Referral code must be at least 4 characters.');
    }
    final codeRef = _firestore.collection('referral_codes').doc(normalised);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(codeRef);
      if (existing.exists && existing.data()?['ownerUid'] != uid) {
        throw StateError('That referral code is already taken.');
      }
      transaction.set(
        codeRef,
        {
          'code': normalised,
          'ownerUid': uid,
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      transaction.set(
        _firestore.collection('users').doc(uid),
        {
          'monetisation': {
            'referralCode': normalised,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          'referralCode': normalised,
        },
        SetOptions(merge: true),
      );
    });
  }

  String _weekKey(DateTime date) {
    final monday = DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }
}
