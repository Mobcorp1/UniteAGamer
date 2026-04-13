
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LegalRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  Future<Map<String, dynamic>> getLegal() async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['legalAccepted'] ?? {};
  }

  Future<void> acceptFanDisclaimer() async {
    await _firestore.collection('users').doc(uid).set({
      'legalAccepted': {
        'fanDisclaimerAccepted': true,
        'fanDisclaimerVersion': 1,
        'fanDisclaimerAcceptedAt': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));
  }
}
