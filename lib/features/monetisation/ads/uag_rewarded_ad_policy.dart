import '../models/uag_ad_policy.dart';
import '../models/uag_subscription_tier.dart';

/// Disabled eligibility foundation, never an entitlement or reward grant.
/// Production must verify and atomically consume the cap on the server.
class UagRewardedAdPolicy {
  const UagRewardedAdPolicy({this.enabled = false});

  final bool enabled;
  static const maxDailyCompletions = 3;
  static const minimumInterval = Duration(minutes: 20);
  static const placementId = 'arc_optional_convenience_reward';

  bool canOffer({
    required UagAdPolicy policy,
    required bool signedIn,
    required bool consentGranted,
    required bool serverGrantReady,
    required bool explicitlyRequested,
    required int verifiedCompletionsToday,
    required DateTime now,
    DateTime? lastVerifiedCompletion,
  }) {
    if (!enabled ||
        !signedIn ||
        !consentGranted ||
        !serverGrantReady ||
        !explicitlyRequested ||
        policy.tier != UagSubscriptionTier.free ||
        !policy.showRewardedAds ||
        verifiedCompletionsToday < 0 ||
        verifiedCompletionsToday >= maxDailyCompletions) {
      return false;
    }
    return lastVerifiedCompletion == null ||
        now.difference(lastVerifiedCompletion) >= minimumInterval;
  }
}
