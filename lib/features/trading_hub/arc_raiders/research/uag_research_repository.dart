import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/trade_items_data.dart';
import 'uag_research_catalogue.dart';

class UagResearchProgress {
  const UagResearchProgress({required this.stage, required this.collected, required this.pointsCollected});
  final int stage; // 0 not started, 1 step one, 2 step two, 3 completed
  final Map<String, int> collected;
  final int pointsCollected;
  factory UagResearchProgress.fromMap(Map<String, dynamic>? raw) {
    final values = raw ?? const <String, dynamic>{};
    final collected = <String, int>{};
    final source = values['collected'];
    if (source is Map) {
      for (final item in source.entries) {
        if (item.key is String && item.value is num) {
          collected[item.key as String] = (item.value as num).toInt().clamp(0, 999999);
        }
      }
    }
    return UagResearchProgress(
      stage: ((values['stage'] as num?)?.toInt() ?? 0).clamp(0, 3),
      collected: collected,
      pointsCollected: ((values['pointsCollected'] as num?)?.toInt() ?? 0).clamp(0, 999999),
    );
  }
  Map<String, dynamic> toMap() => <String, dynamic>{
    'stage': stage, 'collected': collected, 'pointsCollected': pointsCollected,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
class UagResearchRepository {
  UagResearchRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  String? get uid => _auth.currentUser?.uid;
  Stream<Map<String, UagResearchProgress>> watchProgress() {
    final user = uid;
    if (user == null) return Stream.value(const <String, UagResearchProgress>{});
    return _db.collection('users').doc(user).collection('uag_research_progress')
        .snapshots().map((snapshot) => {
          for (final doc in snapshot.docs) doc.id: UagResearchProgress.fromMap(doc.data()),
        });
  }
  Future<void> save(String id, UagResearchProgress progress) async {
    final user = uid;
    if (user == null) throw StateError('Sign in to save research progress.');
    final collection = _db.collection('users').doc(user).collection('uag_research_progress');
    await collection.doc(id).set(progress.toMap(), SetOptions(merge: true));
    // Research-driven interests are kept separate from manual preferences.
    // A completed project no longer requests its research materials.
    final saved = await collection.get();
    final projects = {for (final doc in saved.docs) doc.id: UagResearchProgress.fromMap(doc.data())};
    final wantedNames = <String>{};
    for (final recipe in UagResearchCatalogue.recipes) {
      final state = projects[recipe.id];
      if (state == null || state.stage == 0 || state.stage == 3) continue;
      if (state.stage == 1 || state.stage == 2) {
        for (final item in recipe.materials) {
          if ((state.collected[item.name] ?? 0) < item.quantity) wantedNames.add(item.name.toLowerCase());
        }
      }
      // Crafting requirements apply after unlocking, and are therefore
      // not mixed with the Step 2 research materials.
    }
    final ids = ArcTradeItemsData.items
      .where((item) => wantedNames.contains(item.name.toLowerCase()))
      .map((item) => item.id).toSet().toList()..sort();
    await _db.collection('trading_watch_preferences').doc(user).set({
      'researchTradeItemIds': ids,
      'researchUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
