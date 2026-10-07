// Controlled SDK doubles exercise the actual repository write paths.
// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_progression_engine.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/data/arc_quest_catalogue.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_progression_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_raider_setup_repository.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_saved_loadout_repository.dart';
import 'arc_raider_setup_evaluator_test.dart' show setupProfile;

class _User extends Fake implements User {
  @override
  String get uid => 'player';
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User get currentUser => _User();
}

class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.value);
  final Map<String, dynamic>? value;
  @override
  bool get exists => value != null;
  @override
  Map<String, dynamic>? data() => value == null ? null : Map.from(value!);
}

class _QueryDoc extends _Snapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _QueryDoc(this.id, super.value);
  @override
  final String id;
  @override
  Map<String, dynamic> data() => super.data()!;
}

class _QuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  _QuerySnapshot(this.docs);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

class _Doc extends Fake implements DocumentReference<Map<String, dynamic>> {
  _Doc(this.db, this.path);
  final _Db db;
  @override
  final String path;
  @override
  String get id => path.split('/').last;
  @override
  CollectionReference<Map<String, dynamic>> collection(String name) =>
      _Collection(db, '$path/$name');
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _Snapshot(db.values[path]);
  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async =>
      db.put(path, data, options?.merge == true);
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.db, this.path);
  final _Db db;
  @override
  final String path;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) =>
      _Doc(db, '$path/$id');
  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _QuerySnapshot([
    for (final e in db.values.entries)
      if (e.key.startsWith('$path/') &&
          e.key.split('/').length == path.split('/').length + 1)
        _QueryDoc(e.key.split('/').last, e.value),
  ]);
}

class _Batch extends Fake implements WriteBatch {
  _Batch(this.db);
  final _Db db;
  final List<void Function()> pending = [];
  @override
  void set<T>(DocumentReference<T> ref, T data, [SetOptions? options]) =>
      pending.add(
        () => db.put(
          ref.path,
          Map<String, dynamic>.from(data as Map),
          options?.merge == true,
        ),
      );
  @override
  Future<void> commit() async {
    for (final write in pending) {
      write();
    }
  }
}

class _Transaction extends Fake implements Transaction {
  _Transaction(this.db);
  final _Db db;
  final List<void Function()> pending = [];
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> ref,
  ) async => _Snapshot(db.values[ref.path]) as DocumentSnapshot<T>;
  @override
  Transaction set<T>(DocumentReference<T> ref, T data, [SetOptions? options]) {
    pending.add(
      () => db.put(
        ref.path,
        Map<String, dynamic>.from(data as Map),
        options?.merge == true,
      ),
    );
    return this;
  }

  @override
  Transaction update(DocumentReference ref, Map<Object, Object?> data) {
    pending.add(() {
      db.values[ref.path] = {
        ...?db.values[ref.path],
        ...Map<String, dynamic>.from(data),
      };
      db.writes.add(ref.path);
    });
    return this;
  }
}

class _Db extends Fake implements FirebaseFirestore {
  final values = <String, Map<String, dynamic>>{};
  final writes = <String>[];
  @override
  CollectionReference<Map<String, dynamic>> collection(String name) =>
      _Collection(this, name);
  @override
  WriteBatch batch() => _Batch(this);
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    final tx = _Transaction(this);
    final value = await handler(tx);
    for (final write in tx.pending) {
      write();
    }
    return value;
  }

  void put(String path, Map<String, dynamic> data, bool merge) {
    Map<String, dynamic> combine(
      Map<String, dynamic> left,
      Map<String, dynamic> right,
    ) => {
      ...left,
      for (final e in right.entries)
        e.key: e.value is Map && left[e.key] is Map
            ? combine(
                Map<String, dynamic>.from(left[e.key] as Map),
                Map<String, dynamic>.from(e.value as Map),
              )
            : e.value,
    };
    values[path] = merge ? combine(values[path] ?? {}, data) : data;
    writes.add(path);
  }
}

class _Operations extends Fake implements ArcOperationsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
    'No Operations/reward credit during baseline: ${invocation.memberName}',
  );
}

class _Blueprints extends Fake implements ArcBlueprintRepository {
  Map<String, ArcBlueprintState> states = {};
  @override
  Future<Map<String, ArcBlueprintState>> loadMyBlueprintStates() async =>
      states;
}

void main() {
  late _Db db;
  late ArcRaiderSetupRepository repository;
  late _Blueprints blueprints;
  setUp(() {
    db = _Db();
    blueprints = _Blueprints();
    db.values['users/player'] = {
      'displayName': 'Kept identity',
      'legalAccepted': {'termsAccepted': true, 'privacyAccepted': true},
    };
    repository = ArcRaiderSetupRepository(
      firestore: db,
      auth: _Auth(),
      blueprints: blueprints,
      progression: ArcProgressionRepository(
        firestore: db,
        auth: _Auth(),
        operationsRepository: _Operations(),
      ),
    );
  });
  test(
    'actual quest import infers prerequisites without Operations or reward completion timestamps',
    () async {
      const current = 'quest-chain-shani-clearer-skies';
      await repository.setQuestPosition({current});
      final prerequisite = db
          .values['users/player/arc_quest_progress/${ArcQuestCatalogue.rootQuestId}']!;
      expect(prerequisite['status'], 'completed');
      expect(prerequisite['completedAt'], isNull);
      expect(prerequisite['rewardsGrantedAt'], isNull);
      expect(
        db.values['users/player/arc_quest_state/current']!['trackedQuestIds'],
        [current],
      );
      expect(db.writes.every((p) => p.contains('/arc_quest_')), isTrue);
    },
  );
  test(
    'Scrappy and every canonical bench use baseline imports, preserve existing levels',
    () async {
      final engine = const ArcProgressionEngine();
      final level = engine.scrappyDefinitions.last.level;
      await repository.setScrappyLevel(level);
      await repository.setScrappyLevel(1);
      expect(
        db.values['users/player/arc_scrappy_progress/current']!['currentLevel'],
        level,
      );
      final levels = {
        for (final d in engine.benchDefinitions) d.station: d.level,
      };
      await repository.setBenchLevels(levels);
      for (final e in levels.entries) {
        final data = db
            .values['users/player/arc_bench_progress/${ArcProgressionEngine.benchIdFor(e.key)}']!;
        expect(data['currentLevel'], e.value);
        expect(data['completedLevelIds'], isEmpty);
      }
      final before = db.writes.length;
      await expectLater(
        repository.setBenchLevels({'Invented bench': 99}),
        throwsArgumentError,
      );
      expect(db.writes.length, before);
    },
  );
  test(
    'zero Blueprints, unbuilt benches, starting Scrappy and deferred loadout persist without fake ownership',
    () async {
      db.values['users/player/trading_activity/profile'] = setupProfile;
      db.values['users/player/trading_activity/availability'] = {
        'scheduleType': 'flexible',
        'completed': true,
      };
      await expectLater(repository.complete(), throwsStateError);
      await repository.confirmNoBlueprints();
      await repository.deferLoadout();
      await repository.setScrappyLevel(1);
      await repository.setBenchLevels({
        for (final d in const ArcProgressionEngine().benchDefinitions)
          d.station: 0,
      });
      await repository.confirmNoActiveQuests();
      await repository.complete();
      expect((await repository.load()).status.needsSetup, isFalse);
      expect(db.values['users/player']!['displayName'], 'Kept identity');
      expect(db.values['users/player']!['legalAccepted'], {
        'termsAccepted': true,
        'privacyAccepted': true,
      });
      expect(
        db.writes.any(
          (p) =>
              p.contains('arc_blueprints') ||
              p.contains('operations') ||
              p.contains('arc_saved_loadouts'),
        ),
        isFalse,
      );
    },
  );
  test(
    'a default favourite document does not become a configured loadout through model defaults',
    () async {
      final loadouts = ArcSavedLoadoutRepository(firestore: db, auth: _Auth());
      db.values['users/player/arc_saved_loadouts/favourite-loadout'] = {};
      expect(await loadouts.hasConfiguredFavouriteLoadout(), isFalse);
      db.values['users/player/arc_saved_loadouts/favourite-loadout'] = {
        'primaryWeapon': 'Anvil',
        'updatedAt': '2026-10-05T00:00:00Z',
      };
      expect(await loadouts.hasConfiguredFavouriteLoadout(), isTrue);
    },
  );
  test(
    'confirmations from an older season are not reactivated by a new confirmation',
    () async {
      db.values['users/player']!['arcRaiderSetup'] = {
        'seasonId': 'old',
        'confirmationVersion': 1,
        'noBlueprintsConfirmed': true,
        'scrappyStartingConfirmed': true,
      };
      await repository.deferLoadout();
      final data = db.values['users/player']!['arcRaiderSetup'] as Map;
      expect(data['noBlueprintsConfirmed'], isNull);
      expect(data['scrappyStartingConfirmed'], isNull);
    },
  );
  test(
    'admin role keeps privileges but must complete and may write Raider Setup',
    () async {
      db.values['users/player']!['isAdmin'] = true;
      final initial = await repository.load();
      expect(initial.status.preview, isFalse);
      expect(initial.status.needsSetup, isTrue);

      await repository.setQuestPosition({ArcQuestCatalogue.rootQuestId});
      await repository.setScrappyLevel(1);
      await repository.deferLoadout();

      expect(db.values['users/player']!['isAdmin'], isTrue);
      expect(
        db.values['users/player/arc_quest_state/current']!['trackedQuestIds'],
        [ArcQuestCatalogue.rootQuestId],
      );
      expect(
        (db.values['users/player']!['arcRaiderSetup']
            as Map)['loadoutDeferred'],
        isTrue,
      );
    },
  );
}
