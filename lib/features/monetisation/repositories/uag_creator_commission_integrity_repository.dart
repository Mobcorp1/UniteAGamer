import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/uag_creator_commission_pipeline_models.dart';
import '../models/uag_creator_commission_rate_policy.dart';

class UagCreatorCommissionIntegrityRepository {
  UagCreatorCommissionIntegrityRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _ledger(String creatorUid) =>
      _firestore
          .collection('uag_creator_commission_ledgers')
          .doc(creatorUid)
          .collection('entries');

  DocumentReference<Map<String, dynamic>> _dashboard(String creatorUid) =>
      _firestore.collection('uag_creator_dashboard_aggregates').doc(creatorUid);

  DocumentReference<Map<String, dynamic>> get _growth =>
      _firestore.collection('app_config').doc('community_growth');

  Future<double> authoritativeCommissionRate(String creatorUid) async {
    final results = await Future.wait([
      _dashboard(creatorUid).get(),
      _growth.get(),
    ]);
    final dashboard = results[0].data() ?? const <String, dynamic>{};
    final growth = results[1].data() ?? const <String, dynamic>{};
    final points =
        (dashboard['creatorPoints'] as num?)?.toDouble() ??
        (dashboard['points'] as num?)?.toDouble() ??
        0;
    final qualifiedUsers =
        (growth['qualifiedActiveUsers'] as num?)?.toInt() ?? 0;
    return UagCreatorCommissionRatePolicy.effectiveRatePercent(
      points: points,
      qualifiedActiveUsers: qualifiedUsers,
    );
  }

  Future<Map<String, int>> reconcileCommissionDashboard(
    String creatorUid,
  ) async {
    final snapshot = await _ledger(creatorUid).get();

    var pending = 0;
    var approved = 0;
    var paid = 0;
    var clawback = 0;
    var paidConversions = 0;
    var cancellations = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final amount = (data['commissionPence'] as num?)?.toInt() ?? 0;
      final status = data['lifecycleStatus']?.toString() ?? '';
      final eventType = data['eventType']?.toString() ?? '';

      if (status ==
          UagCreatorCommissionLifecycleStatus.pendingValidation.name) {
        pending += amount;
      } else if (status == UagCreatorCommissionLifecycleStatus.payable.name) {
        approved += amount;
      } else if (status == UagCreatorCommissionLifecycleStatus.paid.name) {
        paid += amount;
      } else if (status == UagCreatorCommissionLifecycleStatus.reversed.name) {
        if (data['reversedFromStatus'] ==
                UagCreatorCommissionLifecycleStatus.payable.name ||
            data['reversedFromStatus'] ==
                UagCreatorCommissionLifecycleStatus.paid.name) {
          clawback += amount;
        }
      }

      if (eventType == UagCreatorBillingEventType.subscriptionStarted.name &&
          status != UagCreatorCommissionLifecycleStatus.reversed.name) {
        paidConversions += 1;
      }
      if (eventType == UagCreatorBillingEventType.cancellation.name) {
        cancellations += 1;
      }
    }

    final values = <String, int>{
      'pendingCommissionPence': pending,
      'approvedCommissionPence': approved,
      'paidCommissionPence': paid,
      'clawbackPence': clawback,
      'paidConversions': paidConversions,
      'cancelledSubscriptions': cancellations,
    };

    await _dashboard(creatorUid).set(<String, dynamic>{
      ...values,
      'lastReconciledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return values;
  }

  Future<void> reverseOriginal({
    required String creatorUid,
    required String originalBillingEventId,
    required UagCreatorBillingEventType reversalType,
    required String reason,
  }) async {
    if (reversalType != UagCreatorBillingEventType.refund &&
        reversalType != UagCreatorBillingEventType.chargeback) {
      throw StateError('Only refunds and chargebacks can reverse commission.');
    }
    if (originalBillingEventId.trim().isEmpty) {
      throw StateError('Original billing event ID is required.');
    }

    final originalRef = _ledger(creatorUid).doc(originalBillingEventId.trim());
    await _firestore.runTransaction((transaction) async {
      final original = await transaction.get(originalRef);
      if (!original.exists) {
        throw StateError('Original Creator commission event was not found.');
      }
      final data = original.data() ?? const <String, dynamic>{};
      final currentStatus = data['lifecycleStatus']?.toString() ?? '';
      if (currentStatus == UagCreatorCommissionLifecycleStatus.reversed.name) {
        return;
      }
      transaction.update(originalRef, <String, dynamic>{
        'reversedFromStatus': currentStatus,
        'lifecycleStatus': UagCreatorCommissionLifecycleStatus.reversed.name,
        'reversalType': reversalType.name,
        'reversalReason': reason.trim(),
        'reversedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await reconcileCommissionDashboard(creatorUid);
  }

  Future<int> releaseMaturedSafely(String creatorUid) async {
    final now = DateTime.now().toUtc();
    final snapshot = await _ledger(creatorUid)
        .where(
          'lifecycleStatus',
          isEqualTo: UagCreatorCommissionLifecycleStatus.pendingValidation.name,
        )
        .get();

    var changed = 0;
    for (final doc in snapshot.docs) {
      final payableAt = DateTime.tryParse(
        doc.data()['payableAtIso']?.toString() ?? '',
      )?.toUtc();
      if (payableAt == null || payableAt.isAfter(now)) continue;

      final didChange = await _firestore.runTransaction((transaction) async {
        final fresh = await transaction.get(doc.reference);
        if (!fresh.exists ||
            fresh.data()?['lifecycleStatus'] !=
                UagCreatorCommissionLifecycleStatus.pendingValidation.name) {
          return false;
        }
        transaction.update(doc.reference, <String, dynamic>{
          'lifecycleStatus': UagCreatorCommissionLifecycleStatus.payable.name,
          'qualifiedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
      if (didChange) changed += 1;
    }

    if (changed > 0) {
      await reconcileCommissionDashboard(creatorUid);
    }
    return changed;
  }

  Future<void> markPayableEntryPaid({
    required String creatorUid,
    required String ledgerId,
    required String payoutReference,
  }) async {
    if (payoutReference.trim().isEmpty) {
      throw StateError('Payout reference is required.');
    }
    final ref = _ledger(creatorUid).doc(ledgerId.trim());
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) {
        throw StateError('Commission entry was not found.');
      }
      if (snapshot.data()?['lifecycleStatus'] ==
          UagCreatorCommissionLifecycleStatus.paid.name) {
        return;
      }
      if (snapshot.data()?['lifecycleStatus'] !=
          UagCreatorCommissionLifecycleStatus.payable.name) {
        throw StateError('Only payable commission can be marked paid.');
      }
      transaction.update(ref, <String, dynamic>{
        'lifecycleStatus': UagCreatorCommissionLifecycleStatus.paid.name,
        'payoutReference': payoutReference.trim(),
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    await reconcileCommissionDashboard(creatorUid);
  }
}
