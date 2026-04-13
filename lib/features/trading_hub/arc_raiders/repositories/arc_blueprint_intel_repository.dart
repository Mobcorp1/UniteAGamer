import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:uag_traders_hub/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart';

class ArcBlueprintIntelRepository {
  ArcBlueprintIntelRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reportsCollection =>
      _firestore.collection('arc_blueprint_drop_reports');

  Stream<List<ArcBlueprintDropReport>> watchReportsForBlueprint(
    String blueprintId, {
    int limit = 100,
  }) {
    return _reportsCollection
        .where('blueprintId', isEqualTo: blueprintId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ArcBlueprintDropReport.fromMap(doc.data()))
              .toList(growable: false),
        );
  }

  Future<List<ArcBlueprintDropReport>> getReportsForBlueprint(
    String blueprintId, {
    int limit = 100,
  }) async {
    final snapshot = await _reportsCollection
        .where('blueprintId', isEqualTo: blueprintId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => ArcBlueprintDropReport.fromMap(doc.data()))
        .toList(growable: false);
  }
}
