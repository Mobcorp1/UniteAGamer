import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/uag_community_referral_link.dart';

class UagCommunityReferralAttributionRepository {
  UagCommunityReferralAttributionRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _firestore.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _attribution(String uid) => _user(
    uid,
  ).collection('monetisation_usage').doc('community_referral_attribution');

  Future<bool> captureForCurrentUser(UagCommunityReferralLink link) async {
    final user = _auth.currentUser;
    if (user == null || !link.isValid) return false;

    final referredUid = user.uid;
    final referrerUid = link.referrerUid.trim();
    if (referrerUid == referredUid) return false;

    final referredAttribution = _attribution(referredUid);
    final referrer = _user(referrerUid);

    return _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(referredAttribution);
      if (existing.exists) {
        return false;
      }

      final referrerSnapshot = await transaction.get(referrer);
      if (!referrerSnapshot.exists) {
        return false;
      }

      final codeRef = _firestore
          .collection('uag_community_referral_codes')
          .doc(link.normalizedCode);
      final codeSnapshot = await transaction.get(codeRef);
      if (!codeSnapshot.exists) return false;

      final codeData = codeSnapshot.data() ?? const <String, dynamic>{};
      final codeOwner = codeData['ownerUid']?.toString().trim() ?? '';
      final canonicalCode =
          codeData['code']?.toString().trim().toUpperCase() ?? '';
      if (codeOwner != referrerUid ||
          canonicalCode.isEmpty ||
          canonicalCode != link.normalizedCode) {
        return false;
      }

      transaction.set(referredAttribution, <String, dynamic>{
        'referredUid': referredUid,
        'referrerUid': referrerUid,
        'code': canonicalCode,
        'status': 'pending_validation',
        'source': 'community_referral_link',
        'capturedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(referrer, <String, dynamic>{
        'communityReferral.pendingReferrals': FieldValue.increment(1),
        'communityReferral.updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    });
  }
}
