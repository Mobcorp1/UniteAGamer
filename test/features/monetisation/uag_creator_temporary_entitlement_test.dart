import 'package:flutter_test/flutter_test.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_creator_temporary_entitlement.dart';
import 'package:uag_arc_raiders_hub/features/monetisation/models/uag_subscription_tier.dart';

void main() {
  test('active Essential creator reward lifts Free to Essential', () {
    final now = DateTime.now().toUtc();
    final grant = UagCreatorTemporaryEntitlement(
      grantId: 'creator_test',
      tier: UagSubscriptionTier.essential,
      startedAt: now.subtract(const Duration(minutes: 1)),
      expiresAt: now.add(const Duration(days: 7)),
      sourceCode: 'DROPTEST',
      sourceClaimPath: 'users/u/monetisation_usage/c',
    );
    expect(
      highestCreatorRewardTier([grant], UagSubscriptionTier.free),
      UagSubscriptionTier.essential,
    );
  });

  test('creator reward never downgrades an underlying Premium tier', () {
    final now = DateTime.now().toUtc();
    final grant = UagCreatorTemporaryEntitlement(
      grantId: 'creator_test',
      tier: UagSubscriptionTier.essential,
      startedAt: now.subtract(const Duration(minutes: 1)),
      expiresAt: now.add(const Duration(days: 7)),
      sourceCode: 'DROPTEST',
      sourceClaimPath: 'users/u/monetisation_usage/c',
    );
    expect(
      highestCreatorRewardTier([grant], UagSubscriptionTier.premium),
      UagSubscriptionTier.premium,
    );
  });

  test('expired creator reward falls back to underlying tier', () {
    final now = DateTime.now().toUtc();
    final grant = UagCreatorTemporaryEntitlement(
      grantId: 'creator_test',
      tier: UagSubscriptionTier.premium,
      startedAt: now.subtract(const Duration(days: 8)),
      expiresAt: now.subtract(const Duration(seconds: 1)),
      sourceCode: 'DROPTEST',
      sourceClaimPath: 'users/u/monetisation_usage/c',
    );
    expect(
      highestCreatorRewardTier([grant], UagSubscriptionTier.free),
      UagSubscriptionTier.free,
    );
  });

  test('next expiry returns the earliest future creator reward expiry', () {
    final now = DateTime.now().toUtc();
    final early = UagCreatorTemporaryEntitlement(
      grantId: 'early',
      tier: UagSubscriptionTier.essential,
      startedAt: now.subtract(const Duration(minutes: 1)),
      expiresAt: now.add(const Duration(hours: 1)),
      sourceCode: 'A',
      sourceClaimPath: 'a',
    );
    final late = UagCreatorTemporaryEntitlement(
      grantId: 'late',
      tier: UagSubscriptionTier.premium,
      startedAt: now.subtract(const Duration(minutes: 1)),
      expiresAt: now.add(const Duration(hours: 2)),
      sourceCode: 'B',
      sourceClaimPath: 'b',
    );
    expect(nextCreatorRewardExpiry([late, early]), early.expiresAt);
  });
}
