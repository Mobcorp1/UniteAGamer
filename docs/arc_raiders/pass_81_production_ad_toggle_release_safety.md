# Pass 81 - Production Ad Toggle + Release Safety Controls

Adds a double-lock safety model for AdMob production ads.

## Safety behaviour

- Test ads remain the default.
- Production banner IDs remain stored but blocked.
- Production ads require all release flags to be deliberately enabled.
- Production serving is also blocked while the consent gate is incomplete.

## Files touched

- lib/features/monetisation/ads/uag_admob_config.dart
- lib/features/monetisation/ads/uag_ad_release_safety.dart

## Release checklist added

The release safety checklist captures AdMob policy, GDPR/privacy, app-ads.txt, premium suppression, placement safety, and signed release QA requirements before production ads are enabled.

## Protected systems

No ARC tracker, blueprint grid, carousel, raid planner, trading, Firestore, loadout, ownership, or matchmaking logic changed.