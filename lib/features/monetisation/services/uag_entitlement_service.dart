import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/uag_ad_policy.dart';
import '../models/uag_plan_limits.dart';
import '../models/uag_subscription_tier.dart';
import '../models/uag_user_entitlement.dart';

class UagUsageGateResult {
  const UagUsageGateResult({
    required this.allowed,
    required this.action,
    required this.used,
    required this.limit,
    required this.tier,
    this.reason,
  });

  final bool allowed;
  final UagBillableAction action;
  final int used;
  final int? limit;
  final UagSubscriptionTier tier;
  final String? reason;

  bool get unlimited => limit == null;
  int? get remaining => limit == null ? null : (limit! - used).clamp(0, limit!);
}

class UagEntitlementService {
  UagEntitlementService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get uid => _auth.currentUser?.uid;

  Stream<UagUserEntitlement> watchMyEntitlement() {
    final currentUid = uid;
    if (currentUid == null) {
      return Stream.error(StateError('User must be signed in.'));
    }

    return _firestore.collection('users').doc(currentUid).snapshots().map(
          (snapshot) => UagUserEntitlement.fromUserDoc(
            uid: currentUid,
            data: snapshot.data() ?? <String, dynamic>{},
          ),
        );
  }

  Future<UagUserEntitlement> getMyEntitlement() async {
    final currentUid = uid;
    if (currentUid == null) {
      throw StateError('User must be signed in.');
    }
    final snapshot = await _firestore.collection('users').doc(currentUid).get();
    return UagUserEntitlement.fromUserDoc(
      uid: currentUid,
      data: snapshot.data() ?? <String, dynamic>{},
    );
  }

  Future<UagPlanLimits> getMyLimits() async => (await getMyEntitlement()).limits;

  Future<UagAdPolicy> getMyAdPolicy() async => (await getMyEntitlement()).adPolicy;

  Future<bool> canUseTraderProAnalytics() async => (await getMyEntitlement()).canUseTraderProAnalytics;

  Future<bool> canUseAdvancedVoicePersonalities() async => (await getMyEntitlement()).canUseAdvancedVoicePersonalities;

  Future<bool> canUseSmartAlerts() async => (await getMyEntitlement()).canUseSmartAlerts;

  Future<bool> shouldShowBannerAds() async {
    final entitlement = await getMyEntitlement();
    return entitlement.adPolicy.showBannerAds;
  }

  Future<bool> shouldShowRewardedAds() async {
    final entitlement = await getMyEntitlement();
    return entitlement.adPolicy.showRewardedAds;
  }

  Future<bool> shouldBlockAdsInActiveSession() async {
    final entitlement = await getMyEntitlement();
    return !entitlement.adPolicy.allowMidSessionAds;
  }

  Stream<Map<String, int>> watchCurrentWeeklyUsage() {
    final currentUid = uid;
    if (currentUid == null) return Stream.value(const <String, int>{});
    return _firestore
        .collection('users')
        .doc(currentUid)
        .collection('usage_counters')
        .doc(_currentWeekKey())
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data() ?? <String, dynamic>{};
      return {
        for (final action in UagBillableAction.values)
          action.usageKey: (data[action.usageKey] as num?)?.toInt() ?? 0,
      };
    });
  }

  Future<UagUsageGateResult> canUseAction(UagBillableAction action) async {
    final entitlement = await getMyEntitlement();
    final limit = entitlement.limits.limitFor(action);
    if (entitlement.hasAdminBypass || limit == null) {
      return UagUsageGateResult(
        allowed: true,
        action: action,
        used: 0,
        limit: null,
        tier: entitlement.tier,
      );
    }

    final usageDoc = await _firestore
        .collection('users')
        .doc(entitlement.uid)
        .collection('usage_counters')
        .doc(_currentWeekKey())
        .get();
    final used = (usageDoc.data()?[action.usageKey] as num?)?.toInt() ?? 0;
    final allowed = used < limit;
    return UagUsageGateResult(
      allowed: allowed,
      action: action,
      used: used,
      limit: limit,
      tier: entitlement.tier,
      reason: allowed
          ? null
          : '${action.label} limit reached for ${entitlement.tier.publicName}.',
    );
  }

  Future<UagUsageGateResult> consumeAction(UagBillableAction action) async {
    final currentUid = uid;
    if (currentUid == null) throw StateError('User must be signed in.');

    final entitlement = await getMyEntitlement();
    final limit = entitlement.limits.limitFor(action);
    if (entitlement.hasAdminBypass || limit == null) {
      return UagUsageGateResult(
        allowed: true,
        action: action,
        used: 0,
        limit: null,
        tier: entitlement.tier,
      );
    }

    final docRef = _firestore
        .collection('users')
        .doc(currentUid)
        .collection('usage_counters')
        .doc(_currentWeekKey());

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data() ?? <String, dynamic>{};
      final used = (data[action.usageKey] as num?)?.toInt() ?? 0;
      if (used >= limit) {
        return UagUsageGateResult(
          allowed: false,
          action: action,
          used: used,
          limit: limit,
          tier: entitlement.tier,
          reason: '${action.label} limit reached for ${entitlement.tier.publicName}.',
        );
      }

      transaction.set(
        docRef,
        {
          'uid': currentUid,
          'periodKey': _currentWeekKey(),
          'periodType': 'weekly',
          action.usageKey: FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': snapshot.exists
              ? data['createdAt']
              : FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return UagUsageGateResult(
        allowed: true,
        action: action,
        used: used + 1,
        limit: limit,
        tier: entitlement.tier,
      );
    });
  }

  Future<String> ensureMyReferralCode() async {
    final currentUid = uid;
    final user = _auth.currentUser;
    if (currentUid == null || user == null) {
      throw StateError('User must be signed in.');
    }

    final entitlement = await getMyEntitlement();
    final userRef = _firestore.collection('users').doc(currentUid);
    final userSnap = await userRef.get();
    final existing = userSnap.data()?['referralCode'] as String?;
    if (existing != null && existing.trim().isNotEmpty) return existing;

    final base = (user.displayName ?? user.email ?? currentUid)
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .padRight(6, 'UAG')
        .substring(0, 6);
    final code = '$base${currentUid.substring(0, 4).toUpperCase()}';

    await _firestore.runTransaction((transaction) async {
      final codeRef = _firestore.collection('referral_codes').doc(code);
      final codeSnap = await transaction.get(codeRef);
      if (codeSnap.exists) return;
      transaction.set(codeRef, {
        'code': code,
        'ownerUid': currentUid,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'discountPercent': entitlement.limits.referralDiscountPercent,
        'commissionPercent': entitlement.limits.referralCommissionPercent,
      });
      transaction.set(userRef, {
        'referralCode': code,
        'referralDiscountPercent': entitlement.limits.referralDiscountPercent,
        'referralCommissionPercent': entitlement.limits.referralCommissionPercent,
      }, SetOptions(merge: true));
    });

    return code;
  }

  Future<void> requestPayout({required int amountPence}) async {
    final entitlement = await getMyEntitlement();
    if (amountPence < entitlement.limits.payoutThresholdPence) {
      throw StateError('Minimum payout is £${(entitlement.limits.payoutThresholdPence / 100).toStringAsFixed(2)}.');
    }
    if (amountPence > entitlement.availableBalancePence) {
      throw StateError('Requested payout is higher than available balance.');
    }

    await _firestore.collection('payout_requests').add({
      'uid': entitlement.uid,
      'amountPence': amountPence,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _currentWeekKey() {
    final now = DateTime.now().toUtc();
    final startOfYear = DateTime.utc(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays + 1;
    final week = ((dayOfYear - now.weekday + 10) / 7).floor();
    return '${now.year}-W${week.toString().padLeft(2, '0')}';
  }
}
