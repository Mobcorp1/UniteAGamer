import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/uag_creator_commission_pipeline_models.dart';

class UagCreatorCommissionPipelineRepository {
  UagCreatorCommissionPipelineRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _ledger(String creatorUid) =>
      _firestore
          .collection('uag_creator_commission_ledgers')
          .doc(creatorUid)
          .collection('entries');

  DocumentReference<Map<String, dynamic>> _dashboard(String creatorUid) =>
      _firestore.collection('uag_creator_dashboard_aggregates').doc(creatorUid);

  DocumentReference<Map<String, dynamic>> _attribution(String referredUid) =>
      _firestore
          .collection('users')
          .doc(referredUid)
          .collection('monetisation_usage')
          .doc('creator_attribution');

  Stream<List<UagCreatorCommissionLedgerView>> watchMyCommissionLifecycle({
    int limit = 100,
  }) {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(const <UagCreatorCommissionLedgerView>[]);
    }
    return _ledger(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => UagCreatorCommissionLedgerView.fromMap(
                  <String, dynamic>{...doc.data(), 'id': doc.id},
                ),
              )
              .toList(growable: false),
        );
  }

  Future<UagCreatorCommissionProcessResult> processValidatedBillingEvent({
    required UagCreatorValidatedBillingEvent event,
  }) async {
    if (currentUid == null) {
      throw StateError('Sign in before processing Creator billing events.');
    }
    if (event.id.trim().isEmpty ||
        event.creatorUid.trim().isEmpty ||
        event.referredUid.trim().isEmpty ||
        event.subscriptionId.trim().isEmpty) {
      throw StateError('Billing event identity is incomplete.');
    }
    if (event.creatorUid == event.referredUid) {
      throw StateError('Self-referrals cannot generate Creator commission.');
    }

    final ledgerRef = _ledger(event.creatorUid).doc(event.id);
    final dashboardRef = _dashboard(event.creatorUid);
    final attributionRef = _attribution(event.referredUid);
    final now = DateTime.now().toUtc();
    final lifecycle = UagCreatorCommissionLifecyclePolicy.lifecycleFor(
      eventType: event.eventType,
      occurredAt: event.occurredAt.toUtc(),
      now: now,
    );

    return _firestore.runTransaction((transaction) async {
      final existingLedger = await transaction.get(ledgerRef);
      if (existingLedger.exists) {
        return UagCreatorCommissionProcessResult(
          ledgerId: ledgerRef.id,
          created: false,
          lifecycleStatus: UagCreatorCommissionLifecycleStatus.values
              .firstWhere(
                (status) =>
                    status.name ==
                    existingLedger.data()?['lifecycleStatus']?.toString(),
                orElse: () =>
                    UagCreatorCommissionLifecycleStatus.pendingValidation,
              ),
        );
      }

      final attribution = await transaction.get(attributionRef);
      if (!attribution.exists) {
        throw StateError(
          'No Creator attribution exists for the referred account.',
        );
      }
      final attributionData = attribution.data() ?? const <String, dynamic>{};
      final attributedCreator =
          attributionData['creatorUid']?.toString().trim() ?? '';
      if (attributedCreator != event.creatorUid) {
        throw StateError(
          'Billing event creator does not match the referred account attribution.',
        );
      }
      final attributionStatus =
          attributionData['status']?.toString().trim() ?? '';
      if (attributionStatus != 'validated' &&
          attributionStatus != 'validated_paid' &&
          attributionStatus != 'pending_validation') {
        throw StateError('Creator attribution is not in a processable state.');
      }

      final commission = event.isPositiveRevenueEvent
          ? event.calculatedCommissionPence
          : 0;

      transaction.set(ledgerRef, <String, dynamic>{
        ...event.toMap(),
        'lifecycleStatus': lifecycle.name,
        'commissionPence': commission,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final attributionPatch = <String, dynamic>{
        'status': event.isPositiveRevenueEvent
            ? 'validated_paid'
            : attributionStatus,
        'lastBillingEventId': event.id,
        'lastBillingEventType': event.eventType.name,
        'lastBillingEventAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (event.eventType == UagCreatorBillingEventType.cancellation) {
        attributionPatch['subscriptionStatus'] = 'cancelled';
      } else if (event.eventType == UagCreatorBillingEventType.refund) {
        attributionPatch['subscriptionStatus'] = 'refunded';
      } else if (event.eventType == UagCreatorBillingEventType.chargeback) {
        attributionPatch['subscriptionStatus'] = 'chargeback';
      } else {
        attributionPatch['subscriptionStatus'] = 'active';
      }
      transaction.set(
        attributionRef,
        attributionPatch,
        SetOptions(merge: true),
      );

      if (commission > 0) {
        transaction.set(dashboardRef, <String, dynamic>{
          'pendingCommissionPence': FieldValue.increment(commission),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (event.eventType == UagCreatorBillingEventType.subscriptionStarted) {
        final tier = event.planTier.trim().toLowerCase();
        transaction.set(dashboardRef, <String, dynamic>{
          'paidConversions': FieldValue.increment(1),
          if (tier == 'essential')
            'essentialSubscribers': FieldValue.increment(1),
          if (tier == 'premium') 'premiumSubscribers': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (event.eventType == UagCreatorBillingEventType.cancellation) {
        transaction.set(dashboardRef, <String, dynamic>{
          'cancelledSubscriptions': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return UagCreatorCommissionProcessResult(
        ledgerId: ledgerRef.id,
        created: true,
        lifecycleStatus: lifecycle,
      );
    });
  }

  Future<int> releaseMaturedCommission({
    required String creatorUid,
    DateTime? now,
    int limit = 200,
  }) async {
    final clock = (now ?? DateTime.now()).toUtc();
    final snapshot = await _ledger(creatorUid)
        .where(
          'lifecycleStatus',
          isEqualTo: UagCreatorCommissionLifecycleStatus.pendingValidation.name,
        )
        .limit(limit)
        .get();

    var released = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final payableAtIso = data['payableAtIso']?.toString() ?? '';
      final payableAt = DateTime.tryParse(payableAtIso)?.toUtc();
      if (payableAt == null || clock.isBefore(payableAt)) {
        continue;
      }
      final amount = data['commissionPence'] is num
          ? (data['commissionPence'] as num).toInt()
          : 0;

      await _firestore.runTransaction((transaction) async {
        final fresh = await transaction.get(doc.reference);
        if (!fresh.exists ||
            fresh.data()?['lifecycleStatus'] !=
                UagCreatorCommissionLifecycleStatus.pendingValidation.name) {
          return;
        }
        transaction.update(doc.reference, <String, dynamic>{
          'lifecycleStatus': UagCreatorCommissionLifecycleStatus.payable.name,
          'qualifiedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(_dashboard(creatorUid), <String, dynamic>{
          'pendingCommissionPence': FieldValue.increment(-amount),
          'approvedCommissionPence': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
      released += 1;
    }
    return released;
  }

  Future<void> reverseCommissionForBillingEvent({
    required String creatorUid,
    required String originalBillingEventId,
    required UagCreatorBillingEventType reversalType,
    required String reason,
  }) async {
    if (reversalType != UagCreatorBillingEventType.refund &&
        reversalType != UagCreatorBillingEventType.chargeback) {
      throw StateError('Only refunds and chargebacks reverse commission.');
    }

    final originalRef = _ledger(creatorUid).doc(originalBillingEventId);
    await _firestore.runTransaction((transaction) async {
      final original = await transaction.get(originalRef);
      if (!original.exists) {
        throw StateError('Original Creator commission event was not found.');
      }
      final data = original.data() ?? const <String, dynamic>{};
      final lifecycle = data['lifecycleStatus']?.toString() ?? '';
      if (lifecycle == UagCreatorCommissionLifecycleStatus.reversed.name) {
        return;
      }

      final amount = data['commissionPence'] is num
          ? (data['commissionPence'] as num).toInt()
          : 0;
      if (amount <= 0) {
        transaction.update(originalRef, <String, dynamic>{
          'lifecycleStatus': UagCreatorCommissionLifecycleStatus.reversed.name,
          'reversalType': reversalType.name,
          'reversalReason': reason.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      final dashboardPatch = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (lifecycle ==
          UagCreatorCommissionLifecycleStatus.pendingValidation.name) {
        dashboardPatch['pendingCommissionPence'] = FieldValue.increment(
          -amount,
        );
      } else if (lifecycle ==
          UagCreatorCommissionLifecycleStatus.payable.name) {
        dashboardPatch['approvedCommissionPence'] = FieldValue.increment(
          -amount,
        );
        dashboardPatch['clawbackPence'] = FieldValue.increment(amount);
      } else if (lifecycle == UagCreatorCommissionLifecycleStatus.paid.name) {
        dashboardPatch['clawbackPence'] = FieldValue.increment(amount);
      }

      transaction.update(originalRef, <String, dynamic>{
        'lifecycleStatus': UagCreatorCommissionLifecycleStatus.reversed.name,
        'reversalType': reversalType.name,
        'reversalReason': reason.trim(),
        'reversedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(
        _dashboard(creatorUid),
        dashboardPatch,
        SetOptions(merge: true),
      );
    });
  }

  Future<void> markCommissionPaid({
    required String creatorUid,
    required String ledgerId,
    String payoutReference = '',
  }) async {
    final ref = _ledger(creatorUid).doc(ledgerId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) {
        throw StateError('Creator commission ledger entry was not found.');
      }
      final data = snapshot.data() ?? const <String, dynamic>{};
      if (data['lifecycleStatus'] ==
          UagCreatorCommissionLifecycleStatus.paid.name) {
        return;
      }
      if (data['lifecycleStatus'] !=
          UagCreatorCommissionLifecycleStatus.payable.name) {
        throw StateError('Only payable commission can be marked paid.');
      }
      final amount = data['commissionPence'] is num
          ? (data['commissionPence'] as num).toInt()
          : 0;
      transaction.update(ref, <String, dynamic>{
        'lifecycleStatus': UagCreatorCommissionLifecycleStatus.paid.name,
        'payoutReference': payoutReference.trim(),
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(_dashboard(creatorUid), <String, dynamic>{
        'approvedCommissionPence': FieldValue.increment(-amount),
        'paidCommissionPence': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}

class UagCreatorCommissionProcessResult {
  const UagCreatorCommissionProcessResult({
    required this.ledgerId,
    required this.created,
    required this.lifecycleStatus,
  });

  final String ledgerId;
  final bool created;
  final UagCreatorCommissionLifecycleStatus lifecycleStatus;
}
