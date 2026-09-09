import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_application_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_programme_models.dart';

class UagCreatorFrontDoorRepository {
  UagCreatorFrontDoorRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection('uag_creator_applications');

  CollectionReference<Map<String, dynamic>> get _campaignCodes =>
      _firestore.collection('uag_creator_campaign_code_requests');

  String? get currentUid => _auth.currentUser?.uid;

  Stream<UagCreatorProgrammeApplication?> watchMyApplication() {
    final uid = currentUid;
    if (uid == null) {
      return Stream.value(null);
    }
    return _applications.where('uid', isEqualTo: uid).limit(20).snapshots().map(
      (snapshot) {
        if (snapshot.docs.isEmpty) {
          return null;
        }
        final docs = snapshot.docs.toList(growable: false)
          ..sort((a, b) {
            final aData = a.data();
            final bData = b.data();
            final aTime = aData['createdAt'];
            final bTime = bData['createdAt'];
            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }
            return 0;
          });
        return UagCreatorProgrammeApplication.fromMap(<String, dynamic>{
          ...docs.first.data(),
          'id': docs.first.id,
        });
      },
    );
  }

  Stream<List<UagCreatorProgrammeApplication>> watchApplicationsForAdmin({
    int limit = 100,
  }) {
    return _applications.limit(limit).snapshots().map((snapshot) {
      final applications = snapshot.docs
          .map(
            (doc) => UagCreatorProgrammeApplication.fromMap(<String, dynamic>{
              ...doc.data(),
              'id': doc.id,
            }),
          )
          .toList(growable: true);
      applications.sort((a, b) {
        int priority(UagCreatorApplicationStatus status) {
          switch (status) {
            case UagCreatorApplicationStatus.pending:
              return 0;
            case UagCreatorApplicationStatus.approved:
              return 1;
            case UagCreatorApplicationStatus.suspended:
              return 2;
            case UagCreatorApplicationStatus.rejected:
              return 3;
            case UagCreatorApplicationStatus.closed:
              return 4;
            case UagCreatorApplicationStatus.notApplied:
              return 5;
          }
        }

        final byStatus = priority(a.status).compareTo(priority(b.status));
        if (byStatus != 0) {
          return byStatus;
        }
        return b.createdAtIso.compareTo(a.createdAtIso);
      });
      return applications;
    });
  }

  Future<String> submitApplication({
    required String displayName,
    required List<String> platforms,
    required Map<String, String> socialHandles,
    required bool termsAccepted,
    int? audienceSize,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('Sign in before applying to the Creator Programme.');
    }

    const policy = UagCreatorApplicationPolicy();
    final validation = policy.validate(
      displayName: displayName,
      platforms: platforms,
      socialHandles: socialHandles,
      termsAccepted: termsAccepted,
    );
    if (!validation.valid) {
      throw StateError(validation.errors.join(' '));
    }

    final existing = await _applications
        .where('uid', isEqualTo: uid)
        .limit(20)
        .get();
    final active = existing.docs.any((doc) {
      final status = UagCreatorApplicationStatusX.fromWire(
        doc.data()['status']?.toString(),
      );
      return status == UagCreatorApplicationStatus.pending ||
          status == UagCreatorApplicationStatus.approved;
    });
    if (active) {
      throw StateError(
        'You already have an active Creator Programme application.',
      );
    }

    final doc = _applications.doc();
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final application = UagCreatorProgrammeApplication(
      id: doc.id,
      uid: uid,
      displayName: displayName.trim(),
      platforms: platforms
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(growable: false),
      socialHandles: Map<String, String>.fromEntries(
        socialHandles.entries
            .where(
              (entry) =>
                  entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty,
            )
            .map((entry) => MapEntry(entry.key.trim(), entry.value.trim())),
      ),
      audienceSize: audienceSize,
      status: UagCreatorApplicationStatus.pending,
      agreedTermsVersion: UagCreatorApplicationPolicy.currentTermsVersion,
      createdAtIso: nowIso,
    );

    await doc.set(<String, dynamic>{
      ...application.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<UagCreatorApprovalResult> approveApplication({
    required UagCreatorProgrammeApplication application,
    String? creatorId,
    String? primaryCode,
  }) async {
    if (currentUid == null) {
      throw StateError('Sign in before approving Creator applications.');
    }
    if (application.id.trim().isEmpty || application.uid.trim().isEmpty) {
      throw StateError('Creator application is missing its identity.');
    }

    const policy = UagCreatorApplicationPolicy();
    final resolvedCreatorId = (creatorId ?? '').trim().isEmpty
        ? policy.creatorIdFor(
            uid: application.uid,
            displayName: application.displayName,
          )
        : creatorId!.trim().toUpperCase();

    final requestedCode = (primaryCode ?? '').trim().isEmpty
        ? policy.defaultCodeFor(application.displayName)
        : primaryCode!.trim();
    final codeValidation = const UagCreatorCampaignCodePolicy().normalise(
      raw: requestedCode,
      creatorHandle: application.displayName,
    );
    if (!codeValidation.valid) {
      throw StateError(codeValidation.reasons.join(' '));
    }

    final applicationRef = _applications.doc(application.id);
    final codeRef = _campaignCodes.doc(codeValidation.normalizedCode);
    final approvedAtIso = DateTime.now().toUtc().toIso8601String();

    await _firestore.runTransaction((transaction) async {
      final applicationSnapshot = await transaction.get(applicationRef);
      if (!applicationSnapshot.exists) {
        throw StateError('Creator application no longer exists.');
      }

      final codeSnapshot = await transaction.get(codeRef);
      final codeOwner = codeSnapshot.data()?['uid']?.toString() ?? '';
      if (codeSnapshot.exists &&
          codeOwner.isNotEmpty &&
          codeOwner != application.uid) {
        throw StateError('That Creator code is already assigned.');
      }

      transaction.update(applicationRef, <String, dynamic>{
        'creatorId': resolvedCreatorId,
        'status': UagCreatorApplicationStatus.approved.name,
        'approvedAtIso': approvedAtIso,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(codeRef, <String, dynamic>{
        'id': codeValidation.normalizedCode,
        'code': codeValidation.normalizedCode,
        'requestedCode': requestedCode,
        'uid': application.uid,
        'creatorId': resolvedCreatorId,
        'creatorHandle': application.displayName,
        'status': 'approved',
        'isPrimary': true,
        'creatorTermsVersion': application.agreedTermsVersion,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    return UagCreatorApprovalResult(
      creatorId: resolvedCreatorId,
      primaryCode: codeValidation.normalizedCode,
    );
  }

  Future<void> rejectApplication({
    required UagCreatorProgrammeApplication application,
    required String reason,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.length < 3) {
      throw StateError('Add a short reason for the Creator decision.');
    }
    await _applications.doc(application.id).update(<String, dynamic>{
      'status': UagCreatorApplicationStatus.rejected.name,
      'decisionReason': cleanReason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class UagCreatorApprovalResult {
  const UagCreatorApprovalResult({
    required this.creatorId,
    required this.primaryCode,
  });

  final String creatorId;
  final String primaryCode;
}
