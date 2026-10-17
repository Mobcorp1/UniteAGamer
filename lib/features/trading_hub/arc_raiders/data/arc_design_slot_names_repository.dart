import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'arc_design_reference_catalogue.dart';

/// User-confirmed slot↔name links. Kept separate from ownership/dupes.
/// Firestore stores names under the existing owner-guarded users/{uid} doc.
class ArcDesignSlotNamesRepository {
  ArcDesignSlotNamesRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore, _auth = auth;

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  DocumentReference<Map<String, dynamic>> get _userDoc {
    final auth = _auth ?? FirebaseAuth.instance;
    final uid = auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in to save Design names.');
    }
    return (_firestore ?? FirebaseFirestore.instance).collection('users').doc(uid);
  }

  Future<Map<int, String>> read() async {
    final snapshot = await _userDoc.get();
    final raw = snapshot.data()?['uagCollectionsDesignNamesV1'];
    if (raw is! Map) return const <int, String>{};
    final mapped = <int,String>{};
    raw.forEach((key, value) {
      final slot = int.tryParse(key.toString());
      if (slot != null && slot >= 1 && slot <= 100 && value is String &&
          ArcDesignReferenceCatalogue.names.contains(value)) {
        mapped[slot] = value;
      }
    });
    return mapped;
  }

  Future<void> assign(int slot, String name) async {
    if (slot < 1 || slot > 100 ||
        !ArcDesignReferenceCatalogue.names.contains(name)) {
      throw ArgumentError('Unknown Design slot or name.');
    }
    await _userDoc.set({
      'uagCollectionsDesignNamesV1': {slot.toString(): name},
    }, SetOptions(merge: true));
  }
}
