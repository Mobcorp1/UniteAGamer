import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/arc_beta_feedback.dart';
import 'arc_operations_repository.dart';

class ArcBetaFeedbackRepository {
  ArcBetaFeedbackRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String requireUserId() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in before sending closed-beta feedback.');
    }
    return uid;
  }

  Future<String> submit(ArcBetaFeedbackSubmission submission) async {
    if (submission.uid != requireUserId()) {
      throw StateError(
        'Feedback can only be submitted for the signed-in user.',
      );
    }

    final document = _firestore.collection('beta_feedback').doc();
    await document.set({'id': document.id, ...submission.toFirestore()});
    await ArcOperationsRepository(
      firestore: _firestore,
      auth: _auth,
    ).recordFeedbackSubmitted();
    return document.id;
  }
}
