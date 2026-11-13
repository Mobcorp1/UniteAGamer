import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/arc_blueprint_demand.dart';

class ArcBlueprintDemandRepository {
  ArcBlueprintDemandRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('arc_blueprint_demand');

  Stream<ArcBlueprintDemand> watchDemand(String blueprintId) {
    return _collection.doc(blueprintId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return ArcBlueprintDemand.empty(blueprintId);
      }
      return ArcBlueprintDemand.fromMap(data);
    });
  }

  Future<ArcBlueprintDemand> getDemand(String blueprintId) async {
    final doc = await _collection.doc(blueprintId).get();
    final data = doc.data();
    if (data == null) {
      return ArcBlueprintDemand.empty(blueprintId);
    }
    return ArcBlueprintDemand.fromMap(data);
  }

  Future<void> upsertDemand({
    required String blueprintId,
    required int wantedCount,
    required int tradeableCount,
    String? lastReportedMap,
    String? lastReportedLocation,
    String? lastReportedCondition,
  }) async {
    final demand = ArcBlueprintDemand(
      blueprintId: blueprintId,
      wantedCount: wantedCount,
      tradeableCount: tradeableCount,
      lastReportedMap: lastReportedMap,
      lastReportedLocation: lastReportedLocation,
      lastReportedCondition: lastReportedCondition,
      updatedAt: DateTime.now(),
    );

    await _collection
        .doc(blueprintId)
        .set(demand.toMap(), SetOptions(merge: true));
  }

  Future<void> updateCounts({
    required String blueprintId,
    int wantedDelta = 0,
    int tradeableDelta = 0,
  }) async {
    await _collection.doc(blueprintId).set({
      'blueprintId': blueprintId,
      'wantedCount': FieldValue.increment(wantedDelta),
      'tradeableCount': FieldValue.increment(tradeableDelta),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }
}
