import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/uag_referral_terms_policy.dart';

class UagCommunityReferralRepository {
  UagCommunityReferralRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _profile(String uid) =>
      _firestore.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _terms(String uid) =>
      _firestore.collection('uag_referral_terms_acceptances').doc(uid);

  CollectionReference<Map<String, dynamic>> get _codeRegistry =>
      _firestore.collection('uag_community_referral_codes');

  Stream<Map<String, dynamic>> watchMyReferralSummary() {
    final uid = currentUid;
    if (uid == null) return Stream.value(const <String, dynamic>{});
    return _profile(uid).snapshots().map((snapshot) {
      final data = snapshot.data() ?? const <String, dynamic>{};
      final referral = data['communityReferral'];
      return referral is Map
          ? Map<String, dynamic>.from(referral)
          : const <String, dynamic>{};
    });
  }

  Stream<bool> watchReferralTermsAccepted() {
    final uid = currentUid;
    if (uid == null) return Stream.value(false);
    return _terms(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      return data?['accepted'] == true &&
          data?['version'] == UagReferralTermsPolicy.version;
    });
  }

  Future<void> acceptCurrentReferralTerms() async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('Sign in before accepting referral terms.');
    }
    await _terms(uid).set(<String, dynamic>{
      'uid': uid,
      'accepted': true,
      'version': UagReferralTermsPolicy.version,
      'acceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> _hasAcceptedCurrentTerms(String uid) async {
    final snapshot = await _terms(uid).get();
    final data = snapshot.data();
    return data?['accepted'] == true &&
        data?['version'] == UagReferralTermsPolicy.version;
  }

  Future<String> ensureMyReferralCode() async {
    final uid = currentUid;
    if (uid == null) throw StateError('Sign in to create a referral code.');
    if (!await _hasAcceptedCurrentTerms(uid)) {
      throw StateError(
        'Accept the current Refer a Raider terms before creating a referral link.',
      );
    }

    final profile = _profile(uid);
    final snapshot = await profile.get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final referral = data['communityReferral'];
    if (referral is Map) {
      final existing = referral['code']?.toString().trim().toUpperCase() ?? '';
      if (existing.isNotEmpty) {
        final registered = await _codeRegistry.doc(existing).get();
        if (registered.data()?['ownerUid'] == uid) return existing;
      }
    }

    final compactUid = uid
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    final seed = compactUid.isEmpty
        ? uid.hashCode.abs().toString()
        : compactUid;
    final lengths = <int>[8, 10, 12, 14, 16, seed.length];

    for (final requestedLength in lengths.toSet()) {
      final take = requestedLength.clamp(1, seed.length);
      final suffix = seed.substring(seed.length - take);
      final code = 'RAIDER$suffix';
      final codeRef = _codeRegistry.doc(code);

      final claimed = await _firestore.runTransaction<bool>((
        transaction,
      ) async {
        final existing = await transaction.get(codeRef);
        if (existing.exists) {
          return existing.data()?['ownerUid'] == uid;
        }
        transaction.set(codeRef, <String, dynamic>{
          'code': code,
          'ownerUid': uid,
          'termsVersion': UagReferralTermsPolicy.version,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      });

      if (!claimed) continue;

      await profile.set(<String, dynamic>{
        'communityReferral': <String, dynamic>{
          'code': code,
          'termsVersion': UagReferralTermsPolicy.version,
          'validatedReferrals': 0,
          'pendingReferrals': 0,
          'rewardMilestonesClaimed': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      return code;
    }

    throw StateError(
      'Unable to reserve a unique referral code. Please try again.',
    );
  }

  Uri referralUri(String code) =>
      Uri.https('unite-a-gamer.web.app', '/', <String, String>{
        'referrer': currentUid ?? '',
        'refcode': code.trim().toUpperCase(),
      });
}
