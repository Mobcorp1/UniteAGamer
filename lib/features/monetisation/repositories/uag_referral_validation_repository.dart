import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/uag_referral_milestone_award_policy.dart';
import '../repositories/uag_referral_reward_locker_repository.dart';

class UagReferralValidationResult {
  const UagReferralValidationResult({
    required this.referrerUid,
    required this.referredUid,
    required this.previousValidatedReferrals,
    required this.newValidatedReferrals,
    required this.awardedMilestones,
  });

  final String referrerUid;
  final String referredUid;
  final int previousValidatedReferrals;
  final int newValidatedReferrals;
  final List<int> awardedMilestones;
}

class UagReferralValidationRepository {
  UagReferralValidationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _locker = UagReferralRewardLockerRepository(
         firestore: firestore,
         auth: auth,
       );

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UagReferralRewardLockerRepository _locker;

  String? get currentUid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _firestore.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _attribution(String referredUid) =>
      _user(
        referredUid,
      ).collection('monetisation_usage').doc('community_referral_attribution');

  Stream<Map<String, dynamic>> watchMyReferralProgress() {
    final uid = currentUid;
    if (uid == null) return Stream.value(const <String, dynamic>{});
    return _user(uid).snapshots().map((snapshot) {
      final data = snapshot.data() ?? const <String, dynamic>{};
      final referral = data['communityReferral'];
      return referral is Map
          ? Map<String, dynamic>.from(referral)
          : const <String, dynamic>{};
    });
  }

  Future<UagReferralValidationResult> validateReferral({
    required String referredUid,
    required String referrerUid,
    required String validationReason,
  }) async {
    final actorUid = currentUid;
    if (actorUid == null) {
      throw StateError('Sign in to validate referrals.');
    }
    if (referredUid.trim().isEmpty || referrerUid.trim().isEmpty) {
      throw StateError('Both referred and referrer user IDs are required.');
    }
    if (referredUid == referrerUid) {
      throw StateError('Self-referrals cannot be validated.');
    }

    final referrerRef = _user(referrerUid);
    final attributionRef = _attribution(referredUid);

    late int previousValidated;
    late int nextValidated;
    late List<UagReferralMilestoneAward> awards;

    await _firestore.runTransaction((transaction) async {
      final attributionSnap = await transaction.get(attributionRef);
      final attributionData =
          attributionSnap.data() ?? const <String, dynamic>{};

      final attributedReferrer =
          attributionData['referrerUid']?.toString().trim() ?? '';
      if (attributedReferrer.isNotEmpty && attributedReferrer != referrerUid) {
        throw StateError(
          'This Raider is already attributed to a different referrer.',
        );
      }

      final status = attributionData['status']?.toString() ?? '';
      if (status == 'validated') {
        throw StateError('This referral has already been validated.');
      }

      final referrerSnap = await transaction.get(referrerRef);
      final referrerData = referrerSnap.data() ?? const <String, dynamic>{};
      final referralData =
          (referrerData['communityReferral'] as Map?)
              ?.cast<String, dynamic>() ??
          const <String, dynamic>{};

      previousValidated =
          (referralData['validatedReferrals'] as num?)?.toInt() ?? 0;
      nextValidated = previousValidated + 1;

      final awardedRaw =
          (referralData['awardedMilestones'] as List?) ?? const <dynamic>[];
      final awarded = awardedRaw
          .map((value) => (value as num?)?.toInt())
          .whereType<int>()
          .toSet();

      awards = UagReferralMilestoneAwardPolicy.newlyEarnedAwards(
        previousValidatedReferrals: previousValidated,
        newValidatedReferrals: nextValidated,
        alreadyAwardedMilestones: awarded,
        referrerUid: referrerUid,
      );

      final newAwarded = <int>{
        ...awarded,
        ...awards.map((award) => award.milestone.validatedReferrals),
      }.toList()..sort();

      transaction.set(attributionRef, <String, dynamic>{
        'referrerUid': referrerUid,
        'referredUid': referredUid,
        'status': 'validated',
        'validatedAt': FieldValue.serverTimestamp(),
        'validatedByUid': actorUid,
        'validationReason': validationReason.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': attributionSnap.exists
            ? attributionData['createdAt']
            : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(referrerRef, <String, dynamic>{
        'communityReferral': <String, dynamic>{
          'validatedReferrals': nextValidated,
          'pendingReferrals': FieldValue.increment(-1),
          'awardedMilestones': newAwarded,
          'creatorFastTrackUnlocked': newAwarded.contains(5),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    });

    for (final award in awards) {
      final type = award.rewardType;
      if (type == null) continue;
      await _locker.bankReward(
        uid: referrerUid,
        rewardId: award.rewardId,
        type: type,
        sourceRef:
            'validated_referral:$referredUid:milestone:${award.milestone.validatedReferrals}',
      );
    }

    return UagReferralValidationResult(
      referrerUid: referrerUid,
      referredUid: referredUid,
      previousValidatedReferrals: previousValidated,
      newValidatedReferrals: nextValidated,
      awardedMilestones: awards
          .map((award) => award.milestone.validatedReferrals)
          .toList(growable: false),
    );
  }
}
