import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:uag_arc_raiders_hub/features/auth/session/uag_session_gate_controller.dart';

class UagAccountDeletionException implements Exception {
  const UagAccountDeletionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UagAccountDeletionReceipt {
  const UagAccountDeletionReceipt({
    required this.receiptId,
    required this.retainedCategories,
  });

  final String receiptId;
  final List<String> retainedCategories;
}

class UagAccountDeletionService {
  UagAccountDeletionService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    http.Client? client,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _client = client ?? http.Client();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final http.Client _client;

  Future<UagAccountDeletionReceipt> deleteCurrentAccount({
    required String password,
    required String typedConfirmation,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email?.trim() ?? '';

    if (user == null || email.isEmpty) {
      throw const UagAccountDeletionException(
        'Sign in again before deleting your account.',
      );
    }
    if (password.isEmpty) {
      throw const UagAccountDeletionException(
        'Enter your current password to continue.',
      );
    }
    if (typedConfirmation.trim() != 'DELETE') {
      throw const UagAccountDeletionException(
        'Type DELETE exactly to confirm permanent account deletion.',
      );
    }

    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    } on FirebaseAuthException catch (error) {
      throw UagAccountDeletionException(_authMessage(error.code));
    } catch (_) {
      throw const UagAccountDeletionException(
        'We could not confirm your password. Check your connection and try again.',
      );
    }

    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw const UagAccountDeletionException(
        'Your secure session could not be refreshed. Sign in again and retry.',
      );
    }

    final projectId = _firestore.app.options.projectId;
    if (projectId.isEmpty) {
      throw const UagAccountDeletionException(
        'Account deletion is temporarily unavailable. Please use Support.',
      );
    }

    http.Response response;
    try {
      response = await _client
          .post(
            Uri.https(
              'us-central1-$projectId.cloudfunctions.net',
              '/deleteUagAccount',
            ),
            headers: <String, String>{
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, Object>{
              'data': <String, String>{'confirmation': 'DELETE'},
            }),
          )
          .timeout(const Duration(seconds: 315));
    } catch (_) {
      throw const UagAccountDeletionException(
        'The deletion service could not be reached. Your account has not been confirmed as deleted. Retry, or use Support if the problem continues.',
      );
    }

    Map<String, dynamic> decoded;
    try {
      final body = jsonDecode(response.body);
      decoded = body is Map
          ? Map<String, dynamic>.from(body)
          : <String, dynamic>{};
    } catch (_) {
      decoded = <String, dynamic>{};
    }

    if (response.statusCode != 200 || decoded['error'] != null) {
      throw UagAccountDeletionException(_serviceMessage(decoded['error']));
    }

    final rawResult = decoded['result'] ?? decoded['data'];
    if (rawResult is! Map || rawResult['deleted'] != true) {
      throw const UagAccountDeletionException(
        'The deletion service did not confirm completion. Retry, or use Support if the problem continues.',
      );
    }

    final result = Map<String, dynamic>.from(rawResult);
    final retained = result['retainedCategories'];

    await UagSessionGateController.clearAccountAndDeviceState();
    try {
      await _auth.signOut();
    } catch (_) {
      // The server has already removed the Auth user. Local persisted state was
      // cleared above, so a sign-out transport/plugin failure is non-blocking.
    }

    return UagAccountDeletionReceipt(
      receiptId: (result['receiptId'] as String?)?.trim() ?? '',
      retainedCategories: retained is Iterable
          ? retained.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
    );
  }

  static String _authMessage(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'That password is not correct.';
      case 'too-many-requests':
        return 'Too many verification attempts. Try again later.';
      case 'network-request-failed':
        return 'Your password could not be verified because the network is unavailable.';
      case 'user-disabled':
      case 'user-not-found':
        return 'This account is no longer available. Sign out and contact Support if needed.';
      default:
        return 'We could not confirm your password. Sign in again and retry.';
    }
  }

  static String _serviceMessage(dynamic rawError) {
    if (rawError is Map) {
      final error = Map<String, dynamic>.from(rawError);
      final status = (error['status'] ?? error['code'] ?? '')
          .toString()
          .toLowerCase();
      if (status.contains('unauthenticated')) {
        return 'Your secure session expired. Sign in again before deleting your account.';
      }
      if (status.contains('failed-precondition')) {
        return 'Confirm your password again before deleting your account.';
      }
      if (status.contains('invalid-argument')) {
        return 'Type DELETE exactly to confirm permanent account deletion.';
      }
    }
    return 'Account deletion could not be completed. Retry, or use Support if the problem continues.';
  }
}
