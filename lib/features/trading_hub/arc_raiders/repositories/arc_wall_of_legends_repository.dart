import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/arc_wall_of_legends_models.dart';

class ArcWallOfLegendsRepository {
  ArcWallOfLegendsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _entries =>
      _firestore.collection('wall_of_legends');

  Stream<List<ArcWallOfLegendsEntry>> watchEntries() {
    return _entries.snapshots().map((snapshot) {
      final entries =
          snapshot.docs
              .map(
                (doc) => ArcWallOfLegendsEntry.fromMap(
                  doc.data(),
                  fallbackId: doc.id,
                ),
              )
              .where((entry) => entry.isVisible)
              .toList(growable: false)
            ..sort(compareEntries);
      return entries;
    });
  }

  static int compareEntries(ArcWallOfLegendsEntry a, ArcWallOfLegendsEntry b) {
    final categoryCompare = a.category.sortOrder.compareTo(
      b.category.sortOrder,
    );
    if (categoryCompare != 0) return categoryCompare;
    final sortCompare = a.sortOrder.compareTo(b.sortOrder);
    if (sortCompare != 0) return sortCompare;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  }
}
