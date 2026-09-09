import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/uag_creator_live_models.dart';
import '../models/uag_creator_programme_models.dart';

class UagCreatorLiveRepository {
  UagCreatorLiveRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  Stream<UagCreatorProgrammeApplication?> watchMyApplication() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(null);
    }
    return _firestore
        .collection('uag_creator_applications')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.isEmpty
              ? null
              : UagCreatorProgrammeApplication.fromMap(
                  snapshot.docs.first.data(),
                ),
        );
  }

  Stream<UagCreatorLiveDashboard> watchMyDashboard() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(const UagCreatorLiveDashboard(uid: ''));
    }
    return _firestore
        .collection('uag_creator_dashboard_aggregates')
        .doc(uid)
        .snapshots()
        .map(
          (snapshot) => UagCreatorLiveDashboard.fromMap(uid, snapshot.data()),
        );
  }

  Stream<List<UagCreatorCodeRecord>> watchMyCodeRequests() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(const <UagCreatorCodeRecord>[]);
    }
    return _firestore
        .collection('uag_creator_campaign_code_requests')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final rows = snapshot.docs
              .map((doc) => UagCreatorCodeRecord.fromMap(doc.data()))
              .toList(growable: false);
          rows.sort((a, b) => a.code.compareTo(b.code));
          return rows;
        });
  }

  Future<void> capturePendingAttribution({
    required String creatorUid,
    required String creatorCode,
    String source = 'creator_link',
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('Sign in before using a creator referral.');
    }
    if (creatorUid.trim().isEmpty || creatorUid == uid) {
      throw StateError('A creator referral cannot point to the same account.');
    }
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('monetisation_usage')
        .doc('creator_attribution');
    final existing = await ref.get();
    if (existing.exists &&
        (existing.data()?['creatorUid'] ?? '').toString().trim().isNotEmpty) {
      return;
    }
    final claim = UagCreatorAttributionClaim(
      creatorUid: creatorUid.trim(),
      creatorCode: creatorCode.trim().toUpperCase(),
      source: source.trim().isEmpty ? 'creator_link' : source.trim(),
      capturedAtIso: DateTime.now().toUtc().toIso8601String(),
    );
    await ref.set(<String, dynamic>{
      ...claim.toMap(),
      'capturedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static String creatorShareLink({
    required String creatorUid,
    required String code,
  }) {
    final encodedUid = Uri.encodeQueryComponent(creatorUid.trim());
    final encodedCode = Uri.encodeQueryComponent(code.trim().toUpperCase());
    return 'https://unite-a-gamer.web.app/?creator=$encodedUid&code=$encodedCode';
  }
}
