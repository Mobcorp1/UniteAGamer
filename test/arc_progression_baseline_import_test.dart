// Controlled SDK doubles follow arc_marker_single_update_test.dart.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_progression_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_progression_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_season_reset_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart';

const _scrappyPath = 'users/player/arc_scrappy_progress/current';
const _seasonPath = 'users/player/arc_season_state/current';
String _benchPath(String station) =>
    'users/player/arc_bench_progress/${ArcProgressionEngine.benchIdFor(station)}';

class _User extends Fake implements User {
  @override
  String get uid => 'player';
}

class _Auth extends Fake implements FirebaseAuth {
  _Auth({this.signedIn = true});
  final bool signedIn;

  @override
  User? get currentUser => signedIn ? _User() : null;
}

class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _Document(this.path);
  @override
  final String path;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _Collection('$path/$collectionPath');
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.path);
  @override
  final String path;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Document('${this.path}/$path');
}

class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.value);
  final Map<String, dynamic>? value;

  @override
  bool get exists => value != null;

  @override
  Map<String, dynamic>? data() => value;
}

class _Transaction extends Fake implements Transaction {
  _Transaction(this.db);
  final _Db db;
  final pending = <String, Map<String, dynamic>>{};

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> ref,
  ) async {
    // Any resource, Operations or reward read fails this focused fake.
    expect(
      ref.path == _scrappyPath ||
          ref.path == _seasonPath ||
          ref.path.startsWith('users/player/arc_bench_progress/'),
      isTrue,
      reason: ref.path,
    );
    expect(pending, isEmpty, reason: 'Firestore reads must precede writes.');
    db.reads.add(ref.path);
    final data = db.documents[ref.path];
    return _Snapshot(data == null ? null : {...data}) as DocumentSnapshot<T>;
  }

  @override
  Transaction set<T>(DocumentReference<T> ref, T data, [SetOptions? options]) {
    expect(options?.merge, isTrue);
    expect(
      ref.path == _scrappyPath ||
          ref.path.startsWith('users/player/arc_bench_progress/'),
      isTrue,
      reason: 'Only the existing progression document may be written.',
    );
    pending[ref.path] = {
      ...?db.documents[ref.path],
      ...Map<String, dynamic>.from(data as Map),
    };
    return this;
  }
}

class _Db extends Fake implements FirebaseFirestore {
  final documents = <String, Map<String, dynamic>>{};
  final reads = <String>[];
  final writes = <String>[];
  void Function()? beforeRetry;
  bool failCommit = false;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    expect(path, 'users');
    return _Collection(path);
  }

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    var transaction = _Transaction(this);
    var result = await transactionHandler(transaction);
    final retry = beforeRetry;
    if (retry != null) {
      beforeRetry = null;
      retry();
      transaction = _Transaction(this);
      result = await transactionHandler(transaction);
    }
    if (failCommit) throw StateError('Persistence failed');
    documents.addAll(transaction.pending);
    writes.addAll(transaction.pending.keys);
    return result;
  }
}

class _OperationsGuard extends Fake implements ArcOperationsRepository {
  final calls = <Symbol>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName);
    throw StateError('Baseline must never call Operations.');
  }
}

class _BaselineRepository extends ArcProgressionRepository {
  _BaselineRepository(_Db db, _OperationsGuard operations, {_Auth? auth})
    : super(
        firestore: db,
        auth: auth ?? _Auth(),
        operationsRepository: operations,
      );

  int confirmationCalls = 0;

  @override
  Future<bool> confirmScrappyUpgrade({
    required int level,
    required Map<String, ArcScrappyState> scrappyStates,
  }) async {
    confirmationCalls++;
    throw StateError('Baseline must not confirm an upgrade.');
  }

  @override
  Future<bool> confirmBenchUpgrade({
    required String station,
    required int level,
    required Map<String, ArcScrappyState> scrappyStates,
  }) async {
    confirmationCalls++;
    throw StateError('Baseline must not confirm an upgrade.');
  }
}

void main() {
  late _Db db;
  late _OperationsGuard operations;
  late _BaselineRepository repository;

  setUp(() {
    db = _Db();
    operations = _OperationsGuard();
    repository = _BaselineRepository(db, operations);
  });
  tearDown(() {
    expect(operations.calls, isEmpty);
    expect(repository.confirmationCalls, 0);
  });

  test(
    'Scrappy imports level 3 from level 1 without resources or rewards',
    () async {
      db.documents[_scrappyPath] = const ArcScrappyProgressionState(
        seasonId: 'existing-season',
      ).toMap();
      expect(await repository.setScrappyBaseline(level: 3), isTrue);
      final state = ArcScrappyProgressionState.fromMap(
        db.documents[_scrappyPath],
      );
      expect(state.currentLevel, 3);
      expect(state.maximumLevelReachedThisSeason, 3);
      expect(state.historicalMaximumLevel, 3);
      expect(state.seasonId, 'existing-season');
      expect(state.completedLevelIds, isEmpty);
      expect(db.reads, [_scrappyPath]);
      expect(db.writes, [_scrappyPath]);

      final saved = {...db.documents[_scrappyPath]!};
      expect(await repository.setScrappyBaseline(level: 2), isFalse);
      expect(await repository.setScrappyBaseline(level: 3), isFalse);
      expect(db.documents[_scrappyPath], saved);
      expect(db.writes, [_scrappyPath]);
    },
  );

  test(
    'Scrappy level 1 is a valid initial baseline using the current season',
    () async {
      db.documents[_seasonPath] = {'currentSeasonId': 'current-season'};
      expect(await repository.setScrappyBaseline(level: 1), isTrue);
      final state = ArcScrappyProgressionState.fromMap(
        db.documents[_scrappyPath],
      );
      expect(state.currentLevel, 1);
      expect(state.seasonId, 'current-season');
      expect(state.completedLevelIds, isEmpty);
      expect(await repository.setScrappyBaseline(level: 1), isFalse);
      expect(db.writes, [_scrappyPath]);
    },
  );

  test(
    'Scrappy preserves higher maxima, season and existing completion metadata',
    () async {
      db.documents[_seasonPath] = {'currentSeasonId': 'different-season'};
      db.documents[_scrappyPath] = {
        ...const ArcScrappyProgressionState(
          seasonId: 'original-season',
          maximumLevelReachedThisSeason: 4,
          historicalMaximumLevel: 5,
          completedLevelIds: {'previous-completion'},
        ).toMap(),
        'futureMetadata': 'preserve',
      };
      expect(await repository.setScrappyBaseline(level: 3), isTrue);
      final state = ArcScrappyProgressionState.fromMap(
        db.documents[_scrappyPath],
      );
      expect(state.maximumLevelReachedThisSeason, 4);
      expect(state.historicalMaximumLevel, 5);
      expect(state.seasonId, 'original-season');
      expect(state.completedLevelIds, {'previous-completion'});
      expect(db.documents[_scrappyPath]!['futureMetadata'], 'preserve');
    },
  );

  test(
    'Explosives Station imports level 3 without resources or completion credit',
    () async {
      const station = 'Explosives Station';
      final benchId = ArcProgressionEngine.benchIdFor(station);
      final path = _benchPath(station);
      db.documents[path] = ArcBenchProgressionRecord(
        benchId: benchId,
        station: station,
        seasonId: 'existing-season',
        currentLevel: 1,
      ).toMap();
      expect(
        await repository.setBenchBaseline(station: station, level: 3),
        isTrue,
      );
      final record = ArcBenchProgressionRecord.fromMap(
        benchId,
        db.documents[path]!,
      );
      expect(record.benchId, benchId);
      expect(record.station, station);
      expect(record.currentLevel, 3);
      expect(record.maximumLevelReachedThisSeason, 3);
      expect(record.historicalMaximumLevel, 3);
      expect(record.seasonId, 'existing-season');
      expect(record.completedLevelIds, isEmpty);
      expect(db.reads, [path]);
      expect(db.writes, [path]);

      final saved = {...db.documents[path]!};
      expect(
        await repository.setBenchBaseline(station: station, level: 2),
        isFalse,
      );
      expect(
        await repository.setBenchBaseline(station: station, level: 3),
        isFalse,
      );
      expect(db.documents[path], saved);
      expect(db.writes, [path]);
    },
  );

  test(
    'bench baseline preserves higher maxima, season and existing metadata',
    () async {
      const station = 'Explosives Station';
      final benchId = ArcProgressionEngine.benchIdFor(station);
      final path = _benchPath(station);
      db.documents[_seasonPath] = {'currentSeasonId': 'different-season'};
      db.documents[path] = {
        ...ArcBenchProgressionRecord(
          benchId: benchId,
          station: station,
          seasonId: 'original-season',
          currentLevel: 1,
          maximumLevelReachedThisSeason: 3,
          historicalMaximumLevel: 3,
          completedLevelIds: {'previous-completion'},
        ).toMap(),
        'futureMetadata': 'preserve',
      };
      expect(
        await repository.setBenchBaseline(station: station, level: 2),
        isTrue,
      );
      final record = ArcBenchProgressionRecord.fromMap(
        benchId,
        db.documents[path]!,
      );
      expect(record.maximumLevelReachedThisSeason, 3);
      expect(record.historicalMaximumLevel, 3);
      expect(record.seasonId, 'original-season');
      expect(record.completedLevelIds, {'previous-completion'});
      expect(db.documents[path]!['futureMetadata'], 'preserve');
    },
  );

  test(
    'each canonical station can initialise a baseline with canonical ID',
    () async {
      db.documents[_seasonPath] = {'currentSeasonId': 'current-season'};
      final definitions = const ArcProgressionEngine().benchDefinitions;
      for (final station in definitions.map((d) => d.station).toSet()) {
        final level = definitions.firstWhere((d) => d.station == station).level;
        expect(
          await repository.setBenchBaseline(
            station: ' $station ',
            level: level,
          ),
          isTrue,
        );
        final data = db.documents[_benchPath(station)]!;
        expect(data['station'], station);
        expect(data['benchId'], ArcProgressionEngine.benchIdFor(station));
        expect(data['seasonId'], 'current-season');
        expect(data['completedLevelIds'], isEmpty);
      }
    },
  );

  test(
    'missing season document uses the existing default season policy',
    () async {
      expect(await repository.setScrappyBaseline(level: 2), isTrue);
      expect(
        await repository.setBenchBaseline(station: 'Refiner', level: 1),
        isTrue,
      );
      expect(
        db.documents[_scrappyPath]!['seasonId'],
        ArcSeasonResetPolicy.defaultCurrentSeasonId,
      );
      expect(
        db.documents[_benchPath('Refiner')]!['seasonId'],
        ArcSeasonResetPolicy.defaultCurrentSeasonId,
      );
    },
  );

  test(
    'unknown stations and invalid levels are rejected without writes',
    () async {
      for (final station in [
        'Unknown Station',
        'workbench',
        'in_raid',
        'weapon_bench',
        '',
      ]) {
        await expectLater(
          repository.setBenchBaseline(station: station, level: 1),
          throwsArgumentError,
        );
      }
      const engine = ArcProgressionEngine();
      final scrappyMax = engine.scrappyDefinitions
          .map((d) => d.level)
          .reduce((a, b) => a > b ? a : b);
      for (final level in [-1, 0, scrappyMax + 1]) {
        await expectLater(
          repository.setScrappyBaseline(level: level),
          throwsArgumentError,
        );
      }
      final benchMax = engine.benchDefinitions
          .where((d) => d.station == 'Explosives Station')
          .map((d) => d.level)
          .reduce((a, b) => a > b ? a : b);
      for (final level in [-1, 0, benchMax + 1]) {
        await expectLater(
          repository.setBenchBaseline(
            station: 'Explosives Station',
            level: level,
          ),
          throwsArgumentError,
        );
      }
      expect(db.reads, isEmpty);
      expect(db.writes, isEmpty);
      expect(db.documents, isEmpty);
    },
  );

  test('signed-out imports do not read or write progression', () async {
    repository = _BaselineRepository(
      db,
      operations,
      auth: _Auth(signedIn: false),
    );
    expect(await repository.setScrappyBaseline(level: 3), isFalse);
    expect(
      await repository.setBenchBaseline(station: 'Refiner', level: 3),
      isFalse,
    );
    expect(db.reads, isEmpty);
    expect(db.writes, isEmpty);
  });

  for (final scrappy in [true, false]) {
    test(
      '${scrappy ? 'Scrappy' : 'bench'} retry preserves concurrently stored higher level',
      () async {
        final path = scrappy ? _scrappyPath : _benchPath('Explosives Station');
        db.documents[path] = scrappy
            ? const ArcScrappyProgressionState(
                seasonId: 'existing-season',
              ).toMap()
            : ArcBenchProgressionRecord(
                benchId: ArcProgressionEngine.benchIdFor('Explosives Station'),
                station: 'Explosives Station',
                seasonId: 'existing-season',
              ).toMap();
        final concurrent = {
          ...db.documents[path]!,
          'currentLevel': 3,
          'maximumLevelReachedThisSeason': 3,
          'historicalMaximumLevel': 3,
        };
        db.beforeRetry = () => db.documents[path] = concurrent;
        final changed = scrappy
            ? await repository.setScrappyBaseline(level: 2)
            : await repository.setBenchBaseline(
                station: 'Explosives Station',
                level: 2,
              );
        expect(changed, isFalse);
        expect(db.documents[path], concurrent);
        expect(db.writes, isEmpty);
      },
    );
  }

  test(
    'persistence failure propagates without creating a baseline or rewards',
    () async {
      db.failCommit = true;
      await expectLater(
        repository.setScrappyBaseline(level: 3),
        throwsStateError,
      );
      await expectLater(
        repository.setBenchBaseline(station: 'Explosives Station', level: 3),
        throwsStateError,
      );
      expect(db.documents, isEmpty);
      expect(db.writes, isEmpty);
    },
  );
}
