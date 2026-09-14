// Controlled SDK test doubles exercise the real repository transaction without a live Firebase project.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_raid_intelligence_models.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart';

class _User extends Fake implements User {
  @override
  String get uid => 'admin';
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  User get currentUser => _User();
}

class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.value, this.id);
  final Map<String, dynamic>? value;
  @override
  final String id;
  @override
  bool get exists => value != null;
  @override
  Map<String, dynamic>? data() => value;
}

class _Doc extends Fake implements DocumentReference<Map<String, dynamic>> {
  _Doc(this.id);
  @override
  final String id;
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _Doc(path!);
}

class _Transaction extends Fake implements Transaction {
  _Transaction(this.db);
  final _Db db;
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> ref,
  ) async => _Snapshot(db.stored, ref.id) as DocumentSnapshot<T>;
  @override
  Transaction update(DocumentReference ref, Map<Object, Object?> data) {
    if (db.fail) throw StateError('Write failed');
    db.updatedId = ref.id;
    db.patch = Map<String, dynamic>.from(data);
    db.stored = {...db.stored!, ...Map<String, dynamic>.from(data)};
    return this;
  }
}

class _Db extends Fake implements FirebaseFirestore {
  Map<String, dynamic>? stored;
  String? updatedId;
  Map<String, dynamic>? patch;
  bool fail = false;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    expect(path, ArcAdminMapEditorRepository.collectionName);
    return _Collection();
  }

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) => transactionHandler(_Transaction(this));
}

void main() {
  const marker = ArcAdminMapMarker(
    id: 'same_document',
    mapId: 'stella_montis',
    layer: ArcRaidMapLayer.surface,
    kind: ArcAdminMapMarkerKind.poi,
    name: 'Published POI',
    point: ArcNormalizedPoint(x: .3, y: .4),
    state: ArcAdminMapMarkerState.published,
    aliases: ['Historic POI'],
  );
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'repository transaction updates the same document with a field patch',
    () async {
      final db = _Db()
        ..stored = {...marker.toMap(), 'futureCanonicalLink': 'keep'};
      final repo = ArcAdminMapEditorRepository(firestore: db, auth: _Auth());
      final saved = await repo.updateMarker(
        original: marker,
        edited: marker.copyWith(layer: ArcRaidMapLayer.underground),
      );
      expect(db.updatedId, marker.id);
      expect(
        db.patch!.keys,
        unorderedEquals(['layer', 'updatedByUid', 'updatedAt']),
      );
      expect(db.stored!['futureCanonicalLink'], 'keep');
      expect(saved.state, ArcAdminMapMarkerState.published);
      expect(saved.point.toMap(), marker.point.toMap());
      expect(saved.layer, ArcRaidMapLayer.underground);
    },
  );
  test('persistence failure leaves original record untouched', () async {
    final db = _Db()
      ..stored = marker.toMap()
      ..fail = true;
    final repo = ArcAdminMapEditorRepository(firestore: db, auth: _Auth());
    await expectLater(
      repo.updateMarker(
        original: marker,
        edited: marker.copyWith(layer: ArcRaidMapLayer.underground),
      ),
      throwsStateError,
    );
    expect(db.stored, marker.toMap());
    expect(db.updatedId, isNull);
  });
  test(
    'pending local coordinates are retained instead of silently discarded',
    () async {
      final db = _Db()..stored = marker.toMap();
      final repo = ArcAdminMapEditorRepository(firestore: db, auth: _Auth());
      final local = marker.copyWith(
        point: const ArcNormalizedPoint(x: .8, y: .8),
      );
      await expectLater(
        repo.updateMarker(
          original: local,
          edited: local.copyWith(layer: ArcRaidMapLayer.underground),
        ),
        throwsStateError,
      );
      expect(db.updatedId, isNull);
      expect(db.stored, marker.toMap());
      expect(local.point.x, .8);
    },
  );
  test(
    'remote editable changes block the move without overwriting either version',
    () async {
      final remote = marker.copyWith(name: 'Published POI renamed remotely');
      final db = _Db()..stored = remote.toMap();
      final repo = ArcAdminMapEditorRepository(firestore: db, auth: _Auth());

      await expectLater(
        repo.updateMarker(
          original: marker,
          edited: marker.copyWith(layer: ArcRaidMapLayer.underground),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('reload'),
          ),
        ),
      );

      expect(db.updatedId, isNull);
      expect(db.stored, remote.toMap());
    },
  );

  test(
    'missing and concurrently moved records are not recreated or overwritten',
    () async {
      final db = _Db();
      final repo = ArcAdminMapEditorRepository(firestore: db, auth: _Auth());
      final edited = marker.copyWith(layer: ArcRaidMapLayer.underground);
      await expectLater(
        repo.updateMarker(original: marker, edited: edited),
        throwsStateError,
      );
      db.stored = edited.toMap();
      await expectLater(
        repo.updateMarker(original: marker, edited: edited),
        throwsStateError,
      );
      expect(db.updatedId, isNull);
    },
  );
}
