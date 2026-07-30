# PASS 303 - Closed Beta Readiness

## Ready

- Command Centre remains the post-login home and now avoids duplicate Coming Soon recommendations for the same feature gate.
- Admin Feature Access remains the beta sandbox for Live, Coming Soon and Hidden.
- Direct route access for key controlled beta systems now respects Feature Access.
- Progress Trackers hub respects feature state and does not show Hidden tracker cards.
- Coming Soon screen wording is safer for deferred notification fan-out.
- Feedback categories cover beta triage basics.
- Admin diagnostics now show a standard-user closed-beta configuration summary and warnings.

## Needs Manual Testing

- New account registration into consent and onboarding.
- Consent blocking and route recovery after refresh.
- Onboarding on Android portrait, Android landscape and web.
- Reduced feature set where only Blueprint, Bench and Scrappy are Live.
- Profile & Reputation save/return flows.
- Blueprint Tracker mobile landscape controls and web layout.
- Bench and Scrappy tracker card density.
- Standard-user direct route attempts to Hidden features.
- Logout and login as another account on the same device.

## Deferred Post-Beta Or Later

- Admin Blueprint Catalogue and safe grid editor.
- Blueprint image upload and camera capture.
- Full server-side feature-live push fan-out.
- Feedback screenshots or media upload.
- New trading, matchmaking, Rat, Voice Assistant or Raid Intelligence functionality.

## Known Limitations

- Coming Soon interest is currently expressed through Personalisation/Settings and queued feature-live intents; this pass does not guarantee push delivery.
- Admin diagnostics are read-only and intended for authorised admin surfaces.
- Same-device multi-account testing can still be affected by browser/device auth persistence; do not weaken auth isolation to work around this.
- Manual Firebase rules/index validation remains required before a wider beta.

## Recommended Manual Test Flow

Use `docs/testing/closed_beta_2_manual_test_checklist.md` for a screen-by-screen work-break checklist.

## Go / No-Go Recommendation

Provisional Go for a restricted Closed Beta 2 after manual QA confirms onboarding, consent, direct-route gating, standard-user feature visibility and tracker responsiveness on target devices.
