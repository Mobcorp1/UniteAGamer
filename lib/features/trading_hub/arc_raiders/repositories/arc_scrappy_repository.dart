import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_bench_upgrade_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/data/arc_scrappy_seed_data.dart';
import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_scrappy_state.dart';

class ArcScrappyRepository {
  ArcScrappyRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _collection = 'arc_scrappy_states';

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('No signed-in user available for Scrappy tracker.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _statesRef =>
      _firestore.collection('users').doc(_uid).collection(_collection);

  Stream<Map<String, ArcScrappyState>> watchMyScrappyStates() {
    return _statesRef.snapshots().map((snapshot) {
      final map = <String, ArcScrappyState>{};
      for (final doc in snapshot.docs) {
        final raw = Map<String, dynamic>.from(doc.data());
        final updated = raw['updatedAt'];
        if (updated is Timestamp) {
          raw['updatedAt'] = updated.toDate();
        }
        map[doc.id] = ArcScrappyState.fromJson(raw, itemId: doc.id);
      }
      return map;
    });
  }

  Future<void> saveScrappyState(
    ArcScrappyState state, {
    int? neededCount,
  }) async {
    final resolvedNeeded = neededCount ?? _neededCountFor(state.itemId);

    await _statesRef.doc(state.itemId).set(
          state.copyWith(updatedAt: DateTime.now()).toJson(neededCount: resolvedNeeded),
          SetOptions(merge: true),
        );
  }

  int _neededCountFor(String itemId) {
    for (final item in ArcScrappySeedData.items) {
      if (item.id == itemId) return item.neededCount;
    }
    for (final item in ArcBenchUpgradeSeedData.items) {
      if (item.id == itemId) return item.neededCount;
    }
    return 1;
  }

  Future<void> resetAllScrappyStates(Iterable<String> itemIds) async {
    final batch = _firestore.batch();
    for (final itemId in itemIds) {
      batch.delete(_statesRef.doc(itemId));
    }
    await batch.commit();
  }
}
