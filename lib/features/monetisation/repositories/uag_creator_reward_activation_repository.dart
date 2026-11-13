import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/uag_creator_reward_activation_policy.dart';
import '../models/uag_creator_reward_models.dart';
import '../models/uag_subscription_tier.dart';

class UagCreatorAutomaticActivationResult {
  const UagCreatorAutomaticActivationResult({
    required this.grantId,
    required this.recipientUid,
    required this.tier,
    required this.startedAt,
    required this.expiresAt,
    required this.alreadyActivated,
  });

  final String grantId;
  final String recipientUid;
  final UagSubscriptionTier tier;
  final DateTime startedAt;
  final DateTime expiresAt;
  final bool alreadyActivated;
}

class UagCreatorRewardActivationRepository {
  UagCreatorRewardActivationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<UagCreatorAutomaticActivationResult> validateAndActivate(
    DocumentReference<Map<String, dynamic>> claimRef,
  ) async {
    return _firestore.runTransaction((transaction) async {
      final claimSnap = await transaction.get(claimRef);
      if (!claimSnap.exists) {
        throw StateError('Creator giveaway redemption was not found.');
      }
      final claim = claimSnap.data() ?? const <String, dynamic>{};
      final status = claim['status']?.toString() ?? '';

      if (status == 'entitlement_granted') {
        final recipientUid =
            claim['recipientUid']?.toString().trim() ??
            claimRef.parent.parent?.id ??
            '';
        final rewardType = UagCreatorRewardType.fromValue(
          claim['rewardType']?.toString(),
        );
        if (recipientUid.isEmpty || rewardType == null) {
          throw StateError(
            'Existing creator entitlement record is incomplete.',
          );
        }
        final startedAt =
            _date(claim['entitlementStartedAt']) ?? DateTime.now().toUtc();
        final expiresAt = _date(claim['entitlementExpiresAt']) ?? startedAt;
        return UagCreatorAutomaticActivationResult(
          grantId: claim['entitlementGrantId']?.toString() ?? '',
          recipientUid: recipientUid,
          tier: UagCreatorRewardActivationPolicy.tierFor(rewardType),
          startedAt: startedAt,
          expiresAt: expiresAt,
          alreadyActivated: true,
        );
      }

      if (status != 'pending_validation') {
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
      final expiry = _date(codeData['expiresAt']);

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

      final userRef = _firestore.collection('users').doc(recipientUid);
      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) {
        throw StateError('Recipient user record was not found.');
      }

      final grantId = 'creator_${code.toLowerCase()}';
      final userData = userSnap.data() ?? const <String, dynamic>{};
      final grants = userData['creatorRewardEntitlements'];
      if (grants is Map && grants[grantId] is Map) {
        final existing = Map<String, dynamic>.from(grants[grantId] as Map);
        final existingCode =
            existing['sourceCode']?.toString().trim().toUpperCase() ?? '';
        if (existingCode != code) {
          throw StateError('Duplicate creator reward grant ID detected.');
        }
        final startedAt =
            _date(existing['startedAt']) ?? DateTime.now().toUtc();
        final expiresAt = _date(existing['expiresAt']) ?? startedAt;
        transaction.update(codeRef, <String, dynamic>{
          'status': 'redeemed',
          'redeemedByUid': recipientUid,
          'redeemedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(claimRef, <String, dynamic>{
          'status': 'entitlement_granted',
          'recipientUid': recipientUid,
          'creatorUid': creatorUid,
          'rewardType': rewardType.value,
          'validatedAt': FieldValue.serverTimestamp(),
          'entitlementGrantId': grantId,
          'entitlementStartedAt': Timestamp.fromDate(startedAt),
          'entitlementExpiresAt': Timestamp.fromDate(expiresAt),
          'activationMode': 'atomic_validation',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return UagCreatorAutomaticActivationResult(
          grantId: grantId,
          recipientUid: recipientUid,
          tier: UagCreatorRewardActivationPolicy.tierFor(rewardType),
          startedAt: startedAt,
          expiresAt: expiresAt,
          alreadyActivated: true,
        );
      }

      final now = DateTime.now().toUtc();
      final expiresAt = UagCreatorRewardActivationPolicy.expiryFor(
        rewardType,
        now,
      );
      final tier = UagCreatorRewardActivationPolicy.tierFor(rewardType);
      final claimPath = claimRef.path;
      final grant = <String, dynamic>{
        'grantId': grantId,
        'tier': tier.value,
        'startedAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'source': 'creator_community_arsenal',
        'sourceCode': code,
        'sourceClaimPath': claimPath,
        'creatorUid': creatorUid,
        'rewardType': rewardType.value,
        'activationMode': 'atomic_validation',
        'lifecycleVersion': 1,
        'activatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      transaction.update(userRef, <String, dynamic>{
        'creatorRewardEntitlements.$grantId': grant,
      });
      transaction.update(codeRef, <String, dynamic>{
        'status': 'redeemed',
        'redeemedByUid': recipientUid,
        'redeemedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(claimRef, <String, dynamic>{
        'status': 'entitlement_granted',
        'recipientUid': recipientUid,
        'creatorUid': creatorUid,
        'rewardType': rewardType.value,
        'validatedAt': FieldValue.serverTimestamp(),
        'entitlementGrantId': grantId,
        'entitlementStartedAt': Timestamp.fromDate(now),
        'entitlementExpiresAt': Timestamp.fromDate(expiresAt),
        'activationMode': 'atomic_validation',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return UagCreatorAutomaticActivationResult(
        grantId: grantId,
        recipientUid: recipientUid,
        tier: tier,
        startedAt: now,
        expiresAt: expiresAt,
        alreadyActivated: false,
      );
    });
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    return DateTime.tryParse(value.toString())?.toUtc();
  }
}
