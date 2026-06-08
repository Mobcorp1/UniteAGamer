# Pass 88 - Onboarding + App Lock Security Fix

Applied security and onboarding fixes after new-account testing.

## Included
- Added Android biometric permissions.
- Updated MainActivity to FlutterFragmentActivity for local_auth compatibility.
- Added UagAppLockGate.
- Wrapped HomeScreen behind app lock when biometric login is enabled.
- Strengthened biometric enable flow so users must authenticate before enabling it.
- Added sign-out fallback from the app lock screen.
- Reduced onboarding overflow risk.
- Reworked onboarding option cards so non-selected cards no longer look like broken radio buttons.
- Added stronger tactical selected-card styling.

## Preserved
- Firebase auth flow.
- Firestore onboarding writes.
- App routing.
- Blueprint grid logic.
- Tracker logic.
- Carousel logic.
- Raid Planner logic.
- Trading systems.
- AdMob / GDPR config.
