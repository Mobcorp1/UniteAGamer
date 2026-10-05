import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/uag_ad_policy.dart';
import '../models/uag_commercial_economy.dart';
import '../models/uag_entitlement_test_mode.dart';
import '../models/uag_plan_limits.dart';
import '../models/uag_premium_pass_entitlement.dart';
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

    late StreamController<UagUserEntitlement> controller;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? subscription;
    Timer? expiryTimer;
    UagUserEntitlement? latest;

    void scheduleExpiryRefresh(UagUserEntitlement entitlement) {
      expiryTimer?.cancel();
      final expiry = entitlement.nextCreatorRewardExpiryAt;
      if (expiry == null) return;
      final delay = expiry.difference(DateTime.now().toUtc());
      if (delay <= Duration.zero) return;
      expiryTimer = Timer(delay + const Duration(seconds: 1), () {
        final current = latest;
        if (current != null && !controller.isClosed) {
          controller.add(current);
          scheduleExpiryRefresh(current);
        }
      });
    }

    controller = StreamController<UagUserEntitlement>(
      onListen: () {
        subscription = _firestore
            .collection('users')
            .doc(currentUid)
            .snapshots()
            .listen((snapshot) {
              final entitlement = UagUserEntitlement.fromUserDoc(
                uid: currentUid,
                data: snapshot.data() ?? <String, dynamic>{},
              );
              latest = entitlement;
              controller.add(entitlement);
              scheduleExpiryRefresh(entitlement);
            }, onError: controller.addError);
      },
      onCancel: () async {
        expiryTimer?.cancel();
        await subscription?.cancel();
      },
    );
    return controller.stream;
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

  Future<UagPlanLimits> getMyLimits() async =>
      (await getMyEntitlement()).limits;

  Future<UagAdPolicy> getMyAdPolicy() async =>
      (await getMyEntitlement()).adPolicy;

  Future<bool> canUseTraderProAnalytics() async =>
      (await getMyEntitlement()).canUseTraderProAnalytics;

  Future<bool> canUseAdvancedVoicePersonalities() async =>
      (await getMyEntitlement()).canUseAdvancedVoicePersonalities;

  Future<bool> canUseSmartAlerts() async =>
      (await getMyEntitlement()).canUseSmartAlerts;

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

  Stream<Map<String, int>> watchCurrentUsage() {
    final currentUid = uid;
    if (currentUid == null) return Stream.value(const <String, int>{});

    late StreamController<Map<String, int>> controller;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? monthlySub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? weeklySub;

    Map<String, dynamic> monthly = const <String, dynamic>{};
    Map<String, dynamic> weekly = const <String, dynamic>{};

    var monthlyReady = false;
    var weeklyReady = false;

    void emit() {
      if (!monthlyReady || !weeklyReady || controller.isClosed) return;

      controller.add(<String, int>{
        for (final action in UagBillableAction.values)
          action.usageKey:
              ((UagCommercialEconomy.usesMonthlyAllowance(action)
                          ? monthly[action.usageKey]
                          : weekly[action.usageKey])
                      as num?)
                  ?.toInt() ??
              0,
      });
    }

    controller = StreamController<Map<String, int>>(
      onListen: () {
        final base = _firestore
            .collection('users')
            .doc(currentUid)
            .collection('usage_counters');

        monthlySub = base.doc(_currentMonthKey()).snapshots().listen((
          snapshot,
        ) {
          monthly = snapshot.data() ?? const <String, dynamic>{};
          monthlyReady = true;
          emit();
        }, onError: controller.addError);

        weeklySub = base.doc(_currentWeekKey()).snapshots().listen((snapshot) {
          weekly = snapshot.data() ?? const <String, dynamic>{};
          weeklyReady = true;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await monthlySub?.cancel();
        await weeklySub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Backwards-compatible name retained for existing consumers.
  /// The returned snapshot respects each action's actual billing cadence.
  Stream<Map<String, int>> watchCurrentWeeklyUsage() => watchCurrentUsage();

  Stream<Map<String, int>> watchCurrentMonthlyUsage() {
    final currentUid = uid;
    if (currentUid == null) return Stream.value(const <String, int>{});
    return _firestore
        .collection('users')
        .doc(currentUid)
        .collection('usage_counters')
        .doc(_currentMonthKey())
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data() ?? <String, dynamic>{};
          return {
            for (final action in UagBillableAction.values)
              action.usageKey: (data[action.usageKey] as num?)?.toInt() ?? 0,
          };
        });
  }

  Stream<Map<String, int>> watchCurrentMonthlyBonuses() {
    final currentUid = uid;
    if (currentUid == null) return Stream.value(const <String, int>{});
    return _firestore
        .collection('uag_reward_bonuses')
        .doc(currentUid)
        .collection('months')
        .doc(_currentMonthKey())
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data() ?? <String, dynamic>{};
          return {
            for (final action in UagBillableAction.values)
              action.usageKey: (data[action.usageKey] as num?)?.toInt() ?? 0,
          };
        });
  }

  Future<int?> _limitIncludingRewards(
    UagUserEntitlement entitlement,
    UagBillableAction action,
  ) async {
    final base = entitlement.limits.limitFor(action);
    if (base == null || !UagCommercialEconomy.usesMonthlyAllowance(action)) {
      return base;
    }
    final bonus = await _firestore
        .collection('uag_reward_bonuses')
        .doc(entitlement.uid)
        .collection('months')
        .doc(_currentMonthKey())
        .get();
    final extra = (bonus.data()?[action.usageKey] as num?)?.toInt() ?? 0;
    return base + (extra < 0 ? 0 : extra);
  }

  Future<UagUsageGateResult> canUseAction(UagBillableAction action) async {
    final entitlement = await getMyEntitlement();
    final limit = await _limitIncludingRewards(entitlement, action);
    if (limit == null) {
      return UagUsageGateResult(
        allowed: true,
        action: action,
        used: 0,
        limit: null,
        tier: entitlement.effectiveTier,
      );
    }

    final periodKey = _periodKeyForAction(action);
    final usageDoc = await _firestore
        .collection('users')
        .doc(entitlement.uid)
        .collection('usage_counters')
        .doc(periodKey)
        .get();
    final used = (usageDoc.data()?[action.usageKey] as num?)?.toInt() ?? 0;
    final allowed = used < limit;
    return UagUsageGateResult(
      allowed: allowed,
      action: action,
      used: used,
      limit: limit,
      tier: entitlement.effectiveTier,
      reason: allowed
          ? null
          : '${action.label} ${UagCommercialEconomy.allowancePeriodLabel(action)} limit reached for ${entitlement.effectiveTier.publicName}.',
    );
  }

  Future<UagUsageGateResult> consumeAction(UagBillableAction action) async {
    final currentUid = uid;
    if (currentUid == null) throw StateError('User must be signed in.');

    final entitlement = await getMyEntitlement();
    final limit = await _limitIncludingRewards(entitlement, action);
    if (limit == null) {
      return UagUsageGateResult(
        allowed: true,
        action: action,
        used: 0,
        limit: null,
        tier: entitlement.effectiveTier,
      );
    }

    final periodKey = _periodKeyForAction(action);
    final periodType = UagCommercialEconomy.allowancePeriodLabel(action);
    final docRef = _firestore
        .collection('users')
        .doc(currentUid)
        .collection('usage_counters')
        .doc(periodKey);

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
          tier: entitlement.effectiveTier,
          reason:
              '${action.label} $periodType limit reached for ${entitlement.effectiveTier.publicName}.',
        );
      }

      transaction.set(docRef, {
        'uid': currentUid,
        'periodKey': periodKey,
        'periodType': periodType,
        action.usageKey: FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': snapshot.exists
            ? data['createdAt']
            : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return UagUsageGateResult(
        allowed: true,
        action: action,
        used: used + 1,
        limit: limit,
        tier: entitlement.effectiveTier,
      );
    });
  }

  Future<void> refundAction(UagBillableAction action) async {
    final currentUid = uid;
    if (currentUid == null) return;
    final entitlement = await getMyEntitlement();
    final limit = entitlement.limits.limitFor(action);
    if (limit == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(currentUid)
        .collection('usage_counters')
        .doc(_periodKeyForAction(action));
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? const <String, dynamic>{};
      final used = (data[action.usageKey] as num?)?.toInt() ?? 0;
      if (used <= 0) return;
      transaction.set(docRef, {
        action.usageKey: used - 1,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
        'referralCommissionPercent':
            entitlement.limits.referralCommissionPercent,
      }, SetOptions(merge: true));
    });

    return code;
  }

  Future<void> requestPayout({required int amountPence}) async {
    final entitlement = await getMyEntitlement();
    if (amountPence < entitlement.limits.payoutThresholdPence) {
      throw StateError(
        'Minimum payout is £${(entitlement.limits.payoutThresholdPence / 100).toStringAsFixed(2)}.',
      );
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

  String _periodKeyForAction(UagBillableAction action) =>
      UagCommercialEconomy.usesMonthlyAllowance(action)
      ? _currentMonthKey()
      : _currentWeekKey();

  String _currentMonthKey() {
    final now = DateTime.now().toUtc();
    return '${now.year}-M${now.month.toString().padLeft(2, '0')}';
  }

  String _currentWeekKey() {
    final now = DateTime.now().toUtc();
    final startOfYear = DateTime.utc(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays + 1;
    final week = ((dayOfYear - now.weekday + 10) / 7).floor();
    return '${now.year}-W${week.toString().padLeft(2, '0')}';
  }

  Future<void> setMyEntitlementTestMode(UagEntitlementTestMode mode) async {
    final currentUid = uid;
    if (currentUid == null) throw StateError('User must be signed in.');
    final userRef = _firestore.collection('users').doc(currentUid);
    final snap = await userRef.get();
    final data = snap.data() ?? <String, dynamic>{};
    if (data['isAdmin'] != true && data['isDev'] != true) {
      throw StateError('Entitlement test mode is admin/dev only.');
    }
    await userRef.set({
      'entitlementTest': {
        'mode': mode.value,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUid,
      },
    }, SetOptions(merge: true));
  }

  Future<void> grantPremiumPassForTesting(UagPremiumPassType type) async {
    final currentUid = uid;
    if (currentUid == null) throw StateError('User must be signed in.');
    final userRef = _firestore.collection('users').doc(currentUid);
    final snap = await userRef.get();
    final data = snap.data() ?? <String, dynamic>{};
    if (data['isAdmin'] != true && data['isDev'] != true) {
      throw StateError('Premium pass test grants are admin/dev only.');
    }
    final existing = UagPremiumPassEntitlement.fromMap(
      (data['premiumPass'] as Map?)?.cast<String, dynamic>(),
    );
    final now = DateTime.now().toUtc();
    await userRef.set({
      'premiumPass': {
        'type': type.value,
        'startedAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(now.add(type.duration)),
        'paidPence': type.pricePence,
        'usedDay24': existing.usedDay24 || type == UagPremiumPassType.day24,
        'usedWeek7': existing.usedWeek7 || type == UagPremiumPassType.week7,
        'source': 'admin_test',
      },
    }, SetOptions(merge: true));
  }
}
