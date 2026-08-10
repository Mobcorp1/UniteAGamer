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

  Stream<List<ArcRaiderReport>> watchMyReports() {
    return _reports
        .where('reporterUid', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ArcRaiderReport.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<ArcRaiderContract>> watchLiveContracts() {
    return _contracts
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ArcRaiderContract.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<ArcRaiderContract>> watchMyContracts() {
    return _contracts
        .where('hunterUid', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ArcRaiderContract.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<ArcRaiderReport>> watchModerationReports() {
    return _reports
        .where('status', whereIn: const ['submitted', 'pendingReview'])
        .orderBy('submittedAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ArcRaiderReport.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<ArcRaiderContract>> watchDisputedContracts() {
    return _contracts
        .where('status', isEqualTo: 'disputed')
        .orderBy('updatedAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ArcRaiderContract.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<String> createReport({
    required String targetDisplayName,
    String targetUid = '',
    String targetGameIdentity = '',
    required ArcRaiderReportCategory category,
    required String description,
    String encounterContext = '',
    String mapId = '',
    String eventContext = '',
    String socialContentUrl = '',
    List<ArcRaiderEvidence> evidence = const [],
  }) async {
    final ref = _reports.doc();
    final now = DateTime.now();
    final report = ArcRaiderReport(
      id: ref.id,
      reporterUid: uid,
      targetUid: targetUid.trim(),
      targetDisplayName: targetDisplayName.trim(),
      targetGameIdentity: targetGameIdentity.trim(),
      category: category,
      description: description.trim(),
      encounterContext: encounterContext.trim(),
      mapId: mapId.trim(),
      eventContext: eventContext.trim(),
      socialContentUrl: socialContentUrl.trim(),
      evidence: evidence,
      status: ArcRaiderReportStatus.submitted,
      createdAt: now,
      updatedAt: now,
      submittedAt: now,
    );

    if (!report.canSubmit) {
      throw ArgumentError(
        'Report requires a target and at least 20 characters of detail.',
      );
    }

    await ref.set({
      ...report.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'submittedAt': FieldValue.serverTimestamp(),
    });
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

    await _db.runTransaction((transaction) async {
      final reportRef = _reports.doc(id);
      final snapshot = await transaction.get(reportRef);
      if (!snapshot.exists) {
        throw StateError('Report not found.');
      }

      final report = ArcRaiderReport.fromMap(snapshot.data()!);
      if (!{
        ArcRaiderReportStatus.submitted,
        ArcRaiderReportStatus.pendingReview,
      }.contains(report.status)) {
        throw StateError('Invalid report transition.');
      }

      transaction.update(reportRef, {
        'status': approve ? 'approved' : 'rejected',
        'moderationNotes': notes.trim(),
        'moderatedByUid': moderator,
        'moderatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (approve) {
        final contractRef = _contracts.doc();
        transaction.set(contractRef, {
          'id': contractRef.id,
          'reportId': id,
          'targetUid': report.targetUid,
          'targetDisplayName': report.targetDisplayName,
          'reporterUid': report.reporterUid,
          'hunterUid': '',
          'status': 'available',
          'rewardSummary': 'Community reputation',
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

    final reportSnapshot = await _reports.doc(id).get();
    final reporterUid = reportSnapshot.data()?['reporterUid']?.toString() ?? '';
    await _notify(
      targetUid: reporterUid,
      title: approve ? 'Report approved' : 'Report reviewed',
      body: approve
          ? 'Your report was approved and a Raider Contract has been created.'
          : 'Your report was not approved. Review the moderation notes in Report a Raider.',
      entityId: id,
      type: 'conductReportOutcome',
    );
  }

  Future<void> acceptContract(String id) async {
    _requireSignedIn();
    await _db.runTransaction((transaction) async {
      final contractRef = _contracts.doc(id);
      final snapshot = await transaction.get(contractRef);
      final contract = ArcRaiderContract.fromMap(snapshot.data() ?? {});
      if (!contract.canAccept ||
          contract.reporterUid == uid ||
          contract.targetUid == uid) {
        throw StateError('This contract cannot be accepted by this account.');
      }
      transaction.update(contractRef, {
        'status': 'accepted',
        'hunterUid': uid,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> startContract(String id) {
    return _hunterTransition(id, ArcRaiderContractStatus.inProgress);
  }

  Future<void> submitEvidence(
    String id, {
    required List<ArcRaiderEvidence> evidence,
    String socialContentUrl = '',
  }) async {
    if (evidence.isEmpty) {
      throw ArgumentError('At least one in-app evidence item is required.');
    }

    final snapshot = await _contracts.doc(id).get();
    final contract = ArcRaiderContract.fromMap(snapshot.data() ?? {});
    if (contract.hunterUid != uid ||
        !contract.canTransitionTo(ArcRaiderContractStatus.evidenceSubmitted)) {
      throw StateError('Evidence cannot be submitted.');
    }

    await _contracts.doc(id).update({
      'status': 'evidenceSubmitted',
      'evidence': evidence.map((item) => item.toMap()).toList(),
      'socialContentUrl': socialContentUrl.trim(),
      'evidenceSubmittedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notify(
      targetUid: contract.reporterUid,
      title: 'Contract evidence submitted',
      body:
          'Evidence has been submitted for a Raider Contract linked to your report.',
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
    final currentUid = uid;
    final data =
        (await _db.collection('users').doc(currentUid).get()).data() ?? {};
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
