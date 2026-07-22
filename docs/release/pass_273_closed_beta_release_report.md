# PASS 273 Closed Beta Release Report

Repository: Mobcorp1/UniteAGamer  
Branch: beta-stabilisation  
Pass: PASS 273 - Blueprint game view, web login and Closed Beta final QA

## Executive Summary

PASS 273 closes the final high-value usability items identified for the Closed Beta candidate without starting a broader redesign.

Release recommendation: Conditional Go for a controlled Closed Beta after hosted manual smoke testing. The local implementation, tests, analyzer and builds are expected to remain clean; production launch still requires Firebase deploy validation, hosted web login confirmation, notification worker confirmation and real-device smoke checks.

## Implemented In This Pass

- Restored the Blueprint Tracker no-preference default to Full Grid Overview while preserving the optional In-Game Framed View.
- Preserved the existing in-game view behaviour, authoritative order, filters, zoom, jump controls, ads and ownership/duplicate state.
- Added browser-recognised autofill hints for login, registration and password reset email fields.
- Grouped auth credential fields with Flutter `AutofillGroup` so browser credential managers can recognise sign-in and sign-up forms.
- Kept password fields secure with obscured text, disabled suggestions and existing Firebase auth flow.
- Added focused coverage for auth autofill hint definitions and updated Blueprint view-mode default coverage.
- Added Closed Beta release report, manual QA checklist and post-beta backlog.

## Build And Test Status

| Check | Status | Notes |
| --- | --- | --- |
| dart format `lib test` | Passed | 426 files checked, 0 changed. |
| flutter analyze | Passed | No issues found. |
| flutter test | Passed | 210 tests passed. |
| Functions optional test script | Passed | Existing optional script exited cleanly. |
| Functions optional lint script | Passed | Existing optional script exited cleanly. |
| `node --check functions/index.js` | Passed | Function entrypoint syntax check passed. |
| web release build | Passed | `build\web` produced successfully. |
| Android debug build | Passed | `build\app\outputs\flutter-apk\app-debug.apk` produced successfully. |
| `git diff --check` | Passed | No whitespace errors. |

## Deployment Requirements

- Deploy Firebase Hosting after final approval so the current web build, service worker and hosting headers are live.
- Deploy Firestore rules/indexes when the release owner is ready to promote the latest rule/index state.
- Deploy Cloud Functions for notification schedule processing and feedback reminder automation from PASS 272.
- Confirm Firebase Cloud Scheduler is enabled for scheduled notification processing.
- Confirm web push VAPID configuration is available in the deployed environment.
- Confirm Android notification permission and channel behaviour on a real beta device.
- Do not send real broadcast notifications during release validation unless Mike explicitly authorises the send.

## Manual Test Status

Manual QA remains required on hosted web and real/mobile devices because local automated builds cannot prove browser credential-manager behaviour, push token registration, Android notification delivery or live Firebase permissions.

Priority manual checks are recorded in `docs/release/pass_273_manual_qa_checklist.md`.

## Known Limitations

- Web credential-manager recognition must be verified in Chrome after deployment.
- Cloud Functions and Scheduler behaviour requires Firebase deploy and a real scheduled run.
- Push notification delivery must be verified against live FCM tokens.
- Some advanced matchmaking, social verification and inventory automation remain intentionally post-beta.
- Admin editor surfaces remain limited to current safe tooling.
- Player Locker Pro and broader social/pro progression are still scoped conservatively for Closed Beta.

## Go / No-Go Recommendation

Recommendation: Conditional Go for a limited, monitored Closed Beta after the final validation commands pass and the manual hosted smoke checklist is completed.

No-Go triggers:

- Any analyzer issue, failing test, or failed web/Android build.
- Hosted web login cannot sign in, register or reset password.
- Command Centre does not load as the post-login home route.
- Blueprint Tracker ownership or duplicate state regresses.
- Notification registration or PASS 272 schedule writes fail in live Firebase QA.
- Firestore rules/index deploy is not approved for the release environment.

## Release Owner Notes

- Full Grid remains the safe default for Blueprint Tracker; In-Game View is optional and persisted per user.
- Existing users with a saved Blueprint view preference keep that preference.
- `/my-hub` continues to route to Command Centre, with the old My Hub available through the secondary Tool Deck route.
- This pass intentionally avoids broad visual redesign and avoids changing protected Blueprint Tile/grid state logic.
