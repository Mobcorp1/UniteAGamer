import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/arc_raider_contract_models.dart';

class ArcRaiderContractsRepository {
  ArcRaiderContractsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get uid {
    final value = _auth.currentUser?.uid ?? '';
    if (value.isEmpty) {
      throw StateError('Sign in required.');
    }
    return value;
  }

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('arc_raider_reports');
  CollectionReference<Map<String, dynamic>> get _contracts =>
      _db.collection('arc_raider_contracts');

  Stream<List<ArcRaiderReport>> watchMyReports() => _reports
      .where('reporterUid', isEqualTo: uid)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => ArcRaiderReport.fromMap(d.data())).toList(),
      );

  Stream<List<ArcRaiderContract>> watchLiveContracts() => _contracts
      .where('status', isEqualTo: 'available')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => ArcRaiderContract.fromMap(d.data())).toList(),
      );

  Stream<List<ArcRaiderContract>> watchMyContracts() => _contracts
      .where('hunterUid', isEqualTo: uid)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => ArcRaiderContract.fromMap(d.data())).toList(),
      );

  Stream<List<ArcRaiderReport>> watchModerationReports() => _reports
      .where('status', whereIn: const ['submitted', 'pendingReview'])
      .orderBy('submittedAt')
      .snapshots()
      .map(
        (s) => s.docs.map((d) => ArcRaiderReport.fromMap(d.data())).toList(),
      );

  Stream<List<ArcRaiderContract>> watchDisputedContracts() => _contracts
      .where('status', isEqualTo: 'disputed')
      .orderBy('updatedAt')
      .snapshots()
      .map(
        (s) => s.docs.map((d) => ArcRaiderContract.fromMap(d.data())).toList(),
      );

  Future<String> createReport({
    required String targetDisplayName,
    String targetUid = '',
    String targetGameIdentity = '',
    required ArcRaiderReportCategory category,
    required String description,
    String encounterContext = '',
    required String mapId,
    required String mapDisplayName,
    required double locationX,
    required double locationY,
    String locationLabel = '',
    String nearestPoiId = '',
    String nearestPoiName = '',
    bool atExtraction = false,
    String extractionId = '',
    String extractionName = '',
    String rattingSubtype = '',
    required String serverRegion,
    required DateTime incidentAt,
    ArcRaiderRepeatBehaviour repeatBehaviour = ArcRaiderRepeatBehaviour.no,
    int repeatCount = 1,
    String eventContext = '',
    String socialContentUrl = '',
    List<ArcRaiderEvidence> evidence = const [],
    bool requestContract = false,
    List<ArcRaiderRewardItem> rewardItems = const [],
  }) async {
    final ref = _reports.doc();
    final now = DateTime.now();
    final profile = (await _db.collection('users').doc(uid).get()).data() ?? {};
    final reputation =
        (profile['reputationScore'] as num?)?.toInt() ??
        (profile['traderReputation'] as num?)?.toInt() ??
        0;

    final report = ArcRaiderReport(
      id: ref.id,
      reporterUid: uid,
      targetUid: targetUid.trim(),
      targetDisplayName: targetDisplayName.trim(),
      targetGameIdentity: targetGameIdentity.trim(),
      category: category,
      description: description.trim(),
      encounterContext: encounterContext.trim(),
      mapId: mapId,
      mapDisplayName: mapDisplayName,
      locationLabel: locationLabel,
      locationX: locationX,
      locationY: locationY,
      nearestPoiId: nearestPoiId,
      nearestPoiName: nearestPoiName,
      atExtraction: atExtraction,
      extractionId: extractionId,
      extractionName: extractionName,
      rattingSubtype: rattingSubtype,
      serverRegion: serverRegion,
      incidentAt: incidentAt,
      repeatBehaviour: repeatBehaviour,
      repeatCount: repeatCount < 1 ? 1 : repeatCount,
      eventContext: eventContext.trim(),
      reporterReputationSnapshot: reputation,
      socialContentUrl: socialContentUrl.trim(),
      evidence: evidence,
      requestContract: requestContract,
      rewardItems: rewardItems,
      status: ArcRaiderReportStatus.submitted,
      createdAt: now,
      updatedAt: now,
      submittedAt: now,
    );
    if (!report.canSubmit) {
      throw ArgumentError(
        'Complete all required incident questions before submitting.',
      );
    }

    await ref.set({
      ...report.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'submittedAt': FieldValue.serverTimestamp(),
    });
    await _notify(
      targetUid: uid,
      title: 'Report received',
      body: 'Your Raider report is private and queued for moderator review.',
      entityId: ref.id,
      type: 'conductReportReceived',
    );
    return ref.id;
  }

  Future<void> withdrawReport(String id) async {
    final snapshot = await _reports.doc(id).get();
    final report = ArcRaiderReport.fromMap(snapshot.data() ?? {});
    if (report.reporterUid != uid || !report.canWithdraw) {
      throw StateError('Report cannot be withdrawn.');
    }
    await _reports.doc(id).update({
      'status': 'withdrawn',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> moderateReport(
    String id, {
    required bool approve,
    required String notes,
  }) async {
    await _requireModerator();
    final moderator = uid;
    String reporterUid = '';
    String? contractId;

    await _db.runTransaction((tx) async {
      final reportRef = _reports.doc(id);
      final snapshot = await tx.get(reportRef);
      if (!snapshot.exists) {
        throw StateError('Report not found.');
      }
      final report = ArcRaiderReport.fromMap(snapshot.data()!);
      reporterUid = report.reporterUid;
      if (!{
        ArcRaiderReportStatus.submitted,
        ArcRaiderReportStatus.pendingReview,
      }.contains(report.status)) {
        throw StateError('Invalid report transition.');
      }

      tx.update(reportRef, {
        'status': approve ? 'approved' : 'rejected',
        'moderationNotes': notes.trim(),
        'moderatedByUid': moderator,
        'moderatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (approve && report.requestContract) {
        final contractRef = _contracts.doc();
        contractId = contractRef.id;
        final rewardSummary = report.rewardItems
            .map((e) => '${e.quantity}× ${e.name}')
            .join(' • ');
        tx.set(contractRef, {
          'id': contractRef.id,
          'reportId': id,
          'targetUid': report.targetUid,
          'targetDisplayName': report.targetDisplayName,
          'reporterUid': report.reporterUid,
          'hunterUid': '',
          'status': 'available',
          'rewardItems': report.rewardItems.map((e) => e.toMap()).toList(),
          'rewardSummary': rewardSummary,
          'reputationReward': 10,
          'evidenceRequirements':
              'Provide clear in-app evidence that identifies the encounter and outcome.',
          'evidence': <Map<String, dynamic>>[],
          'resolution': '',
          'moderationNotes': '',
          'moderatedByUid': moderator,
          'socialContentUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 14)),
          ),
        });
      }
    });

    await _notify(
      targetUid: reporterUid,
      title: approve ? 'Report approved' : 'Report reviewed',
      body: approve
          ? contractId == null
                ? 'Your report was approved for Rat Activity intelligence.'
                : 'Your report was approved and your Raider Contract is now live.'
          : 'Your report was not approved. Review the moderation notes.',
      entityId: contractId ?? id,
      type: 'conductReportOutcome',
    );
  }

  Future<void> acceptContract(String id) async {
    _requireSignedIn();
    String reporterUid = '';
    await _db.runTransaction((tx) async {
      final ref = _contracts.doc(id);
      final snapshot = await tx.get(ref);
      final contract = ArcRaiderContract.fromMap(snapshot.data() ?? {});
      reporterUid = contract.reporterUid;
      if (!contract.canAccept ||
          contract.reporterUid == uid ||
          contract.targetUid == uid) {
        throw StateError('This contract cannot be accepted by this account.');
      }
      tx.update(ref, {
        'status': 'accepted',
        'hunterUid': uid,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    await _notify(
      targetUid: reporterUid,
      title: 'Raider Contract accepted',
      body: 'A hunter has accepted your Raider Contract.',
      entityId: id,
      type: 'operations',
    );
  }

  Future<void> startContract(String id) =>
      _hunterTransition(id, ArcRaiderContractStatus.inProgress);

  Future<void> submitEvidence(
    String id, {
    required List<ArcRaiderEvidence> evidence,
    String socialContentUrl = '',
  }) async {
    if (evidence.isEmpty) {
      throw ArgumentError('At least one evidence item is required.');
    }
    final snapshot = await _contracts.doc(id).get();
    final contract = ArcRaiderContract.fromMap(snapshot.data() ?? {});
    if (contract.hunterUid != uid ||
        !contract.canTransitionTo(ArcRaiderContractStatus.evidenceSubmitted)) {
      throw StateError('Evidence cannot be submitted.');
    }
    await _contracts.doc(id).update({
      'status': 'evidenceSubmitted',
      'evidence': evidence.map((e) => e.toMap()).toList(),
      'socialContentUrl': socialContentUrl.trim(),
      'evidenceSubmittedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _notify(
      targetUid: contract.reporterUid,
      title: 'Contract evidence submitted',
      body: 'Evidence has been submitted for your Raider Contract.',
      entityId: id,
      type: 'operations',
    );
  }

  Future<void> disputeContract(String id, String reason) async {
    final snapshot = await _contracts.doc(id).get();
    final contract = ArcRaiderContract.fromMap(snapshot.data() ?? {});
    if (uid != contract.reporterUid && uid != contract.hunterUid) {
      throw StateError('Only contract participants can dispute.');
    }
    if (!contract.canTransitionTo(ArcRaiderContractStatus.disputed)) {
      throw StateError('Invalid contract transition.');
    }
    await _contracts.doc(id).update({
      'status': 'disputed',
      'resolution': reason.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final otherUid = uid == contract.reporterUid
        ? contract.hunterUid
        : contract.reporterUid;
    await _notify(
      targetUid: otherUid,
      title: 'Raider Contract disputed',
      body: 'A contract participant requested moderator review.',
      entityId: id,
      type: 'operations',
    );
  }

  Future<void> resolveContract(
    String id, {
    required bool completed,
    required String resolution,
  }) async {
    await _requireModerator();
    final snapshot = await _contracts.doc(id).get();
    final contract = ArcRaiderContract.fromMap(snapshot.data() ?? {});
    final next = completed
        ? ArcRaiderContractStatus.completed
        : ArcRaiderContractStatus.rejected;
    if (!contract.canTransitionTo(next)) {
      throw StateError('Invalid resolution transition.');
    }
    await _contracts.doc(id).update({
      'status': next.name,
      'resolution': resolution.trim(),
      'moderatedByUid': uid,
      'resolvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (completed && contract.hunterUid.isNotEmpty) {
      await _db.collection('users').doc(contract.hunterUid).set({
        'raiderContractStats': {
          'completed': FieldValue.increment(1),
          'reputationEarned': FieldValue.increment(contract.reputationReward),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    }
    await _notify(
      targetUid: contract.hunterUid,
      title: completed
          ? 'Raider Contract completed'
          : 'Raider Contract rejected',
      body: resolution.trim().isEmpty
          ? 'The contract has been resolved.'
          : resolution.trim(),
      entityId: id,
      type: completed ? 'reward' : 'operations',
    );
    await _notify(
      targetUid: contract.reporterUid,
      title: completed
          ? 'Contract completion approved'
          : 'Contract evidence rejected',
      body: resolution.trim().isEmpty
          ? 'The contract has been resolved.'
          : resolution.trim(),
      entityId: id,
      type: 'operations',
    );
  }

  Future<void> _hunterTransition(
    String id,
    ArcRaiderContractStatus next,
  ) async {
    final snapshot = await _contracts.doc(id).get();
    final contract = ArcRaiderContract.fromMap(snapshot.data() ?? {});
    if (contract.hunterUid != uid || !contract.canTransitionTo(next)) {
      throw StateError('Invalid contract transition.');
    }
    await _contracts.doc(id).update({
      'status': next.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _requireSignedIn() {
    if ((_auth.currentUser?.uid ?? '').isEmpty) {
      throw StateError('Sign in required.');
    }
  }

  Future<void> _requireModerator() async {
    final data = (await _db.collection('users').doc(uid).get()).data() ?? {};
    if (data['isAdmin'] != true &&
        data['isDev'] != true &&
        data['isModerator'] != true) {
      throw StateError('Moderator access required.');
    }
  }

  Future<void> _notify({
    required String targetUid,
    required String title,
    required String body,
    required String entityId,
    required String type,
  }) async {
    if (targetUid.isEmpty) {
      return;
    }
    final ref = _db.collection('trading_notifications').doc();
    await ref.set({
      'id': ref.id,
      'targetUid': targetUid,
      'actorUid': uid,
      'title': title,
      'body': body,
      'type': type,
      'listingId': '',
      'offerId': '',
      'sessionId': '',
      'route': '/raider-contracts',
      'entityId': entityId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
