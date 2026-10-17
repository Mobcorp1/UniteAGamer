import 'package:firebase_auth/firebase_auth.dart';
import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/services/uag_trade_invite_service.dart';

import '../models/uag_community_referral_link.dart';

class UagCommunityReferralAttributionRepository {
  UagCommunityReferralAttributionRepository({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<bool> captureForCurrentUser(UagCommunityReferralLink link) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || !link.isValid || link.referrerUid == uid) return false;
    // Client writes to attribution ledgers are no longer permitted. The
    // server verifies code ownership, signup eligibility and idempotency.
    final response = await UagTradeInviteService.instance.claimLegacy(
      referrerUid: link.referrerUid.trim(), code: link.normalizedCode);
    return response['status'] == 'captured';
  }
}
