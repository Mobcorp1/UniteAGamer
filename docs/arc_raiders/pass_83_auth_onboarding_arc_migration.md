# Pass 83 - Auth / Onboarding ARC Migration

This pass prepares the auth and onboarding layer for ARC command-centre visual migration without changing authentication, Firestore, routing, profile-save, terms, or privacy logic.

## Files detected
- lib/build/splash_screen.dart

## Safety
- No auth logic changed
- No Firestore logic changed
- No account creation logic changed
- No terms/privacy text rewritten
- No route rewiring

## Next direct pass
Pass 84 should target the detected files directly after visual inspection of current auth/onboarding screens.
