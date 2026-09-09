import 'package:flutter_test/flutter_test.dart';

import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_live_models.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_referral_terms_policy.dart';

void main() {
  test('Creator dashboard reads authoritative aggregate field names', () {
    final dashboard =
        UagCreatorLiveDashboard.fromMap('creator-1', <String, dynamic>{
          'essentialActiveSubscribers': 3,
          'premiumActiveSubscribers': 2,
          'creatorPoints': 6,
          'pendingCommissionPence': 1250,
        });

    expect(dashboard.essentialSubscribers, 3);
    expect(dashboard.premiumSubscribers, 2);
    expect(dashboard.creatorPoints, 6);
    expect(dashboard.pendingCommissionPence, 1250);
  });

  test('Referral terms policy has a versioned public launch contract', () {
    expect(UagReferralTermsPolicy.version, isNotEmpty);
    expect(UagReferralTermsPolicy.requiredPrinciples, isNotEmpty);
  });
}
