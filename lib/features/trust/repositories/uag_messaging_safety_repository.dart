import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:uag_arc_raiders_hub/features/trust/models/uag_messaging_safety_models.dart';

class UagMessagingSafetyRepository {
  UagMessagingSafetyRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _blocks =>
      _firestore.collection('uag_user_blocks');

  CollectionReference<Map<String, dynamic>> get _outbox =>
      _firestore.collection('uag_message_outbox');

  CollectionReference<Map<String, dynamic>> get _messageReports =>
      _firestore.collection('uag_message_reports');

  CollectionReference<Map<String, dynamic>> get _conversationReports =>
      _firestore.collection('uag_conversation_reports');

  Future<void> blockUser(String blockedUid, {String reason = ''}) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Sign in before blocking a user.');
    if (uid == blockedUid) throw StateError('You cannot block yourself.');
    final id = UagUserBlock.idFor(uid, blockedUid);
    await _blocks.doc(id).set(<String, dynamic>{
      'id': id,
      'blockerUid': uid,
      'blockedUid': blockedUid,
      'reason': reason.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> unblockUser(String blockedUid) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Sign in before unblocking a user.');
    await _blocks.doc(UagUserBlock.idFor(uid, blockedUid)).delete();
  }

  Future<String> queueMessage({
    required String recipientUid,
    required String body,
    String conversationId = '',
    String contextType = 'direct_message',
    String contextId = '',
    String clientRequestId = '',
  }) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Sign in before sending a message.');
    if (uid == recipientUid) {
      throw StateError('Messages need a different recipient.');
    }
    final trimmed = body.trim();
    if (trimmed.isEmpty) throw StateError('Message cannot be empty.');
    final doc = _outbox.doc();
    final request = UagMessageOutboxRequest(
      id: doc.id,
      senderUid: uid,
      recipientUid: recipientUid,
      body: trimmed,
      conversationId: conversationId,
      contextType: contextType,
      contextId: contextId,
      clientRequestId: clientRequestId,
    );
    await doc.set(<String, dynamic>{
      ...request.toCreateMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<String> reportMessage({
    required String messageId,
    required String reportedUid,
    required String category,
    required String detail,
  }) async {
    final uid = currentUid;
    if (uid == null) throw StateError('Sign in before reporting a message.');
    final doc = _messageReports.doc();
    await doc.set(<String, dynamic>{
      'id': doc.id,
      'reporterUid': uid,
      'reportedUid': reportedUid,
      'messageId': messageId,
      'category': category.trim(),
      'detail': detail.trim(),
      'status': 'submitted',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<String> reportConversation({
    required String conversationId,
    required String reportedUid,
    required String category,
    required String detail,
  }) async {
    final uid = currentUid;
    if (uid == null) {
      throw StateError('Sign in before reporting a conversation.');
    }
    final doc = _conversationReports.doc();
    await doc.set(<String, dynamic>{
      'id': doc.id,
      'reporterUid': uid,
      'reportedUid': reportedUid,
      'conversationId': conversationId,
      'category': category.trim(),
      'detail': detail.trim(),
      'status': 'submitted',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }
}
