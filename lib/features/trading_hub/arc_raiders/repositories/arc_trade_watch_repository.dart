import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArcTradeWatchRepository {
  ArcTradeWatchRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  Stream<Set<String>> watchInterests() async* {
    final uid = _uid;
    if (uid == null) { yield <String>{}; return; }
    final ref = _db.collection('trading_watch_preferences').doc(uid);
    if (!(await ref.get()).exists) {
      await ref.set({'tradeItemIds': <String>[], 'updatedAt': FieldValue.serverTimestamp()});
    }
    yield* ref.snapshots().map((snapshot) {
      final raw = snapshot.data()?['tradeItemIds'];
      if (raw is! List) return <String>{};
      return raw.whereType<String>().where((value) => value.isNotEmpty).toSet();
    });
  }

  Future<void> saveInterests(Set<String> ids) async {
    final uid = _uid;
    if (uid == null) throw StateError('Sign in to save trade interests.');
    await _db.collection('trading_watch_preferences').doc(uid).set({
      'tradeItemIds': (ids.toList()..sort()),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
