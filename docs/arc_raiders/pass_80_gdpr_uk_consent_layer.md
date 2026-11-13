# Pass 80 - GDPR / UK Consent Layer

This pass adds a production-safety consent gate for advertising.

## What changed

- Added `UagAdConsentController`.
- Added AdMob config flags for UK/GDPR consent protection.
- Gated tactical banner ad requests behind consent state.
- Initialised consent controller at app startup.

## Safe default

Production ads remain blocked until a complete consent flow is implemented.
Local/test builds can still be enabled for internal testing through the consent controller.

## Preserved systems

No tracker, blueprint grid, carousel, raid planner, trading, Firestore, ownership, duplicate, or loadout logic was changed.

## Next pass

Pass 81 should add the real Google UMP consent form flow and the release toggle checks.
