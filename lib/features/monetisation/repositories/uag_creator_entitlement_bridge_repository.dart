import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/uag_creator_reward_models.dart';
import '../models/uag_subscription_tier.dart';

class UagCreatorEntitlementGrantResult {
  const UagCreatorEntitlementGrantResult({
    required this.grantId,
    required this.recipientUid,
    required this.tier,
    required this.startedAt,
    required this.expiresAt,
    required this.alreadyGranted,
  });

  final String grantId;
  final String recipientUid;
  final UagSubscriptionTier tier;
  final DateTime startedAt;
  final DateTime expiresAt;
  final bool alreadyGranted;
}

class UagCreatorEntitlementBridgeRepository {
  UagCreatorEntitlementBridgeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchValidatedRewardClaims() =>
      _firestore.collectionGroup('monetisation_usage').snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRecipient(String uid) =>
      _firestore.collection('users').doc(uid.trim()).snapshots();

  Future<UagCreatorEntitlementGrantResult> grantValidatedReward(
    DocumentReference<Map<String, dynamic>> claimRef,
  ) async {
    return _firestore.runTransaction((transaction) async {
      final claimSnap = await transaction.get(claimRef);
      if (!claimSnap.exists) {
        throw StateError('Validated redemption claim was not found.');
      }
      final claim = claimSnap.data() ?? const <String, dynamic>{};
      final status = claim['status']?.toString() ?? '';
      if (status == 'entitlement_granted') {
        final existingGrantId = claim['entitlementGrantId']?.toString() ?? '';
        final recipientUid =
            claim['recipientUid']?.toString().trim() ??
            claimRef.parent.parent?.id ??
            '';
        final tier = _tierForReward(
          UagCreatorRewardType.fromValue(claim['rewardType']?.toString()),
        );
        final startedAt =
            _date(claim['entitlementStartedAt']) ?? DateTime.now().toUtc();
        final expiresAt = _date(claim['entitlementExpiresAt']) ?? startedAt;
        return UagCreatorEntitlementGrantResult(
          grantId: existingGrantId,
          recipientUid: recipientUid,
          tier: tier,
          startedAt: startedAt,
          expiresAt: expiresAt,
          alreadyGranted: true,
        );
      }
      if (status != 'validated_entitlement_pending') {
        throw StateError(
          'Reward must be validated before entitlement can be granted.',
        );
      }

      final recipientUid =
          claim['recipientUid']?.toString().trim() ??
          claimRef.parent.parent?.id ??
          '';
      final creatorUid = claim['creatorUid']?.toString().trim() ?? '';
      final sourceCode = claim['code']?.toString().trim().toUpperCase() ?? '';
      final rewardType = UagCreatorRewardType.fromValue(
        claim['rewardType']?.toString(),
      );
      if (recipientUid.isEmpty || sourceCode.isEmpty || rewardType == null) {
        throw StateError(
          'Validated reward is missing recipient, code or reward type.',
        );
      }
      if (creatorUid == recipientUid) {
        throw StateError(
          'Creators cannot grant their own Community Arsenal reward to themselves.',
        );
      }

      final grantId = 'creator_${sourceCode.toLowerCase()}';
      final userRef = _firestore.collection('users').doc(recipientUid);
      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) {
        throw StateError('Recipient user record was not found.');
      }
      final userData = userSnap.data() ?? const <String, dynamic>{};
      final grants = userData['creatorRewardEntitlements'];
      if (grants is Map && grants[grantId] is Map) {
        final existing = Map<String, dynamic>.from(grants[grantId] as Map);
        final existingPath = existing['sourceClaimPath']?.toString() ?? '';
        if (existingPath != claimRef.path) {
          throw StateError('Duplicate creator reward grant ID detected.');
        }
        final startedAt =
            _date(existing['startedAt']) ?? DateTime.now().toUtc();
        final expiresAt = _date(existing['expiresAt']) ?? startedAt;
        transaction.update(claimRef, <String, dynamic>{
          'status': 'entitlement_granted',
          'entitlementGrantId': grantId,
          'entitlementStartedAt': Timestamp.fromDate(startedAt),
          'entitlementExpiresAt': Timestamp.fromDate(expiresAt),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return UagCreatorEntitlementGrantResult(
          grantId: grantId,
          recipientUid: recipientUid,
          tier: _tierForReward(rewardType),
          startedAt: startedAt,
          expiresAt: expiresAt,
          alreadyGranted: true,
        );
      }

      final now = DateTime.now().toUtc();
      final expiresAt = now.add(_durationForReward(rewardType));
      final tier = _tierForReward(rewardType);
      final grant = <String, dynamic>{
        'grantId': grantId,
        'tier': tier.value,
        'startedAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'source': 'creator_community_arsenal',
        'sourceCode': sourceCode,
        'sourceClaimPath': claimRef.path,
        'creatorUid': creatorUid,
        'rewardType': rewardType.value,
        'createdAt': FieldValue.serverTimestamp(),
      };

      transaction.update(userRef, <String, dynamic>{
        'creatorRewardEntitlements.$grantId': grant,
      });
      transaction.update(claimRef, <String, dynamic>{
        'status': 'entitlement_granted',
        'entitlementGrantId': grantId,
        'entitlementStartedAt': Timestamp.fromDate(now),
        'entitlementExpiresAt': Timestamp.fromDate(expiresAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return UagCreatorEntitlementGrantResult(
        grantId: grantId,
        recipientUid: recipientUid,
        tier: tier,
        startedAt: now,
        expiresAt: expiresAt,
        alreadyGranted: false,
      );
    });
  }

  static UagSubscriptionTier _tierForReward(UagCreatorRewardType? type) =>
      switch (type) {
        UagCreatorRewardType.essential7Day ||
        UagCreatorRewardType.essentialMonth => UagSubscriptionTier.essential,
        UagCreatorRewardType.premium7Day ||
        UagCreatorRewardType.premiumMonth ||
        UagCreatorRewardType.annualPremium => UagSubscriptionTier.premium,
        null => UagSubscriptionTier.free,
      };

  static Duration _durationForReward(UagCreatorRewardType type) =>
      switch (type) {
        UagCreatorRewardType.essential7Day ||
        UagCreatorRewardType.premium7Day => const Duration(days: 7),
        UagCreatorRewardType.essentialMonth ||
        UagCreatorRewardType.premiumMonth => const Duration(days: 30),
        UagCreatorRewardType.annualPremium => const Duration(days: 365),
      };

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    return DateTime.tryParse(value.toString())?.toUtc();
  }
}
