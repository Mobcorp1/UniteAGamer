import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/models/arc_loadout_models.dart';

import 'arc_operations_repository.dart';

class ArcSavedLoadoutRepository {
  ArcSavedLoadoutRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _collection {
    final uid = _uid;
    if (uid == null) return null;

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('arc_saved_loadouts');
  }

  // Keep Firestore listeners bound to the active signed-in account. Creating
  // a stream before Firebase restores Auth must not freeze its value at [].
  Stream<T> _watchAuthenticated<T>({
    required T signedOutValue,
    required Stream<T> Function(String uid) observe,
  }) {
    StreamSubscription<User?>? authSubscription;
    StreamSubscription<T>? dataSubscription;
    var generation = 0;
    late StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        authSubscription = _auth.authStateChanges().listen((user) async {
          final currentGeneration = ++generation;
          await dataSubscription?.cancel();
          dataSubscription = null;
          if (controller.isClosed || currentGeneration != generation) return;
          if (user == null) {
            controller.add(signedOutValue);
            return;
          }
          dataSubscription = observe(user.uid).listen(
            (value) {
              if (!controller.isClosed && currentGeneration == generation) {
                controller.add(value);
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!controller.isClosed && currentGeneration == generation) {
                controller.addError(error, stackTrace);
              }
            },
          );
        }, onError: (Object error, StackTrace stackTrace) {
          if (!controller.isClosed) controller.addError(error, stackTrace);
        });
      },
      onCancel: () async {
        generation++;
        await authSubscription?.cancel();
        await dataSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  Stream<List<ArcSavedLoadout>> watchSavedLoadouts() =>
      _watchAuthenticated<List<ArcSavedLoadout>>(
        signedOutValue: const <ArcSavedLoadout>[],
        observe: (uid) => _firestore
            .collection('users')
            .doc(uid)
            .collection('arc_saved_loadouts')
            // No orderBy: old saved records without updatedAt must not
            // disappear from Command Centre's persisted loadout query.
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => ArcSavedLoadout.fromMap(doc.id, doc.data()))
                .toList(growable: false)),
      );

  Stream<ArcSavedLoadout?> watchFavouriteLoadout() =>
      _watchAuthenticated<ArcSavedLoadout?>(
        signedOutValue: null,
        observe: (uid) => _firestore
            .collection('users')
            .doc(uid)
            .collection('arc_saved_loadouts')
            .doc('favourite-loadout').snapshots()
            .map((snapshot) {
              final data = snapshot.data();
              return snapshot.exists && data != null
                  ? ArcSavedLoadout.fromMap(snapshot.id, data)
                  : null;
            }),
      );

  Future<ArcSavedLoadout?> loadFavouriteLoadout() async {
    final collection = _collection;
    if (collection == null) return null;

    final snapshot = await collection.doc('favourite-loadout').get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return ArcSavedLoadout.fromMap(snapshot.id, data);
  }

  /// Checks persisted choices before model defaults are applied.
  Future<bool> hasConfiguredFavouriteLoadout() async {
    final collection = _collection;
    if (collection == null) return false;
    final data = (await collection.doc('favourite-loadout').get()).data();
    return data != null &&
        (data['primaryWeapon']?.toString().trim().isNotEmpty ?? false) &&
        (data['updatedAt'] != null || data['createdAt'] != null);
  }

  Future<void> saveLoadout(ArcSavedLoadout loadout) async {
    final collection = _collection;
    if (collection == null) {
      throw StateError('User must be signed in to save loadouts.');
    }

    await collection
        .doc(loadout.id)
        .set(loadout.toMap(), SetOptions(merge: true));
    // Saving the actual loadout succeeds independently of optional operations
    // telemetry. A telemetry outage must not report a successful save as failed.
    try {
      await ArcOperationsRepository(
        firestore: _firestore,
        auth: _auth,
      ).recordFavouriteLoadoutSaved();
    } on FirebaseException {
      // The user's saved document is already committed.
    }
  }

  Future<void> deleteLoadout(String id) async {
    final collection = _collection;
    if (collection == null) {
      throw StateError('User must be signed in to delete loadouts.');
    }

    await collection.doc(id).delete();
  }
}
