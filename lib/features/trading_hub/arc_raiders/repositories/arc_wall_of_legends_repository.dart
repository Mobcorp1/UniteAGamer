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

  Future<ArcWallOfLegendsEntry?> getEntry(String entryId) async {
    final id = entryId.trim();
    if (id.isEmpty) return null;
    final snapshot = await _entries.doc(id).get();
    if (!snapshot.exists) return null;
    return ArcWallOfLegendsEntry.fromMap(
      snapshot.data() ?? const <String, dynamic>{},
      fallbackId: snapshot.id,
    );
  }

  Future<void> upsertEntry(
    ArcWallOfLegendsEntry entry, {
    String? inductedByUid,
  }) async {
    final id = entry.id.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(entry.id, 'entry.id', 'Legend ID is required.');
    }
    if (entry.displayName.trim().isEmpty) {
      throw ArgumentError.value(
        entry.displayName,
        'entry.displayName',
        'Display name is required.',
      );
    }

    final ref = _entries.doc(id);
    final existing = await ref.get();
    final data = entry.toMap()
      ..remove('createdAt')
      ..remove('updatedAt');
    data.addAll(<String, dynamic>{
      'networkScope': 'unite_a_gamer',
      'sourceProduct': 'arc_raiders_hub',
      'updatedAt': FieldValue.serverTimestamp(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      if (!existing.exists) 'inductedAt': FieldValue.serverTimestamp(),
      if (inductedByUid != null && inductedByUid.trim().isNotEmpty)
        'inductedByUid': inductedByUid.trim(),
    });
    await ref.set(data, SetOptions(merge: true));
  }

  Future<void> deleteEntry(String entryId) async {
    final id = entryId.trim();
    if (id.isEmpty) return;
    await _entries.doc(id).delete();
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
