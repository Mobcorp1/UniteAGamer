import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uag_arc_raiders_hub/features/legal/models/uag_policy_catalog.dart';

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
        'fanDisclaimerVersion': UagFanProjectNotice.version,
        'fanDisclaimerAcceptedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  Future<void> acceptPolicy({
    required String policyId,
    required int version,
    bool mandatory = true,
    bool optionalConsent = false,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'legalAccepted': {
        'policies': {
          policyId: {
            'accepted': true,
            'version': version,
            'mandatory': mandatory,
            'optionalConsent': optionalConsent,
            'acceptedAt': FieldValue.serverTimestamp(),
          },
        },
      },
    }, SetOptions(merge: true));
  }
}
