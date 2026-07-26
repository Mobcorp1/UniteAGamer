import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_community_intel_report.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';

class ArcCommunityIntelRepository {
  ArcCommunityIntelRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('arc_community_intel_reports');

  String? get currentUid => _auth.currentUser?.uid;

  Stream<List<ArcCommunityIntelReport>> watchMapReports(
    String mapId, {
    int limit = 250,
  }) {
    return _collection
        .where('mapId', isEqualTo: mapId)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          final reports = snapshot.docs
              .map(
                (doc) => ArcCommunityIntelReport.fromMap(<String, dynamic>{
                  ...doc.data(),
                  'id': doc.id,
                }),
              )
              .where(
                (report) =>
                    report.active &&
                    report.verificationStateAt(now) !=
                        ArcCommunityIntelVerificationState.expired,
              )
              .toList(growable: false);
          reports.sort((a, b) {
            final confidence = b.confirmationCount.compareTo(
              a.confirmationCount,
            );
            if (confidence != 0) return confidence;
            return b.updatedAt.compareTo(a.updatedAt);
          });
          return reports;
        });
  }

  Future<String> submit({
    required String mapId,
    required ArcRaidMapLayer layer,
    required ArcCommunityIntelCategory category,
    required ArcNormalizedPoint point,
    String? poiId,
    String? poiName,
    String? blueprintId,
    String? blueprintName,
    String notes = '',
  }) async {
    final uid = currentUid;
    if (uid == null) throw StateError('You must be signed in.');

    if (category == ArcCommunityIntelCategory.blueprintFound &&
        (blueprintId == null || blueprintId.trim().isEmpty)) {
      throw ArgumentError('Choose the Blueprint that was found.');
    }

    final cleanPoint = point.clamp();
    final signature = ArcCommunityIntelReport.buildSignature(
      mapId: mapId,
      layer: layer,
      category: category,
      point: cleanPoint,
      blueprintId: blueprintId,
    );
    final now = DateTime.now();

    final existing = await _collection
        .where('signature', isEqualTo: signature)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final report = ArcCommunityIntelReport.fromMap(<String, dynamic>{
        ...doc.data(),
        'id': doc.id,
      });
      final alreadyConfirmed = report.confirmedByUserIds.contains(uid);
      final update = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(now),
        'lastConfirmedAt': Timestamp.fromDate(now),
        'active': true,
      };
      if (!alreadyConfirmed) {
        update['confirmationCount'] = FieldValue.increment(1);
        update['confirmedByUserIds'] = FieldValue.arrayUnion(<String>[uid]);
      }
      final cleanNotes = notes.trim();
      if (cleanNotes.isNotEmpty && report.notes.trim().isEmpty) {
        update['notes'] = cleanNotes.substring(
          0,
          cleanNotes.length.clamp(0, 280),
        );
      }
      await doc.reference.set(update, SetOptions(merge: true));
      return doc.id;
    }

    final doc = _collection.doc();
    final cleanNotes = notes.trim();
    final report = ArcCommunityIntelReport(
      id: doc.id,
      reporterUid: uid,
      mapId: mapId,
      layer: layer,
      category: category,
      point: cleanPoint,
      poiId: poiId?.trim().isEmpty == true ? null : poiId?.trim(),
      poiName: poiName?.trim().isEmpty == true ? null : poiName?.trim(),
      blueprintId: blueprintId?.trim().isEmpty == true
          ? null
          : blueprintId?.trim(),
      blueprintName: blueprintName?.trim().isEmpty == true
          ? null
          : blueprintName?.trim(),
      notes: cleanNotes.substring(0, cleanNotes.length.clamp(0, 280)),
      createdAt: now,
      updatedAt: now,
      lastConfirmedAt: now,
      confirmationCount: 1,
      confirmedByUserIds: <String>[uid],
      disputeCount: 0,
      disputedByUserIds: const <String>[],
      signature: signature,
      expiresAt: now.add(_lifetimeFor(category)),
    );
    await doc.set(report.toMap());
    return doc.id;
  }

  Future<void> confirm(String reportId) async {
    await _verify(reportId, confirm: true);
  }

  Future<void> dispute(String reportId) async {
    await _verify(reportId, confirm: false);
  }

  Future<void> _verify(String reportId, {required bool confirm}) async {
    final uid = currentUid;
    if (uid == null) throw StateError('You must be signed in.');

    final doc = _collection.doc(reportId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(doc);
      if (!snapshot.exists) return;

      final report = ArcCommunityIntelReport.fromMap(<String, dynamic>{
        ...snapshot.data()!,
        'id': snapshot.id,
      });
      final now = DateTime.now();
      if (report.verificationStateAt(now) ==
          ArcCommunityIntelVerificationState.expired) {
        throw StateError('This Intel report has expired.');
      }
      if (report.reporterUid == uid) {
        throw StateError('You cannot verify your own Intel report.');
      }

      final alreadyConfirmed = report.confirmedByUserIds.contains(uid);
      final alreadyDisputed = report.disputedByUserIds.contains(uid);
      final updates = <String, dynamic>{'updatedAt': Timestamp.fromDate(now)};

      if (confirm) {
        if (alreadyConfirmed) return;
        updates['confirmationCount'] = FieldValue.increment(1);
        updates['confirmedByUserIds'] = FieldValue.arrayUnion(<String>[uid]);
        updates['lastConfirmedAt'] = Timestamp.fromDate(now);
        if (alreadyDisputed) {
          updates['disputeCount'] = FieldValue.increment(-1);
          updates['disputedByUserIds'] = FieldValue.arrayRemove(<String>[uid]);
        }
      } else {
        if (alreadyDisputed) return;
        updates['disputeCount'] = FieldValue.increment(1);
        updates['disputedByUserIds'] = FieldValue.arrayUnion(<String>[uid]);
        updates['lastDisputedAt'] = Timestamp.fromDate(now);
        if (alreadyConfirmed) {
          updates['confirmationCount'] = FieldValue.increment(-1);
          updates['confirmedByUserIds'] = FieldValue.arrayRemove(<String>[uid]);
        }
      }

      transaction.update(doc, updates);
    });
  }

  static Duration _lifetimeFor(ArcCommunityIntelCategory category) {
    switch (category) {
      case ArcCommunityIntelCategory.raiderActivity:
      case ArcCommunityIntelCategory.extractionActivity:
      case ArcCommunityIntelCategory.extractionDanger:
      case ArcCommunityIntelCategory.clearedArea:
        return const Duration(hours: 12);
      case ArcCommunityIntelCategory.arcThreat:
        return const Duration(hours: 24);
      case ArcCommunityIntelCategory.blueprintFound:
      case ArcCommunityIntelCategory.lockedRoom:
      case ArcCommunityIntelCategory.lootContainer:
      case ArcCommunityIntelCategory.highValueLoot:
        return const Duration(days: 7);
    }
  }
}
