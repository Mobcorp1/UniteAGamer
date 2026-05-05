import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/raid_planner/models/raid_planner_models.dart';

class RaidPlannerRepository {
  RaidPlannerRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _targetCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('arc_blueprint_targets');
  }

  Stream<List<RaidBlueprintTarget>> watchTargets() {
    final uid = _uid;
    if (uid == null) return Stream<List<RaidBlueprintTarget>>.value(const <RaidBlueprintTarget>[]);

    return _targetCollection(uid).snapshots().map((snapshot) {
      final targets = snapshot.docs
          .map((doc) => RaidBlueprintTarget.fromMap(doc.data()))
          .where((target) => target.blueprintId.trim().isNotEmpty)
          .toList(growable: false);

      final sorted = List<RaidBlueprintTarget>.from(targets)
        ..sort((a, b) {
          final tierCompare = a.tier.index.compareTo(b.tier.index);
          if (tierCompare != 0) return tierCompare;
          final rankCompare = a.rank.compareTo(b.rank);
          if (rankCompare != 0) return rankCompare;
          return a.blueprintId.compareTo(b.blueprintId);
        });
      return sorted;
    });
  }

  Stream<RaidPlannerEntitlement> watchEntitlement() {
    final uid = _uid;
    if (uid == null) {
      return Stream.value(const RaidPlannerEntitlement(tier: RaidPlannerTier.free));
    }

    return _firestore.collection('users').doc(uid).snapshots().map(
          (snapshot) => RaidPlannerEntitlement.fromUserMap(snapshot.data()),
        );
  }

  Future<void> saveTarget(RaidBlueprintTarget target) async {
    final uid = _uid;
    if (uid == null) throw Exception('You must be signed in.');
    final now = DateTime.now();
    final currentDoc = await _targetCollection(uid).doc(target.blueprintId).get();
    final normalized = target.copyWith(
      createdAt: target.createdAt ??
          (currentDoc.data()?['createdAt'] as Timestamp?)?.toDate() ??
          now,
      updatedAt: now,
    );
    await _targetCollection(uid)
        .doc(target.blueprintId)
        .set(normalized.toMap(), SetOptions(merge: true));
  }

  Future<void> removeTarget(String blueprintId) async {
    final uid = _uid;
    if (uid == null) throw Exception('You must be signed in.');
    await _targetCollection(uid).doc(blueprintId).delete();
  }

  Future<void> clearTargets() async {
    final uid = _uid;
    if (uid == null) throw Exception('You must be signed in.');
    final snapshot = await _targetCollection(uid).get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> seedDefaultTargets() async {
    // Intentionally no-op: targets must be selected by the user, not auto-seeded.
  }
}
