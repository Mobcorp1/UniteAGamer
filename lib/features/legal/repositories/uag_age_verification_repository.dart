import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:uag_arc_raiders_hub/features/legal/models/uag_age_verification_models.dart';

class UagAgeVerificationRepository {
  UagAgeVerificationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('uag_age_verification_requests');

  Stream<UagAgeVerificationRequest?> watchLatestRequest() {
    final uid = currentUid;
    if (uid == null) return Stream.value(null);
    return _requests
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return UagAgeVerificationRequest.fromMap(snapshot.docs.first.data());
        });
  }

  Future<String> submitDateOfBirth(DateTime dateOfBirth) async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('Sign in before completing age verification.');
    }
    final doc = _requests.doc();
    final request = UagAgeVerificationRequest(
      id: doc.id,
      uid: uid,
      dateOfBirthIso: DateTime.utc(
        dateOfBirth.year,
        dateOfBirth.month,
        dateOfBirth.day,
      ).toIso8601String(),
      status: UagAgeVerificationStatus.pending,
    );
    await doc.set(<String, dynamic>{
      ...request.toCreateMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> appealRejectedVerification({
    required String requestId,
    required String appealReason,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('Sign in before appealing age verification.');
    }
    await _requests.doc(requestId).set(<String, dynamic>{
      'id': requestId,
      'uid': uid,
      'status': UagAgeVerificationStatus.appealed.name,
      'appealReason': appealReason.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
