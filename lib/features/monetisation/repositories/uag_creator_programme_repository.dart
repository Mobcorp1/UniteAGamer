import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_programme_models.dart';

class UagCreatorProgrammeRepository {
  UagCreatorProgrammeRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection('uag_creator_applications');

  CollectionReference<Map<String, dynamic>> get _campaignCodeRequests =>
      _firestore.collection('uag_creator_campaign_code_requests');

  DocumentReference<Map<String, dynamic>> _dashboard(String uid) =>
      _firestore.collection('uag_creator_dashboard_aggregates').doc(uid);

  CollectionReference<Map<String, dynamic>> _commissionLedger(String uid) =>
      _firestore
          .collection('uag_creator_commission_ledgers')
          .doc(uid)
          .collection('entries');

  Stream<UagCreatorProgrammeApplication?> watchMyApplication() {
    final uid = currentUid;
    if (uid == null) return Stream.value(null);
    return _applications
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return UagCreatorProgrammeApplication.fromMap(
            snapshot.docs.first.data(),
          );
        });
  }

  Stream<UagCreatorDashboardAggregate> watchMyDashboardAggregate() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(const UagCreatorDashboardAggregate(uid: ''));
    }
    return _dashboard(uid).snapshots().map(
      (snapshot) => UagCreatorDashboardAggregate.fromMap(<String, dynamic>{
        'uid': uid,
        ...?snapshot.data(),
      }),
    );
  }

  Stream<List<UagCreatorCommissionLedgerEntry>> watchMyCommissionLedger({
    int limit = 50,
  }) {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(const <UagCreatorCommissionLedgerEntry>[]);
    }
    return _commissionLedger(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UagCreatorCommissionLedgerEntry.fromMap(doc.data()))
              .where((entry) => entry.creatorUid == uid)
              .toList(growable: false),
        );
  }

  Future<String> submitApplication({
    required String displayName,
    required List<String> platforms,
    required Map<String, String> socialHandles,
    required int agreedTermsVersion,
    int? audienceSize,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('Sign in before applying to the Creator Programme.');
    }
    if (agreedTermsVersion <= 0) {
      throw StateError('Creator terms must be accepted before applying.');
    }
    final doc = _applications.doc();
    final application = UagCreatorProgrammeApplication(
      id: doc.id,
      uid: uid,
      displayName: displayName.trim(),
      platforms: platforms
          .map((platform) => platform.trim())
          .where((platform) => platform.isNotEmpty)
          .toList(growable: false),
      socialHandles: socialHandles.map(
        (key, value) => MapEntry(key.trim(), value.trim()),
      )..removeWhere((key, value) => key.isEmpty || value.isEmpty),
      audienceSize: audienceSize,
      status: UagCreatorApplicationStatus.pending,
      agreedTermsVersion: agreedTermsVersion,
      createdAtIso: DateTime.now().toUtc().toIso8601String(),
    );
    await doc.set(<String, dynamic>{
      ...application.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<String> requestCampaignCode({
    required String rawCode,
    required String creatorHandle,
    required int creatorTermsVersion,
    Iterable<String> locallyKnownExistingCodes = const <String>[],
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('Sign in before requesting campaign codes.');
    }
    if (creatorTermsVersion <= 0) {
      throw StateError(
        'Creator terms must be accepted before requesting codes.',
      );
    }
    final validation = const UagCreatorCampaignCodePolicy().normalise(
      raw: rawCode,
      creatorHandle: creatorHandle,
      existingCodes: locallyKnownExistingCodes,
    );
    if (!validation.valid) {
      throw StateError(validation.reasons.join(' '));
    }
    final doc = _campaignCodeRequests.doc(validation.normalizedCode);
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(doc);
      if (existing.exists && existing.data()?['uid'] != uid) {
        throw StateError('That campaign code is already requested.');
      }
      transaction.set(doc, <String, dynamic>{
        'id': validation.normalizedCode,
        'code': validation.normalizedCode,
        'requestedCode': validation.requestedCode,
        'uid': uid,
        'creatorHandle': creatorHandle.trim(),
        'status': 'pending_admin_approval',
        'creatorTermsVersion': creatorTermsVersion,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    return validation.normalizedCode;
  }
}
