import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_referral_link.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/services/uag_community_referral_deep_link_bootstrap.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/repositories/uag_creator_referral_repository.dart';

class UagCreatorReferralBootstrap {
  UagCreatorReferralBootstrap._();

  static final UagCreatorReferralBootstrap instance =
      UagCreatorReferralBootstrap._();

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  UagCreatorReferralLink? _initialReferral;
  String? _capturedForUid;
  bool _initialised = false;

  Future<void> initialise() async {
    if (_initialised) {
      return;
    }
    _initialised = true;

    // Preserve the web/PWA/default-route bootstrap before native events arrive.
    readInitialReferral();

    try {
      _appLinks = AppLinks();
      _linkSubscription = _appLinks!.uriLinkStream.listen(
        _handleIncomingUri,
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Creator native deep-link stream failed: $error');
          debugPrintStack(stackTrace: stackTrace);
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Creator native deep-link bootstrap failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  UagCreatorReferralLink? readInitialReferral() {
    if (_initialReferral != null) {
      return _initialReferral;
    }

    final candidates = <Uri>[Uri.base];

    final routeName =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    if (routeName.trim().isNotEmpty && routeName != '/') {
      final parsed = Uri.tryParse(routeName);
      if (parsed != null) {
        candidates.add(parsed);
      }
    }

    for (final candidate in candidates) {
      final referral = UagCreatorReferralLink.tryParse(candidate);
      if (referral != null) {
        _rememberReferral(referral);
        return referral;
      }
    }
    return null;
  }

  Future<void> _handleIncomingUri(Uri uri) async {
    UagCommunityReferralDeepLinkBootstrap.instance.captureRoute(uri);
    final referral = UagCreatorReferralLink.tryParse(uri);
    if (referral == null) {
      return;
    }

    _rememberReferral(referral);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await captureForSignedInUser(user.uid);
    }
  }

  void _rememberReferral(UagCreatorReferralLink referral) {
    _initialReferral = referral;
    debugPrint(
      'Creator referral detected for '
      '${referral.creatorUid} / ${referral.normalizedCode}.',
    );
  }

  Future<void> captureForSignedInUser(String uid) async {
    if (uid.trim().isEmpty || _capturedForUid == uid) {
      return;
    }

    final referral = readInitialReferral();
    if (referral == null) {
      return;
    }

    try {
      await UagCreatorReferralRepository().capturePendingReferral(referral);
      _capturedForUid = uid;
    } catch (error, stackTrace) {
      debugPrint('Creator referral capture failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @visibleForTesting
  void resetForTest() {
    _initialReferral = null;
    _capturedForUid = null;
    _initialised = false;
    unawaited(_linkSubscription?.cancel());
    _linkSubscription = null;
    _appLinks = null;
  }
}
