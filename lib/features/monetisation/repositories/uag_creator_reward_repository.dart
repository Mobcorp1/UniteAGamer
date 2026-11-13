import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/uag_creator_reward_models.dart';

class UagCreatorRewardRepository {
  UagCreatorRewardRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  Stream<List<UagCreatorGiveawayCode>> watchMyGiveawayCodes() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(const <UagCreatorGiveawayCode>[]);
    }
    return _firestore
        .collection('uag_creator_campaign_code_requests')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final rows = snapshot.docs
              .where((doc) => doc.data()['requestType'] == 'community_giveaway')
              .map((doc) => UagCreatorGiveawayCode.fromMap(doc.data()))
              .toList(growable: false);
          rows.sort((a, b) => b.code.compareTo(a.code));
          return rows;
        });
  }

  Stream<List<UagCreatorRedemptionClaim>> watchMyRedemptions() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(const <UagCreatorRedemptionClaim>[]);
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('monetisation_usage')
        .where('recordType', isEqualTo: 'creator_giveaway_redemption')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => UagCreatorRedemptionClaim.fromMap(<String, dynamic>{
                  ...doc.data(),
                  'recipientUid': uid,
                }),
              )
              .toList(growable: false),
        );
  }

  Future<String> requestGiveawayCode(UagCreatorRewardType rewardType) async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('Sign in before requesting a giveaway code.');
    }

    final application = await _firestore
        .collection('uag_creator_applications')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
    if (application.docs.isEmpty ||
        application.docs.first.data()['status'] != 'approved') {
      throw StateError(
        'Only approved creators can request Community Arsenal codes.',
      );
    }

    final now = DateTime.now().toUtc();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final code = _newCode(now);
    final doc = _firestore
        .collection('uag_creator_campaign_code_requests')
        .doc(code);
    await doc.set(<String, dynamic>{
      'id': code,
      'code': code,
      'requestedCode': code,
      'uid': uid,
      'creatorHandle': '',
      'status': 'pending_admin_approval',
      'creatorTermsVersion': 1,
      'requestType': 'community_giveaway',
      'rewardType': rewardType.value,
      'monthKey': monthKey,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  Future<void> submitGiveawayRedemption(String rawCode) async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('Sign in before redeeming a creator code.');
    }
    final code = normaliseCreatorCode(rawCode);
    if (code.length < 6) {
      throw StateError('Enter a valid creator giveaway code.');
    }
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('monetisation_usage')
        .doc('creator_giveaway_redemption_$code');
    final existing = await ref.get();
    if (existing.exists) {
      final status = existing.data()?['status']?.toString() ?? '';
      if (status != 'rejected') {
        throw StateError(
          'This code is already awaiting validation or has been used on this account.',
        );
      }
    }
    await ref.set(<String, dynamic>{
      'recordType': 'creator_giveaway_redemption',
      'recipientUid': uid,
      'code': code,
      'status': 'pending_validation',
      'submittedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static String _newCode(DateTime now) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final suffix = List<String>.generate(
      7,
      (_) => alphabet[random.nextInt(alphabet.length)],
      growable: false,
    ).join();
    final stamp = now.millisecondsSinceEpoch.toRadixString(36).toUpperCase();
    return 'DROP${stamp.substring(stamp.length - 4)}$suffix';
  }
}

class UagCreatorRewardAdminRepository {
  UagCreatorRewardAdminRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchGiveawayCodeRequests() =>
      _firestore.collection('uag_creator_campaign_code_requests').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUsageClaims() =>
      _firestore.collectionGroup('monetisation_usage').snapshots();

  Future<void> approveCreatorReferralCode(String code) async {
    final normalized = normaliseCreatorCode(code);
    final ref = _firestore
        .collection('uag_creator_campaign_code_requests')
        .doc(normalized);
    final snap = await ref.get();
    if (!snap.exists) {
      throw StateError('Creator code was not found.');
    }
    final data = snap.data() ?? const <String, dynamic>{};
    if (data['requestType'] == 'community_giveaway') {
      throw StateError('Use giveaway issuance for Community Arsenal codes.');
    }
    await ref.update(<String, dynamic>{
      'status': 'active',
      'approvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> validateReferralClaim(
    DocumentReference<Map<String, dynamic>> claimRef,
  ) async {
    final claimSnap = await claimRef.get();
    final claim = claimSnap.data() ?? const <String, dynamic>{};
    final creatorUid = claim['creatorUid']?.toString().trim() ?? '';
    final code = normaliseCreatorCode(claim['creatorCode']?.toString() ?? '');
    final referredUid = claimRef.parent.parent?.id ?? '';
    if (creatorUid.isEmpty ||
        code.isEmpty ||
        referredUid.isEmpty ||
        creatorUid == referredUid) {
      throw StateError('Referral claim identity is invalid.');
    }
    final codeSnap = await _firestore
        .collection('uag_creator_campaign_code_requests')
        .doc(code)
        .get();
    final codeData = codeSnap.data() ?? const <String, dynamic>{};
    if (!codeSnap.exists ||
        codeData['uid'] != creatorUid ||
        codeData['status'] != 'active') {
      throw StateError('Referral code is not an active code for this creator.');
    }
    await claimRef.update(<String, dynamic>{
      'status': 'validated',
      'referredUid': referredUid,
      'validatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectReferralClaim(
    DocumentReference<Map<String, dynamic>> claimRef, {
    String reason = 'Admin validation rejected',
  }) => claimRef.update(<String, dynamic>{
    'status': 'rejected',
    'rejectionReason': reason,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> issueGiveawayCode(String code) async {
    final normalized = normaliseCreatorCode(code);
    final codeRef = _firestore
        .collection('uag_creator_campaign_code_requests')
        .doc(normalized);
    await _firestore.runTransaction((transaction) async {
      final codeSnap = await transaction.get(codeRef);
      if (!codeSnap.exists) {
        throw StateError('Giveaway code was not found.');
      }
      final data = codeSnap.data() ?? const <String, dynamic>{};
      if (data['requestType'] != 'community_giveaway' ||
          data['status'] != 'pending_admin_approval') {
        throw StateError('Giveaway code is not awaiting approval.');
      }
      final creatorUid = data['uid']?.toString().trim() ?? '';
      final rewardType = UagCreatorRewardType.fromValue(
        data['rewardType']?.toString(),
      );
      final requestMonth = data['monthKey']?.toString() ?? '';
      if (creatorUid.isEmpty || rewardType == null) {
        throw StateError('Giveaway request is incomplete.');
      }

      final dashboardRef = _firestore
          .collection('uag_creator_dashboard_aggregates')
          .doc(creatorUid);
      final dashboardSnap = await transaction.get(dashboardRef);
      final dashboard = dashboardSnap.data() ?? const <String, dynamic>{};
      final arsenal = dashboard['communityArsenal'] is Map
          ? Map<String, dynamic>.from(dashboard['communityArsenal'] as Map)
          : <String, dynamic>{};
      if ((arsenal['monthKey']?.toString() ?? '') != requestMonth) {
        throw StateError(
          'Creator Community Arsenal month does not match this request.',
        );
      }
      final pair = _inventoryFields(rewardType);
      final granted = (arsenal[pair.$1] as num?)?.toInt() ?? 0;
      final used = (arsenal[pair.$2] as num?)?.toInt() ?? 0;
      if (used >= granted) {
        throw StateError(
          'No remaining ${rewardType.label} allocation for this creator.',
        );
      }

      final now = DateTime.now().toUtc();
      transaction.update(dashboardRef, <String, dynamic>{
        'communityArsenal.${pair.$2}': used + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(codeRef, <String, dynamic>{
        'status': 'active',
        'issuedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 30))),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectGiveawayCode(String code) async {
    final normalized = normaliseCreatorCode(code);
    await _firestore
        .collection('uag_creator_campaign_code_requests')
        .doc(normalized)
        .update(<String, dynamic>{
          'status': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> validateGiveawayRedemption(
    DocumentReference<Map<String, dynamic>> claimRef,
  ) async {
    await _firestore.runTransaction((transaction) async {
      final claimSnap = await transaction.get(claimRef);
      final claim = claimSnap.data() ?? const <String, dynamic>{};
      if (claim['status'] != 'pending_validation') {
        throw StateError('Redemption is not pending validation.');
      }
      final recipientUid = claimRef.parent.parent?.id ?? '';
      final code = normaliseCreatorCode(claim['code']?.toString() ?? '');
      if (recipientUid.isEmpty || code.isEmpty) {
        throw StateError('Redemption identity is incomplete.');
      }

      final codeRef = _firestore
          .collection('uag_creator_campaign_code_requests')
          .doc(code);
      final codeSnap = await transaction.get(codeRef);
      if (!codeSnap.exists) {
        throw StateError('Giveaway code was not found.');
      }
      final codeData = codeSnap.data() ?? const <String, dynamic>{};
      final creatorUid = codeData['uid']?.toString().trim() ?? '';
      final rewardType = UagCreatorRewardType.fromValue(
        codeData['rewardType']?.toString(),
      );
      final expiresAt = codeData['expiresAt'];
      final expiry = expiresAt is Timestamp
          ? expiresAt.toDate().toUtc()
          : DateTime.tryParse(expiresAt?.toString() ?? '')?.toUtc();
      if (codeData['status'] != 'active' ||
          creatorUid.isEmpty ||
          rewardType == null) {
        throw StateError('Giveaway code is not active.');
      }
      if (creatorUid == recipientUid) {
        throw StateError('Creators cannot redeem their own giveaway code.');
      }
      if (expiry == null || !expiry.isAfter(DateTime.now().toUtc())) {
        throw StateError('Giveaway code has expired.');
      }
      if ((codeData['redeemedByUid']?.toString().trim() ?? '').isNotEmpty) {
        throw StateError('Giveaway code has already been redeemed.');
      }

      transaction.update(codeRef, <String, dynamic>{
        'status': 'redeemed',
        'redeemedByUid': recipientUid,
        'redeemedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(claimRef, <String, dynamic>{
        'status': 'validated_entitlement_pending',
        'recipientUid': recipientUid,
        'creatorUid': creatorUid,
        'rewardType': rewardType.value,
        'validatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectGiveawayRedemption(
    DocumentReference<Map<String, dynamic>> claimRef, {
    String reason = 'Admin validation rejected',
  }) => claimRef.update(<String, dynamic>{
    'status': 'rejected',
    'rejectionReason': reason,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  static (String, String) _inventoryFields(UagCreatorRewardType type) =>
      switch (type) {
        UagCreatorRewardType.essential7Day => (
          'essential7DayGranted',
          'essential7DayUsed',
        ),
        UagCreatorRewardType.essentialMonth => (
          'essentialMonthGranted',
          'essentialMonthUsed',
        ),
        UagCreatorRewardType.premium7Day => (
          'premium7DayGranted',
          'premium7DayUsed',
        ),
        UagCreatorRewardType.premiumMonth => (
          'premiumMonthGranted',
          'premiumMonthUsed',
        ),
        UagCreatorRewardType.annualPremium => (
          'annualPremiumGranted',
          'annualPremiumUsed',
        ),
      };
}
