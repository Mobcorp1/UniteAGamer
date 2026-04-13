import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_poi_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_map_conditions.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_drop_intel.dart';

class ArcBlueprintRepository {
  ArcBlueprintRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _stateCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('arc_blueprints');

  CollectionReference<Map<String, dynamic>> get _reportsCollection =>
      _firestore.collection('arc_blueprint_drop_reports');

  Stream<Map<String, ArcBlueprintState>> watchMyBlueprintStates() {
    final uid = currentUid;
    if (uid == null) return Stream.value(<String, ArcBlueprintState>{});

    return _stateCollection(uid).snapshots().map((snapshot) {
      final out = <String, ArcBlueprintState>{};
      for (final doc in snapshot.docs) {
        final state = ArcBlueprintState.fromMap(doc.data());
        out[state.blueprintId] = state;
      }
      return out;
    });
  }

  Future<void> saveBlueprintState(ArcBlueprintState state) async {
    final uid = currentUid;
    if (uid == null) throw Exception('You must be signed in.');

    final normalized = state.copyWith(updatedAt: DateTime.now());

    await _stateCollection(uid)
        .doc(normalized.blueprintId)
        .set(normalized.toMap(), SetOptions(merge: true));
  }

  Future<void> saveBlueprintStates(Iterable<ArcBlueprintState> states) async {
    final uid = currentUid;
    if (uid == null) throw Exception('You must be signed in.');

    final batch = _firestore.batch();
    for (final state in states) {
      final normalized = state.copyWith(updatedAt: DateTime.now());
      final docRef = _stateCollection(uid).doc(normalized.blueprintId);
      batch.set(docRef, normalized.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> clearBlueprintState(String blueprintId) async {
    final uid = currentUid;
    if (uid == null) throw Exception('You must be signed in.');

    await saveBlueprintState(ArcBlueprintState.empty(blueprintId));
  }

  Future<void> resetAllBlueprintStates(Iterable<String> blueprintIds) async {
    final uid = currentUid;
    if (uid == null) throw Exception('You must be signed in.');

    final batch = _firestore.batch();
    for (final blueprintId in blueprintIds) {
      final docRef = _stateCollection(uid).doc(blueprintId);
      batch.set(
        docRef,
        ArcBlueprintState.empty(
          blueprintId,
        ).copyWith(updatedAt: DateTime.now()).toMap(),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Stream<List<ArcBlueprintDropReport>> watchReportsForBlueprint(
    String blueprintId,
  ) {
    return _reportsCollection
        .where('blueprintId', isEqualTo: blueprintId)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          final reports = snapshot.docs
              .map((doc) => ArcBlueprintDropReport.fromMap(doc.data()))
              .toList(growable: false);

          final sorted = List<ArcBlueprintDropReport>.from(reports)
            ..sort((a, b) {
              final aTime =
                  a.lastConfirmedAt ??
                  a.createdAt ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bTime =
                  b.lastConfirmedAt ??
                  b.createdAt ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final timeCompare = bTime.compareTo(aTime);
              if (timeCompare != 0) return timeCompare;
              return b.confirmationCount.compareTo(a.confirmationCount);
            });

          return sorted;
        });
  }

  Stream<List<ArcBlueprintDropReport>> watchRecentReports({int limit = 120}) {
    return _reportsCollection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ArcBlueprintDropReport.fromMap(doc.data()))
              .toList(growable: false),
        );
  }

  Stream<ArcDropIntel> watchIntelForBlueprint(String blueprintId) {
    return watchReportsForBlueprint(blueprintId).map(
      (reports) =>
          ArcDropIntel.fromReports(blueprintId: blueprintId, reports: reports),
    );
  }

  Future<void> addDropReport({
    required String blueprintId,
    required String mapName,
    required ArcDropSourceType sourceType,
    required ArcRaidMode mode,
    required ArcRaidType raidType,
    required ArcEntryTime entryTime,
    required ArcTimeOfDay timeOfDay,
    String? poiId,
    String? poiName,
    String? enemySourceId,
    String? enemySourceName,
    String? containerTypeId,
    String? containerTypeLabel,
    String? weatherConditionId,
    String? weatherConditionLabel,
    String? mapEventId,
    String? mapEventLabel,
    String? conditionId,
    String? conditionLabel,
    DateTime? foundAt,
    String notes = '',
  }) async {
    final uid = currentUid;
    if (uid == null) throw Exception('You must be signed in.');

    final trimmedMapName = mapName.trim();
    final trimmedPoiId = poiId?.trim();
    final normalizedPoi = (trimmedPoiId != null && trimmedPoiId.isNotEmpty)
        ? ArcPoiDataStore.findPoiById(trimmedMapName, trimmedPoiId)
        : null;

    final rawConditionId = (mapEventId?.trim().isNotEmpty ?? false)
        ? mapEventId!.trim()
        : ((weatherConditionId?.trim().isNotEmpty ?? false)
              ? weatherConditionId!.trim()
              : conditionId?.trim());

    final selectedCondition = ArcMapConditions.byId(rawConditionId);
    final resolvedWeatherConditionId =
        selectedCondition != null && selectedCondition.isWeather
        ? selectedCondition.id
        : null;
    final resolvedWeatherConditionLabel =
        selectedCondition != null && selectedCondition.isWeather
        ? selectedCondition.label
        : null;
    final resolvedMapEventId =
        selectedCondition != null &&
            !selectedCondition.isWeather &&
            !selectedCondition.isNeutral
        ? selectedCondition.id
        : (selectedCondition != null && selectedCondition.isNeutral
              ? selectedCondition.id
              : null);
    final resolvedMapEventLabel =
        selectedCondition != null &&
            !selectedCondition.isWeather &&
            !selectedCondition.isNeutral
        ? selectedCondition.label
        : (selectedCondition != null && selectedCondition.isNeutral
              ? selectedCondition.label
              : null);

    final normalizedPoiId = normalizedPoi?.id ?? trimmedPoiId;
    final normalizedPoiName = normalizedPoi?.name ?? poiName?.trim();
    final normalizedEnemyId = enemySourceId?.trim();
    final normalizedEnemyName = enemySourceName?.trim();
    final normalizedContainerTypeId = containerTypeId?.trim();
    final normalizedContainerTypeLabel = containerTypeLabel?.trim();
    final now = DateTime.now();

    final signature = ArcBlueprintDropReport.buildSignature(
      blueprintId: blueprintId,
      mapName: trimmedMapName,
      sourceType: sourceType,
      poiId: normalizedPoiId,
      enemySourceId: normalizedEnemyId,
      containerTypeId: normalizedContainerTypeId,
      weatherConditionId: resolvedWeatherConditionId,
      mapEventId: resolvedMapEventId,
      mode: mode,
      raidType: raidType,
      entryTime: entryTime,
      timeOfDay: timeOfDay,
    );

    final existingSnapshot = await _reportsCollection
        .where('signature', isEqualTo: signature)
        .limit(1)
        .get();

    if (existingSnapshot.docs.isNotEmpty) {
      final existingDoc = existingSnapshot.docs.first;
      final existingReport = ArcBlueprintDropReport.fromMap(existingDoc.data());
      final alreadyConfirmed = existingReport.confirmedByUserIds.any(
        (item) => item.trim().toLowerCase() == uid.toLowerCase(),
      );

      final updatePayload = <String, dynamic>{
        'lastConfirmedAt': Timestamp.fromDate(now),
        'foundAt': Timestamp.fromDate(foundAt ?? now),
      };

      if (!alreadyConfirmed) {
        updatePayload['confirmationCount'] = FieldValue.increment(1);
        updatePayload['confirmedByUserIds'] = FieldValue.arrayUnion([uid]);
      }

      final trimmedNotes = notes.trim();
      if (trimmedNotes.isNotEmpty && existingReport.notes.trim().isEmpty) {
        updatePayload['notes'] = trimmedNotes;
      }

      await existingDoc.reference.set(updatePayload, SetOptions(merge: true));
      return;
    }

    final doc = _reportsCollection.doc();

    final report = ArcBlueprintDropReport(
      id: doc.id,
      blueprintId: blueprintId,
      userId: uid,
      mapName: trimmedMapName,
      sourceType: sourceType,
      poiId: normalizedPoiId,
      poiName: normalizedPoiName,
      enemySourceId: normalizedEnemyId,
      enemySourceName: normalizedEnemyName,
      containerTypeId: normalizedContainerTypeId,
      containerTypeLabel: normalizedContainerTypeLabel,
      weatherConditionId: resolvedWeatherConditionId,
      weatherConditionLabel: resolvedWeatherConditionLabel,
      mapEventId: resolvedMapEventId,
      mapEventLabel: resolvedMapEventLabel,
      mode: mode,
      raidType: raidType,
      entryTime: entryTime,
      timeOfDay: timeOfDay,
      foundAt: foundAt ?? now,
      lastConfirmedAt: now,
      notes: notes.trim(),
      createdAt: now,
      confirmationCount: 1,
      confirmedByUserIds: [uid],
      signature: signature,
    );

    await doc.set({...report.toMap(), 'locationName': report.poiName});

    debugPrint(
      'ARC report saved: blueprint=$blueprintId, map=$mapName, '
      'signature=$signature, confirmations=${report.confirmationCount}, '
      'conditionId=${report.conditionId}, mapEventId=${report.mapEventId}, '
      'weatherId=${report.weatherConditionId}',
    );
  }
}
