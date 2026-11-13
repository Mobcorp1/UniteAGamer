import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_referral_link.dart';

class UagCreatorReferralRepository {
  UagCreatorReferralRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<bool> capturePendingReferral(UagCreatorReferralLink link) async {
    final user = _auth.currentUser;
    if (user == null || !link.isValid) {
      return false;
    }
    if (user.uid == link.creatorUid.trim()) {
      return false;
    }

    final ref = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('monetisation_usage')
        .doc('creator_attribution');

    return _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (existing.exists) {
        return false;
      }

      transaction.set(ref, <String, dynamic>{
        'userUid': user.uid,
        'creatorUid': link.creatorUid.trim(),
        'code': link.normalizedCode,
        'status': 'pending_validation',
        'capturedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'source': 'creator_referral_link',
      });
      return true;
    });
  }
}
