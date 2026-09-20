import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/arc_raider_contract_models.dart';
import '../models/arc_contract_projections.dart';
import '../models/arc_hunter_verified_result.dart';
import '../services/arc_raider_blueprint_reward_service.dart';

class ArcRaiderContractsRepository {
  ArcRaiderContractsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

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

  Stream<List<ArcHunterVerifiedResult>> watchVerifiedResults({
    String? countryCode,
    String? hunterUid,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(
      'raider_verified_results',
    );
    // Raw verified records are participant-private. Public rankings must use
    // a separate aggregate projection, never expose contract/hunter joins.
    if (hunterUid != null && hunterUid != uid) {
      throw StateError('Only your own verified results are available here.');
    }
    query = query.where('hunterUid', isEqualTo: uid);
    if (countryCode != null) {
      query = query.where('countryCode', isEqualTo: countryCode.toUpperCase());
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) =>
                ArcHunterVerifiedResult.fromServerRecord(doc.id, doc.data()),
          )
          .whereType<ArcHunterVerifiedResult>()
          .toList(growable: false),
    );
  }

  Stream<List<ArcRaiderReport>> watchMyReports() => _reports
      .where('reporterUid', isEqualTo: uid)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => ArcRaiderReport.fromMap(d.data())).toList(),
      );

  Future<List<ArcContractDiscoveryItem>> discoverContracts([
    String search = '',
  ]) async {
    final data = await _verificationCall('discoverRaiderContracts', {
      'search': search,
    });
    return (data['contracts'] as List)
        .map(
          (e) => ArcContractDiscoveryItem.fromMap(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<List<ArcContractAccountCase>> accountCases() async {
    final data = await _verificationCall('raiderAccountCases', {});
    return (data['cases'] as List)
        .map(
          (e) => ArcContractAccountCase.fromMap(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<void> recordTradingBetrayal(String sessionId) async {
    await _verificationCall('recordTradingBetrayal', {'sessionId': sessionId});
  }

  Future<void> attachReportEvidence(String reportId, XFile file) async {
    final evidence = await uploadReportVideoEvidence(
      reportId: reportId,
      file: file,
    );
    await _verificationCall('attachRaiderReportEvidence', {
      'reportId': reportId,
      'storagePath': evidence.storagePath,
    });
  }

  Future<void> challengeContract(String contractId, String reason) async {
    await _verificationCall('challengeRaiderContract', {
      'contractId': contractId,
      'reason': reason,
    });
  }

  Stream<List<Map<String, dynamic>>> watchChallenges() => _db
      .collection('arc_contract_challenges')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());

  Future<Map<String, dynamic>> adminContext(String reportId) =>
      _verificationCall('raiderContractAdminContext', {'reportId': reportId});

  Future<String> reportEvidenceUrl(ArcRaiderEvidence evidence) =>
      _storage.ref(evidence.storagePath).getDownloadURL();

  Future<void> reviewChallenge(
    String contractId,
    bool overturn,
    String notes,
  ) async {
    await _verificationCall('reviewRaiderContractChallenge', {
      'contractId': contractId,
      'overturn': overturn,
      'notes': notes,
    });
  }

  Stream<List<ArcRaiderContract>> watchMyContracts() => _contracts
      .where('hunterUid', isEqualTo: uid)
      .where('targetUid', isNotEqualTo: uid)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => ArcRaiderContract.fromMap(d.data())).toList(),
      );

  Stream<List<ArcRaiderContract>> watchIssuedContracts() => _contracts
      .where('reporterUid', isEqualTo: uid)
      .where('targetUid', isNotEqualTo: uid)
      .snapshots()
      .map((snapshot) {
        final contracts = snapshot.docs
            .map(
              (doc) => ArcRaiderContract.fromMap({...doc.data(), 'id': doc.id}),
            )
            .toList();
        contracts.sort(
          (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
            a.updatedAt ?? DateTime(1970),
          ),
        );
        return contracts;
      });

  Future<ArcRaiderEvidence> uploadContractVideoEvidence({
    required String contractId,
    required XFile file,
  }) async {
    final actor = uid;
    final snapshot = await _contracts.doc(contractId).get();
    final contract = ArcRaiderContract.fromMap(snapshot.data() ?? {});
    if (contract.hunterUid != actor || !contract.canSubmitVideoEvidence) {
      throw StateError('This contract cannot receive a new clip.');
    }
    if (!file.name.toLowerCase().endsWith('.mp4')) {
      throw ArgumentError('Choose an MP4 video.');
    }
    if (await file.length() > 25 * 1024 * 1024) {
      throw ArgumentError('Video must be no larger than 25 MB.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.length < 12 ||
        bytes.length > 25 * 1024 * 1024 ||
        ascii.decode(bytes.sublist(4, 8), allowInvalid: true) != 'ftyp') {
      throw ArgumentError('Choose a valid MP4 video, up to 25 MB.');
    }
    final submissionId = const Uuid().v4();
    final path = 'contract_evidence/$contractId/$actor/$submissionId.mp4';
    await _storage
        .ref(path)
        .putData(bytes, SettableMetadata(contentType: 'video/mp4'));
    return ArcRaiderEvidence(
      id: submissionId,
      submittedByUid: actor,
      kind: 'video',
      url: '',
      storagePath: path,
    );
  }

  // Firebase callable wire protocol, using the existing HTTP dependency.
  // The server authenticates the ID token and is the sole verification writer.
  Future<Map<String, dynamic>> _verificationCall(
    String name,
    Map<String, dynamic> data,
  ) async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null || token.isEmpty) throw StateError('Sign in required.');
    final project = _db.app.options.projectId;
    final response = await http
        .post(
          Uri.https('us-central1-$project.cloudfunctions.net', '/$name'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'data': data}),
        )
        .timeout(const Duration(seconds: 60));
    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200 ||
        decoded is! Map ||
        decoded['error'] != null) {
      throw StateError(
        'The Contract service could not complete this request. Refresh and retry.',
      );
    }
    return Map<String, dynamic>.from(decoded['result'] as Map);
  }

  Future<void> reviewEvidence({
    required String contractId,
    required String submissionId,
    required bool confirmed,
    String reason = '',
  }) async {
    if (submissionId.isEmpty) {
      throw ArgumentError('No video submission to review.');
    }
    if (!confirmed && reason.trim().isEmpty) {
      throw ArgumentError('Explain why the evidence needs replacing.');
    }
    await _verificationCall('reviewRaiderContractEvidence', {
      'contractId': contractId,
      'submissionId': submissionId,
      'decision': confirmed ? 'confirm' : 'reject',
      'reason': reason.trim(),
    });
  }

  Stream<List<ArcRaiderReport>> watchModerationReports() => _reports
      .where('status', whereIn: const ['submitted', 'pendingReview'])
      .where('targetUid', isNotEqualTo: uid)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => ArcRaiderReport.fromMap(d.data())).toList(),
      );

  Stream<List<ArcRaiderContract>> watchDisputedContracts() => _contracts
      .where('status', isEqualTo: 'disputed')
      .where('targetUid', isNotEqualTo: uid)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => ArcRaiderContract.fromMap(d.data())).toList(),
      );

  String newReportId() => _reports.doc().id;

  Future<ArcRaiderEvidence> uploadReportVideoEvidence({
    required String reportId,
    required XFile file,
  }) async {
    if (reportId.trim().isEmpty) {
      throw ArgumentError('A report ID is required before evidence upload.');
    }

    final lowerName = file.name.toLowerCase();
    if (!lowerName.endsWith('.mp4')) {
      throw ArgumentError('Evidence clip must be an MP4 file.');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw ArgumentError('The selected evidence clip is empty.');
    }
    if (bytes.length > 25 * 1024 * 1024) {
      throw ArgumentError('Evidence clip must be 25 MB or smaller.');
    }

    final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final storagePath = 'conduct_evidence/$reportId/$uid/${stamp}_$safeName';
    final ref = _storage.ref(storagePath);

    await ref.putData(bytes, SettableMetadata(contentType: 'video/mp4'));
    final url = await ref.getDownloadURL();

    return ArcRaiderEvidence(
      id: '$stamp',
      submittedByUid: uid,
      kind: 'video',
      url: url,
      storagePath: storagePath,
      caption: 'Reporter evidence clip',
      createdAt: DateTime.now(),
    );
  }

  Future<String> createReport({
    String? reportId,
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
    int blueprintRewardCount = 0,
  }) async {
    final ref = reportId == null || reportId.trim().isEmpty
        ? _reports.doc()
        : _reports.doc(reportId.trim());
    final now = DateTime.now();
    var blueprintRewardPool = const <String>[];
    if (requestContract && blueprintRewardCount > 0) {
      final rewardService = ArcRaiderBlueprintRewardService(firestore: _db);
      await rewardService.validateOffer(
        creatorUid: uid,
        rewardCount: blueprintRewardCount,
      );
      blueprintRewardPool = await rewardService.snapshotDuplicateBlueprintIds(
        uid,
      );
    }
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
      blueprintRewardCount: blueprintRewardCount,
      blueprintRewardPool: blueprintRewardPool,
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
    try {
      await _notify(
        targetUid: uid,
        title: 'Report received',
        body: 'Your Rat report is private and queued for moderator review.',
        entityId: ref.id,
        type: 'conductReportReceived',
      );
    } on FirebaseException {
      // The report is already safely stored. A notification permission or
      // transient messaging failure must never make the UI report submission
      // look unsuccessful or encourage duplicate reports.
    }
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
    String targetUid = '',
  }) async {
    await _verificationCall('moderateRaiderReport', {
      'reportId': id,
      'approve': approve,
      'notes': notes,
      'targetUid': targetUid,
    });
  }

  Future<int> maxBlueprintRewardsIcanOffer() => ArcRaiderBlueprintRewardService(
    firestore: _db,
  ).maxDistinctBlueprintRewards(uid);

  Future<List<ArcRaiderBlueprintRewardCandidate>> loadEligibleBlueprintRewards(
    ArcRaiderContract contract,
  ) async {
    if (contract.hunterUid != uid) {
      return const <ArcRaiderBlueprintRewardCandidate>[];
    }
    return ArcRaiderBlueprintRewardService(firestore: _db).eligibleCandidates(
      creatorPool: contract.blueprintRewardPool,
      claimantUid: uid,
    );
  }

  Future<void> saveBlueprintRewardSelection(
    String contractId,
    Iterable<String> blueprintIds,
  ) async {
    final unique = blueprintIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final snapshot = await _contracts.doc(contractId).get();
    final contract = ArcRaiderContract.fromMap(
      snapshot.data() ?? const <String, dynamic>{},
    );
    if (contract.hunterUid != uid) {
      throw StateError(
        'Only the contract claimant can choose Blueprint rewards.',
      );
    }
    if (contract.blueprintRewardCount <= 0) {
      throw StateError('This contract does not offer Blueprint rewards.');
    }
    if (!{
      ArcRaiderContractStatus.accepted,
      ArcRaiderContractStatus.inProgress,
      ArcRaiderContractStatus.evidenceSubmitted,
      ArcRaiderContractStatus.disputed,
    }.contains(contract.status)) {
      throw StateError(
        'Blueprint rewards cannot be changed in this contract state.',
      );
    }
    if (unique.length != contract.blueprintRewardCount) {
      throw ArgumentError(
        'Choose exactly ${contract.blueprintRewardCount} Blueprint reward${contract.blueprintRewardCount == 1 ? '' : 's'}.',
      );
    }
    if (!unique.every(contract.blueprintRewardPool.contains)) {
      throw StateError(
        'A selected Blueprint is not in the creator duplicate pool.',
      );
    }
    final eligible = await loadEligibleBlueprintRewards(contract);
    final eligibleIds = eligible
        .map((candidate) => candidate.blueprintId)
        .toSet();
    if (!unique.every(eligibleIds.contains)) {
      throw StateError(
        'One or more selected Blueprints are no longer missing from your tracker.',
      );
    }
    await _contracts.doc(contractId).update({
      'blueprintRewardSelection': unique,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptContract(String id) async {
    await _verificationCall('acceptRaiderContract', {'contractId': id});
  }

  Future<void> startContract(String id) =>
      _hunterTransition(id, ArcRaiderContractStatus.inProgress);

  Future<void> submitEvidence(
    String id, {
    required List<ArcRaiderEvidence> evidence,
    String socialContentUrl = '',
  }) async {
    if (evidence.length != 1 ||
        evidence.single.kind != 'video' ||
        evidence.single.storagePath.isEmpty ||
        evidence.single.submittedByUid != uid) {
      throw ArgumentError('One uploaded contract video is required.');
    }
    await _verificationCall('submitRaiderContractEvidence', {
      'contractId': id,
      'storagePath': evidence.single.storagePath,
      'submissionId': evidence.single.id,
    });
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
    if (completed && !contract.isVerifiedComplete) {
      throw StateError(
        'Only the issuer can verify completion after video review.',
      );
    }
    if (!completed && !contract.canTransitionTo(next)) {
      throw StateError('Invalid resolution transition.');
    }
    if (completed && contract.blueprintRewardCount <= 0) return;
    if (completed && contract.blueprintRewardCount > 0) {
      final authority =
          (await _db.collection('users').doc(uid).get()).data() ??
          const <String, dynamic>{};
      if (authority['isAdmin'] != true && authority['isDev'] != true) {
        throw StateError(
          'Blueprint reward settlement requires an admin/dev moderator so both Blueprint inventories can be updated atomically.',
        );
      }
      await ArcRaiderBlueprintRewardService(
        firestore: _db,
      ).settleCompletedContract(
        contractId: id,
        moderatorUid: uid,
        resolution: resolution,
      );
    } else {
      await _contracts.doc(id).update({
        'status': next.name,
        'resolution': resolution.trim(),
        'moderatedByUid': uid,
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
