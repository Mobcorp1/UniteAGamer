import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'arc_amplification_state.dart';

/// Stores a single per-user document in a dedicated research collection.
/// The project's existing owner-only recursive /users/{uid} rule covers it.
/// It never writes to Favourite Loadout or any cross-user collection.
class ArcAmplificationRepository {
  ArcAmplificationRepository({FirebaseFirestore? firestore,FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  DocumentReference<Map<String,dynamic>> _document() {
    final uid=_auth.currentUser?.uid;
    if(uid == null || uid.isEmpty) throw StateError('Sign in to sync amplification research.');
    return _firestore.collection('users').doc(uid).collection('arc_amplification_research').doc('state');
  }
  Stream<ArcAmplificationState> watch() {
    try {
      return _document().snapshots().map((snap)=>ArcAmplificationState.fromMap(snap.data()?['progress'] is Map<String,dynamic> ? snap.data()!['progress'] as Map<String,dynamic> : null));
    } on StateError {
      return Stream<ArcAmplificationState>.error(StateError('Sign in to sync research progress.'));
    }
  }
  Future<ArcAmplificationState> update(ArcAmplificationState Function(ArcAmplificationState) mutate) async {
    final doc=_document();
    return _firestore.runTransaction<ArcAmplificationState>((transaction) async {
      final snapshot=await transaction.get(doc);
      final raw=snapshot.data()?['progress'];
      final current=ArcAmplificationState.fromMap(raw is Map<String,dynamic> ? raw : null);
      final next=mutate(current);
      transaction.set(doc,<String,dynamic>{'schemaVersion':1,'progress':next.toMap()},SetOptions(merge:true));
      return next;
    });
  }
}
