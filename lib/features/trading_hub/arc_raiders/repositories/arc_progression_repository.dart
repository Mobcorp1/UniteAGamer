import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_progression_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_season_reset_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart';

class ArcProgressionRepository {
  ArcProgressionRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ArcProgressionEngine engine = const ArcProgressionEngine(),
    ArcOperationsRepository? operationsRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _engine = engine,
       _operationsRepository = operationsRepository;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ArcProgressionEngine _engine;
  final ArcOperationsRepository? _operationsRepository;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _seasonRef(String uid) =>
      _userRef(uid).collection('arc_season_state').doc('current');

  CollectionReference<Map<String, dynamic>> _questProgressRef(String uid) =>
      _userRef(uid).collection('arc_quest_progress');

  DocumentReference<Map<String, dynamic>> _scrappyProgressRef(String uid) =>
      _userRef(uid).collection('arc_scrappy_progress').doc('current');

  CollectionReference<Map<String, dynamic>> _benchProgressRef(String uid) =>
      _userRef(uid).collection('arc_bench_progress');

  Stream<ArcProgressionRecords> watchProgressionRecords() {
    final uid = _uid;
    if (uid == null) return Stream.value(ArcProgressionRecords.empty);

    final controller = StreamController<ArcProgressionRecords>();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? questSubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    scrappySubscription;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? benchSubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    seasonSubscription;
    var disposed = false;
    var seasonId = ArcSeasonResetPolicy.defaultCurrentSeasonId;
    var questRecords = <String, ArcQuestProgressionRecord>{};
    var scrappyState = ArcScrappyProgressionState.empty;
    var benchRecords = <String, ArcBenchProgressionRecord>{};

    void emit() {
      if (disposed || controller.isClosed) return;
      controller.add(
        ArcProgressionRecords(
          questRecords: questRecords,
          scrappyState: scrappyState.copyWith(seasonId: seasonId),
          benchRecords: benchRecords,
          seasonId: seasonId,
        ),
      );
    }

    void addError(Object error, StackTrace stackTrace) {
      if (!disposed && !controller.isClosed) {
        controller.addError(error, stackTrace);
      }
    }

    controller.onListen = () {
      seasonSubscription = _seasonRef(uid).snapshots().listen((snapshot) {
        seasonId = _seasonIdFrom(snapshot.data());
        emit();
      }, onError: addError);

      questSubscription = _questProgressRef(uid).snapshots().listen((snapshot) {
        questRecords = {
          for (final doc in snapshot.docs)
            doc.id: ArcQuestProgressionRecord.fromMap(
              doc.id,
              _normalizeMap(doc.data()),
            ),
        };
        emit();
      }, onError: addError);

      scrappySubscription = _scrappyProgressRef(uid).snapshots().listen((
        snapshot,
      ) {
        scrappyState = ArcScrappyProgressionState.fromMap(
          snapshot.exists ? _normalizeMap(snapshot.data()) : null,
        );
        emit();
      }, onError: addError);

      benchSubscription = _benchProgressRef(uid).snapshots().listen((snapshot) {
        benchRecords = {
          for (final doc in snapshot.docs)
            doc.id: ArcBenchProgressionRecord.fromMap(
              doc.id,
              _normalizeMap(doc.data()),
            ),
        };
        emit();
      }, onError: addError);
    };

    controller.onCancel = () async {
      disposed = true;
      await questSubscription?.cancel();
      await scrappySubscription?.cancel();
      await benchSubscription?.cancel();
      await seasonSubscription?.cancel();
    };

    return controller.stream;
  }

  Future<ArcProgressionRecords> loadProgressionRecords() async {
    final uid = _uid;
    if (uid == null) return ArcProgressionRecords.empty;
    final season = await _seasonRef(uid).get();
    final seasonId = _seasonIdFrom(season.data());
    final questSnapshot = await _questProgressRef(uid).get();
    final scrappySnapshot = await _scrappyProgressRef(uid).get();
    final benchSnapshot = await _benchProgressRef(uid).get();

    return ArcProgressionRecords(
      seasonId: seasonId,
      questRecords: {
        for (final doc in questSnapshot.docs)
          doc.id: ArcQuestProgressionRecord.fromMap(
            doc.id,
            _normalizeMap(doc.data()),
          ),
      },
      scrappyState: ArcScrappyProgressionState.fromMap(
        scrappySnapshot.exists ? _normalizeMap(scrappySnapshot.data()) : null,
      ).copyWith(seasonId: seasonId),
      benchRecords: {
        for (final doc in benchSnapshot.docs)
          doc.id: ArcBenchProgressionRecord.fromMap(
            doc.id,
            _normalizeMap(doc.data()),
          ),
      },
    );
  }

  Future<bool> confirmQuestCompleted({
    required String questId,
    required Map<String, ArcScrappyState> scrappyStates,
  }) async {
    final uid = _uid;
    if (uid == null || questId.trim().isEmpty) return false;
    final records = await loadProgressionRecords();
    final snapshot = _engine.buildQuestSnapshot(
      scrappyStates: scrappyStates,
      records: records.questRecords,
      seasonId: records.seasonId,
    );
    final entry = snapshot.entries.firstWhere(
      (entry) => entry.questId == questId,
      orElse: () => throw StateError('Unknown quest progression id: $questId'),
    );
    if (entry.completed) return false;
    if (!entry.readyToComplete) {
      throw StateError('${entry.questLabel} is not ready to complete.');
    }

    final record = _engine.completeQuestRecord(
      snapshot: snapshot,
      questId: questId,
    );
    await _questProgressRef(uid).doc(questId).set({
      ...record.toMap(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    }, SetOptions(merge: true));
    await _operations.recordQuestCompleted(questId: questId);
    return true;
  }

  Future<bool> confirmScrappyUpgrade({
    required int level,
    required Map<String, ArcScrappyState> scrappyStates,
  }) async {
    final uid = _uid;
    if (uid == null || level <= 0) return false;
    final records = await loadProgressionRecords();
    final snapshot = _engine.buildScrappySnapshot(
      scrappyStates: scrappyStates,
      state: records.scrappyState,
      seasonId: records.seasonId,
    );
    if (level <= snapshot.state.currentLevel) return false;

    final state = _engine.confirmScrappyLevel(snapshot: snapshot, level: level);
    await _scrappyProgressRef(uid).set({
      ...state.toMap(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    }, SetOptions(merge: true));
    await _operations.recordScrappyUpgradeCompleted(level: level);
    return true;
  }

  Future<bool> confirmBenchUpgrade({
    required String station,
    required int level,
    required Map<String, ArcScrappyState> scrappyStates,
  }) async {
    final uid = _uid;
    if (uid == null || station.trim().isEmpty || level <= 0) return false;
    final records = await loadProgressionRecords();
    final benchId = ArcProgressionEngine.benchIdFor(station);
    final current = records.benchRecords[benchId];
    if (current != null && level <= current.currentLevel) return false;
    final snapshot = _engine.buildBenchSnapshot(
      scrappyStates: scrappyStates,
      records: records.benchRecords,
      seasonId: records.seasonId,
    );
    final record = _engine
        .confirmBenchLevel(
          snapshot: snapshot,
          scrappyStates: scrappyStates,
          station: station,
          level: level,
        )
        .copyWith(seasonId: records.seasonId);
    await _benchProgressRef(uid).doc(benchId).set({
      ...record.toMap(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    }, SetOptions(merge: true));
    await _operations.recordBenchUpgradeCompleted(
      benchId: benchId,
      level: level,
    );
    return true;
  }

  ArcOperationsRepository get _operations =>
      _operationsRepository ??
      ArcOperationsRepository(firestore: _firestore, auth: _auth);

  String _seasonIdFrom(Map<String, dynamic>? data) {
    final value = data?['currentSeasonId'];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return ArcSeasonResetPolicy.defaultCurrentSeasonId;
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic>? source) {
    if (source == null) return const <String, dynamic>{};
    return source.map((key, value) => MapEntry(key, _normalizeValue(value)));
  }

  Object? _normalizeValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is Map) {
      return value.map(
        (key, value) => MapEntry(key.toString(), _normalizeValue(value)),
      );
    }
    if (value is Iterable) {
      return value.map(_normalizeValue).toList(growable: false);
    }
    return value;
  }
}
