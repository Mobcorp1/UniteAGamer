# Pass 89 v3 - Registration Flow Repair

Applied a parse-safe registration/security repair pass.

## Fixed
- AppEntryGate no longer traps users on an endless spinner when user profile reads hit permission-denied/unavailable.
- Signup-created profiles now bypass the older duplicate onboarding flow.
- Auth signup marks onboardingComplete as true because the create-account flow already collects the core profile.
- Onboarding cards no longer display misleading hard-selected states.
- App lock sign-out remains manual only and is labelled as password fallback.
- Android biometric permission declarations are ensured.

## Preserved
- No tracker logic changed.
- No blueprint grid logic changed.
- No carousel logic changed.
- No trading logic changed.
- No raid planner logic changed.
- No Firestore rules changed.
