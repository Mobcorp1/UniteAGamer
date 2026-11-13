import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_reward_activation_policy.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_reward_models.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_tier.dart';

void main() {
  test(
    'Essential rewards map to Essential and Premium rewards map to Premium',
    () {
      expect(
        UagCreatorRewardActivationPolicy.tierFor(
          UagCreatorRewardType.essential7Day,
        ),
        UagSubscriptionTier.essential,
      );
      expect(
        UagCreatorRewardActivationPolicy.tierFor(
          UagCreatorRewardType.essentialMonth,
        ),
        UagSubscriptionTier.essential,
      );
      expect(
        UagCreatorRewardActivationPolicy.tierFor(
          UagCreatorRewardType.premium7Day,
        ),
        UagSubscriptionTier.premium,
      );
      expect(
        UagCreatorRewardActivationPolicy.tierFor(
          UagCreatorRewardType.annualPremium,
        ),
        UagSubscriptionTier.premium,
      );
    },
  );

  test('Reward durations remain 7, 30 and 365 days', () {
    expect(
      UagCreatorRewardActivationPolicy.durationFor(
        UagCreatorRewardType.premium7Day,
      ),
      const Duration(days: 7),
    );
    expect(
      UagCreatorRewardActivationPolicy.durationFor(
        UagCreatorRewardType.essentialMonth,
      ),
      const Duration(days: 30),
    );
    expect(
      UagCreatorRewardActivationPolicy.durationFor(
        UagCreatorRewardType.annualPremium,
      ),
      const Duration(days: 365),
    );
  });

  test('Lifecycle state moves from scheduled to active to expired', () {
    final start = DateTime.utc(2026, 9, 6, 12);
    final end = start.add(const Duration(days: 7));
    expect(
      UagCreatorRewardActivationPolicy.lifecycleState(
        startedAt: start,
        expiresAt: end,
        now: start.subtract(const Duration(seconds: 1)),
      ),
      'scheduled',
    );
    expect(
      UagCreatorRewardActivationPolicy.lifecycleState(
        startedAt: start,
        expiresAt: end,
        now: start.add(const Duration(hours: 1)),
      ),
      'active',
    );
    expect(
      UagCreatorRewardActivationPolicy.lifecycleState(
        startedAt: start,
        expiresAt: end,
        now: end,
      ),
      'expired',
    );
  });
}
