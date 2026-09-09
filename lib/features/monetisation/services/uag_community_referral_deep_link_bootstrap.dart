import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../models/uag_community_referral_link.dart';
import '../repositories/uag_community_referral_attribution_repository.dart';

class UagCommunityReferralDeepLinkBootstrap {
  UagCommunityReferralDeepLinkBootstrap._();

  static final UagCommunityReferralDeepLinkBootstrap instance =
      UagCommunityReferralDeepLinkBootstrap._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UagCommunityReferralAttributionRepository _repository =
      UagCommunityReferralAttributionRepository();

  StreamSubscription<User?>? _authSubscription;
  UagCommunityReferralLink? _pending;
  String? _capturedForUid;
  bool _initialised = false;

  Future<void> initialise() async {
    if (_initialised) return;
    _initialised = true;

    // Web/PWA initial route. Native link events are owned by the single
    // Creator bootstrap listener and forwarded through captureRoute().
    captureRoute(Uri.base);

    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _capturePendingFor(user.uid);
      }
    });

    final current = _auth.currentUser;
    if (current != null) {
      await _capturePendingFor(current.uid);
    }
  }

  void captureWebRoute(Uri uri) => captureRoute(uri);

  void captureRoute(Uri uri) {
    final parsed = UagCommunityReferralLink.tryParse(uri);
    if (parsed == null) return;
    _pending ??= parsed;

    final current = _auth.currentUser;
    if (current != null) {
      _capturePendingFor(current.uid);
    }
  }

  Future<void> _capturePendingFor(String uid) async {
    final pending = _pending;
    if (pending == null || _capturedForUid == uid) return;
    if (pending.referrerUid == uid) {
      _pending = null;
      _capturedForUid = uid;
      return;
    }

    final captured = await _repository.captureForCurrentUser(pending);
    if (captured) {
      _pending = null;
    }
    _capturedForUid = uid;
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
  }
}
