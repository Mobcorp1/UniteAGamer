import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/uag_community_growth_snapshot.dart';

class UagCommunityGrowthRepository {
  UagCommunityGrowthRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('app_config').doc('community_growth');

  Stream<UagCommunityGrowthSnapshot> watch() {
    return _ref.snapshots().map((snapshot) {
      final data = snapshot.data() ?? const <String, dynamic>{};
      return UagCommunityGrowthSnapshot.fromMap(data);
    });
  }

  Future<void> adminSetQualifiedActiveUsers(int users) async {
    if (users < 0) {
      throw StateError('Qualified active users cannot be negative.');
    }
    await _ref.set(<String, dynamic>{
      'qualifiedActiveUsers': users,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtIso': DateTime.now().toUtc().toIso8601String(),
    }, SetOptions(merge: true));
  }
}
