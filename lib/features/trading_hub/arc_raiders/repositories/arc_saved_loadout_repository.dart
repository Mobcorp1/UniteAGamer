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

  Stream<List<ArcSavedLoadout>> watchSavedLoadouts() {
    final collection = _collection;
    if (collection == null) {
      return Stream<List<ArcSavedLoadout>>.value(const <ArcSavedLoadout>[]);
    }

    return collection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ArcSavedLoadout.fromMap(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  Stream<ArcSavedLoadout?> watchFavouriteLoadout() {
    final collection = _collection;
    if (collection == null) {
      return Stream<ArcSavedLoadout?>.value(null);
    }

    return collection.doc('favourite-loadout').snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return ArcSavedLoadout.fromMap(snapshot.id, data);
    });
  }

  Future<ArcSavedLoadout?> loadFavouriteLoadout() async {
    final collection = _collection;
    if (collection == null) return null;

    final snapshot = await collection.doc('favourite-loadout').get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return ArcSavedLoadout.fromMap(snapshot.id, data);
  }

  Future<void> saveLoadout(ArcSavedLoadout loadout) async {
    final collection = _collection;
    if (collection == null) {
      throw StateError('User must be signed in to save loadouts.');
    }

    await collection
        .doc(loadout.id)
        .set(loadout.toMap(), SetOptions(merge: true));
    await ArcOperationsRepository(
      firestore: _firestore,
      auth: _auth,
    ).recordFavouriteLoadoutSaved();
  }

  Future<void> deleteLoadout(String id) async {
    final collection = _collection;
    if (collection == null) {
      throw StateError('User must be signed in to delete loadouts.');
    }

    await collection.doc(id).delete();
  }
}
