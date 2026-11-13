import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_reward_models.dart';

void main() {
  test('normalises creator codes safely', () {
    expect(normaliseCreatorCode(' drop-12 ab '), 'DROP12AB');
  });

  test('maps reward wire values', () {
    expect(
      UagCreatorRewardType.fromValue('premium_month'),
      UagCreatorRewardType.premiumMonth,
    );
    expect(UagCreatorRewardType.annualPremium.label, 'Annual Premium');
  });

  test('redemption states distinguish pending and validated', () {
    const pending = UagCreatorRedemptionClaim(
      code: 'DROP123456',
      status: 'pending_validation',
    );
    const validated = UagCreatorRedemptionClaim(
      code: 'DROP123456',
      status: 'validated_entitlement_pending',
    );
    expect(pending.pending, isTrue);
    expect(validated.validated, isTrue);
  });
}
