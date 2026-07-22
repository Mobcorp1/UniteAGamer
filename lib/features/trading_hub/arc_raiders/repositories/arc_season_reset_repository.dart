import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_bench_upgrade_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_operations_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_requirement_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_scrappy_seed_data.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_operations_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_item.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_season_reset_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart';

class ArcSeasonResetRepository {
  ArcSeasonResetRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('No signed-in user available for season reset.');
    }
    return uid;
  }

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _seasonRef(String uid) =>
      _userRef(uid).collection('arc_season_state').doc('current');

  CollectionReference<Map<String, dynamic>> _historyRef(String uid) =>
      _userRef(uid).collection('arc_season_history');

  CollectionReference<Map<String, dynamic>> _blueprintStatesRef(String uid) =>
      _userRef(uid).collection('arc_blueprints');

  CollectionReference<Map<String, dynamic>> _scrappyStatesRef(String uid) =>
      _userRef(uid).collection('arc_scrappy_states');

  CollectionReference<Map<String, dynamic>> _questProgressRef(String uid) =>
      _userRef(uid).collection('arc_quest_progress');

  CollectionReference<Map<String, dynamic>> _scrappyProgressRef(String uid) =>
      _userRef(uid).collection('arc_scrappy_progress');

  CollectionReference<Map<String, dynamic>> _benchProgressRef(String uid) =>
      _userRef(uid).collection('arc_bench_progress');

  DocumentReference<Map<String, dynamic>> _operationSummaryRef(String uid) =>
      _firestore.collection('arc_operation_progress').doc(uid);

  CollectionReference<Map<String, dynamic>> _operationProgressRef(String uid) =>
      _operationSummaryRef(uid).collection('operations');

  CollectionReference<Map<String, dynamic>> _rewardInventoryRef(String uid) =>
      _firestore
          .collection('arc_rewards_inventory')
          .doc(uid)
          .collection('items');

  Stream<ArcSeasonState> watchSeasonState() {
    final uid = _uid;
    return _seasonRef(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return ArcSeasonState.initial();
      return ArcSeasonState.fromMap(data);
    });
  }

  Future<ArcSeasonState> getSeasonState() async {
    final uid = _uid;
    final snapshot = await _seasonRef(uid).get();
    final data = snapshot.data();
    if (data == null) return ArcSeasonState.initial();
    return ArcSeasonState.fromMap(data);
  }

  Future<void> ensureSeasonStateExists() async {
    final uid = _uid;
    final ref = _seasonRef(uid);
    final snapshot = await ref.get();
    if (snapshot.exists) return;
    await ref.set(ArcSeasonState.initial().toMap(), SetOptions(merge: true));
  }

  Future<ArcSeasonResetPreview> createResetPreview({
    String? nextSeasonId,
    String? resetId,
  }) async {
    final uid = _uid;
    final state = await getSeasonState();
    final blueprintSnapshot = await _blueprintStatesRef(uid).get();
    final scrappySnapshot = await _scrappyStatesRef(uid).get();
    final questProgressSnapshot = await _questProgressRef(uid).get();
    final scrappyProgressSnapshot = await _scrappyProgressRef(uid).get();
    final benchProgressSnapshot = await _benchProgressRef(uid).get();
    final operationSnapshot = await _operationProgressRef(uid).get();
    final rewardSnapshot = await _rewardInventoryRef(uid).get();
    final groups = _classifyTrackerDocs(scrappySnapshot.docs);
    final scrappyResetCount =
        groups.scrappyDocs.length + scrappyProgressSnapshot.docs.length;
    final questResetCount =
        groups.questDocs.length + questProgressSnapshot.docs.length;
    final benchResetCount =
        groups.benchDocs.length + benchProgressSnapshot.docs.length;
    final seasonalOperationDocs = _seasonalOperationDocs(
      operationSnapshot.docs,
      currentSeasonId: state.currentSeasonId,
    );
    final generatedAt = DateTime.now().toUtc();
    final resolvedNextSeasonId = nextSeasonId?.trim().isNotEmpty == true
        ? nextSeasonId!.trim()
        : _nextSeasonId(state.currentSeasonId);
    final resolvedResetId = resetId?.trim().isNotEmpty == true
        ? resetId!.trim()
        : 'reset-${state.currentSeasonId}-$resolvedNextSeasonId-${generatedAt.millisecondsSinceEpoch}';

    return ArcSeasonResetPreview(
      currentSeasonId: state.currentSeasonId,
      nextSeasonId: resolvedNextSeasonId,
      resetId: resolvedResetId,
      resetVersion: state.resetVersion + 1,
      generatedAt: generatedAt,
      impacts: ArcSeasonResetPolicy.impacts(
        blueprintStateCount: blueprintSnapshot.docs.length,
        scrappyStateCount: scrappyResetCount,
        questStateCount: questResetCount,
        benchStateCount: benchResetCount,
        operationProgressCount: seasonalOperationDocs.length,
        rewardCount: rewardSnapshot.docs.length,
      ),
      blueprintStateCount: blueprintSnapshot.docs.length,
      scrappyStateCount: scrappyResetCount,
      questStateCount: questResetCount,
      benchStateCount: benchResetCount,
      operationProgressCount: seasonalOperationDocs.length,
      rewardCount: rewardSnapshot.docs.length,
    );
  }

  Future<ArcSeasonResetApplyResult> applyReset(
    ArcSeasonResetPreview preview, {
    bool adminPreview = false,
  }) async {
    final uid = _uid;
    final now = DateTime.now().toUtc();
    final currentState = await getSeasonState();

    if (currentState.lastResetId == preview.resetId &&
        currentState.resetStatus == ArcSeasonResetStatus.completed) {
      return ArcSeasonResetApplyResult(
        resetId: preview.resetId,
        archivedSeasonId:
            currentState.lastCompletedSeasonId ?? preview.currentSeasonId,
        currentSeasonId: currentState.currentSeasonId,
        resetVersion: currentState.resetVersion,
        completedAt: currentState.lastResetAt ?? now,
        alreadyApplied: true,
      );
    }

    if (adminPreview) {
      return ArcSeasonResetApplyResult(
        resetId: preview.resetId,
        archivedSeasonId: preview.currentSeasonId,
        currentSeasonId: preview.nextSeasonId,
        resetVersion: preview.resetVersion,
        completedAt: now,
      );
    }

    if (currentState.resetStatus == ArcSeasonResetStatus.inProgress &&
        currentState.pendingResetId != null &&
        currentState.pendingResetId != preview.resetId) {
      throw StateError(
        'Another reset is already in progress: ${currentState.pendingResetId}.',
      );
    }

    await _seasonRef(uid).set({
      'resetStatus': ArcSeasonResetStatus.inProgress.name,
      'pendingResetId': preview.resetId,
      'pendingNextSeasonId': preview.nextSeasonId,
      'resetStartedAt': now.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      final blueprintSnapshot = await _blueprintStatesRef(uid).get();
      final scrappySnapshot = await _scrappyStatesRef(uid).get();
      final questProgressSnapshot = await _questProgressRef(uid).get();
      final scrappyProgressSnapshot = await _scrappyProgressRef(uid).get();
      final benchProgressSnapshot = await _benchProgressRef(uid).get();
      final operationSnapshot = await _operationProgressRef(uid).get();
      final rewardSnapshot = await _rewardInventoryRef(uid).get();
      final groups = _classifyTrackerDocs(scrappySnapshot.docs);
      final scrappyResetCount =
          groups.scrappyDocs.length + scrappyProgressSnapshot.docs.length;
      final questResetCount =
          groups.questDocs.length + questProgressSnapshot.docs.length;
      final benchResetCount =
          groups.benchDocs.length + benchProgressSnapshot.docs.length;
      final seasonalOperationDocs = _seasonalOperationDocs(
        operationSnapshot.docs,
        currentSeasonId: preview.currentSeasonId,
      );
      final resetDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[
        ...groups.scrappyDocs,
        ...groups.questDocs,
        ...groups.benchDocs,
        ...questProgressSnapshot.docs,
        ...scrappyProgressSnapshot.docs,
        ...benchProgressSnapshot.docs,
      ];
      final resetStateIds = resetDocs.map((doc) => doc.id).toList()..sort();
      final archivedOperationIds =
          seasonalOperationDocs.map((doc) => doc.id).toList()..sort();
      final historyEntry = ArcSeasonHistoryEntry(
        seasonId: preview.currentSeasonId,
        resetId: preview.resetId,
        completedAt: now,
        blueprintStateCount: blueprintSnapshot.docs.length,
        scrappyStateCount: scrappyResetCount,
        questStateCount: questResetCount,
        benchStateCount: benchResetCount,
        operationProgressCount: seasonalOperationDocs.length,
        rewardCount: rewardSnapshot.docs.length,
      );
      final result = ArcSeasonResetApplyResult(
        resetId: preview.resetId,
        archivedSeasonId: preview.currentSeasonId,
        currentSeasonId: preview.nextSeasonId,
        resetVersion: preview.resetVersion,
        completedAt: now,
        resetBlueprintIds: blueprintSnapshot.docs.map((doc) => doc.id).toList()
          ..sort(),
        resetStateIds: resetStateIds,
        archivedOperationIds: archivedOperationIds,
        archivedRewardCount: rewardSnapshot.docs.length,
      );

      final batch = _firestore.batch();
      batch.set(_historyRef(uid).doc(_historyDocId(preview)), {
        ...historyEntry.toMap(),
        'preview': preview.toMap(),
        'blueprintArchive': _archiveDocs(blueprintSnapshot.docs),
        'trackerArchive': {
          'scrappy': _archiveDocs(groups.scrappyDocs),
          'quests': _archiveDocs(groups.questDocs),
          'benches': _archiveDocs(groups.benchDocs),
        },
        'progressionArchive': {
          'scrappy': _archiveDocs(scrappyProgressSnapshot.docs),
          'quests': _archiveDocs(questProgressSnapshot.docs),
          'benches': _archiveDocs(benchProgressSnapshot.docs),
        },
        'operationArchive': _archiveDocs(seasonalOperationDocs),
        'rewardArchive': _archiveDocs(rewardSnapshot.docs),
        'createdAt': now.toIso8601String(),
        'policyVersion': ArcSeasonResetPolicy.resetPolicyVersion,
      }, SetOptions(merge: true));

      for (final doc in blueprintSnapshot.docs) {
        batch.delete(doc.reference);
      }

      for (final doc in resetDocs) {
        batch.delete(doc.reference);
      }

      for (final doc in seasonalOperationDocs) {
        batch.delete(doc.reference);
      }

      for (final doc in rewardSnapshot.docs) {
        final data = doc.data();
        final sourceSeasonId = _string(data['sourceSeasonId']);
        final currentSeasonUnlock = data['currentSeasonUnlock'] != false;
        if (sourceSeasonId == preview.currentSeasonId ||
            (sourceSeasonId == null && currentSeasonUnlock)) {
          batch.set(doc.reference, {
            'currentSeasonUnlock': false,
            'historicalVisible': data['historicalVisible'] != false,
            'archivedSeasonId': preview.currentSeasonId,
            'archivedByResetId': preview.resetId,
            'updatedAt': now.toIso8601String(),
          }, SetOptions(merge: true));
        }
      }

      batch.set(_operationSummaryRef(uid), {
        'currentSeasonId': preview.nextSeasonId,
        'lastSeasonReset': result.toMap(),
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));

      batch.set(_seasonRef(uid), {
        'currentSeasonId': preview.nextSeasonId,
        'currentSeasonStartedAt': now.toIso8601String(),
        'lastCompletedSeasonId': preview.currentSeasonId,
        'lastResetId': preview.resetId,
        'lastResetAt': now.toIso8601String(),
        'resetVersion': preview.resetVersion,
        'resetStatus': ArcSeasonResetStatus.completed.name,
        'pendingResetId': null,
        'pendingNextSeasonId': null,
        'lastResetResult': result.toMap(),
        'seasonHistory': FieldValue.arrayUnion([historyEntry.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
        'policyVersion': ArcSeasonResetPolicy.resetPolicyVersion,
      }, SetOptions(merge: true));

      await batch.commit();
      await ArcOperationsRepository(
        firestore: _firestore,
        auth: _auth,
      ).reconcileEquippedCosmetics();
      return result;
    } catch (error) {
      await _seasonRef(uid).set({
        'resetStatus': ArcSeasonResetStatus.failed.name,
        'lastResetError': error.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      rethrow;
    }
  }

  Future<ArcSeasonResetApplyResult?> reconcileInterruptedReset() async {
    final state = await getSeasonState();
    if (!state.resetInProgress) return null;
    final resetId = state.pendingResetId;
    if (resetId == null || resetId.trim().isEmpty) return null;
    final preview = await createResetPreview(
      nextSeasonId: state.pendingNextSeasonId,
      resetId: resetId,
    );
    return applyReset(preview);
  }

  Future<Map<String, ArcScrappyState>> getTrackerStates() async {
    final uid = _uid;
    final snapshot = await _scrappyStatesRef(uid).get();
    final states = <String, ArcScrappyState>{};
    for (final doc in snapshot.docs) {
      states[doc.id] = ArcScrappyState.fromJson(doc.data(), itemId: doc.id);
    }
    return states;
  }

  _TrackerDocGroups _classifyTrackerDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final scrappyIds = ArcScrappySeedData.items
        .whereType<ArcScrappyItem>()
        .map((item) => item.id)
        .toSet();
    final questIds = ArcQuestRequirementSeedData.items
        .whereType<ArcScrappyItem>()
        .map((item) => item.id)
        .toSet();
    final benchIds = ArcBenchUpgradeSeedData.items
        .whereType<ArcScrappyItem>()
        .map((item) => item.id)
        .toSet();

    final scrappyDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final questDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final benchDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (final doc in docs) {
      if (scrappyIds.contains(doc.id)) {
        scrappyDocs.add(doc);
      } else if (questIds.contains(doc.id) || doc.id.startsWith('quest-')) {
        questDocs.add(doc);
      } else if (benchIds.contains(doc.id) || doc.id.startsWith('bench-')) {
        benchDocs.add(doc);
      }
    }

    return _TrackerDocGroups(
      scrappyDocs: scrappyDocs,
      questDocs: questDocs,
      benchDocs: benchDocs,
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _seasonalOperationDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required String currentSeasonId,
  }) {
    return docs
        .where((doc) {
          final task = _operationTaskById(doc.id);
          if (task == null) return false;
          if (!task.resetsWithSeason) return false;
          final seasonId = _string(doc.data()['seasonId']);
          return seasonId == null || seasonId == currentSeasonId;
        })
        .toList(growable: false);
  }

  ArcOperationTask? _operationTaskById(String operationId) {
    for (final task in ArcOperationsSeedData.allOperations) {
      if (task.id == operationId) return task;
    }
    return null;
  }

  List<Map<String, dynamic>> _archiveDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs
        .map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          return {
            'id': doc.id,
            'data': data.map(
              (key, value) => MapEntry(key, _archiveValue(value)),
            ),
          };
        })
        .toList(growable: false);
  }

  Object? _archiveValue(Object? value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return value.map(
        (key, value) => MapEntry(key.toString(), _archiveValue(value)),
      );
    }
    if (value is Iterable) {
      return value.map(_archiveValue).toList(growable: false);
    }
    return value;
  }

  String? _string(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String _nextSeasonId(String currentSeasonId) {
    final match = RegExp(r'^(.*?)(\d+)$').firstMatch(currentSeasonId);
    if (match == null) return '$currentSeasonId-next';
    final prefix = match.group(1) ?? currentSeasonId;
    final number = int.tryParse(match.group(2) ?? '') ?? 1;
    return '$prefix${number + 1}';
  }

  String _historyDocId(ArcSeasonResetPreview preview) {
    final raw = '${preview.currentSeasonId}-${preview.resetId}';
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}

class _TrackerDocGroups {
  const _TrackerDocGroups({
    required this.scrappyDocs,
    required this.questDocs,
    required this.benchDocs,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> scrappyDocs;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> questDocs;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> benchDocs;
}
