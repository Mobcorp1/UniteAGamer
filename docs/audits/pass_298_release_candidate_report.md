# PASS 298 Release Candidate Report

Date: 2026-07-28  
Baseline: `aa3363a14846de66a23510465f9ec6a9502df9d5`  
Pass: Release Candidate Deployment, Real-Service Wiring, Full UI Audit and Closed-Beta Defect Repair

## Executive Summary

PASS 298 completes the repository-side release-candidate hardening that can be done without private provider credentials, solicitor approval or physical-device access.

Release status: **CLOSED-BETA READY AFTER CONFIGURATION**.

The codebase now has:

- Java 21/Firebase emulator validation scripts.
- Separate release deployment stages for Hosting, Firestore rules, Firestore indexes, Storage rules and Functions.
- Storage rules configured in `firebase.json`.
- Secure Storage rules for screenshots, OCR sessions, evidence, creator content, profile media and legal exports.
- Age-gated Firestore create paths for messaging, trading, Match Rider, contracts, evidence metadata, image import, creator applications and payout/referral creation.
- Age-gated Stripe checkout session creation.
- Separate Founding Supporter backend subscription handling that does not grant Essential or Premium.
- Config-gated Google Cloud Natural Language moderation provider support.
- Safe provider-unavailable moderation state.
- Admin Console Release Readiness diagnostics.
- Local Blueprint photo overlap stitching and confidence gating without fake OCR.
- Focused tests for release config, readiness, legal operator config, local photo matching and moderation wire states.

No production deployment, OCR success, moderation-provider success, billing success or physical push delivery is claimed.

## Defect Register

| ID | Area | Severity | Platform | Current Behaviour | Expected Behaviour | Root Cause | Files Changed | Automated Test | Manual Test Required | Resolution State | Remaining Blocker | Configuration Owner |
|---|---|---:|---|---|---|---|---|---|---|---|---|---|
| P298-001 | Firebase emulator readiness | High | Dev machine | Rules emulator blocked on Java 17. | Clear Java 21 validation before emulator tests. | Firebase CLI requires Java 21. | `scripts/validate_release_environment.ps1`, `scripts/run_firebase_emulator_tests.ps1` | Static script guard test | Run after Java 21 install | Fixed repo-side | Java 21 install | Mike |
| P298-002 | Firebase Storage | Blocker | Firebase | No Storage rules target in repo config. | Storage rules deployable and secure. | `firebase.json` only declared Hosting/Firestore/Functions. | `firebase.json`, `storage.rules` | Static rules/config test | Deploy Storage rules | Fixed repo-side | Firebase deploy | Mike/Firebase |
| P298-003 | Firestore indexes | Medium | Firebase | Prior rejected index needed verification. | Rejected single-field coverage index absent. | Historical deploy failure. | `test/release/uag_release_configuration_test.dart` | Static index guard | Deploy indexes separately | Fixed | None repo-side | Firebase |
| P298-004 | Age gate | High | Firestore/Functions | Some restricted create paths only required auth. | Server-recorded 18+ state required. | PASS 297 added age verification but not every risky rule gate. | `firestore.rules`, `functions/index.js`, `trading/firestore-rules.test.js` | Rule fixture updated | Existing-user migration QA | Fixed repo-side | Users must verify | Mike |
| P298-005 | Messaging moderation provider | High | Functions | Deterministic moderation only. | Optional trusted backend provider path. | Provider credentials/config missing. | `functions/index.js`, `lib/features/trust/models/uag_messaging_safety_models.dart` | Model wire-state test, Node syntax | Configure and send provider health test | Fixed architecture | Google Cloud Natural Language setup | Firebase/Google Cloud |
| P298-006 | Provider failure | High | Functions | No external provider failure state. | Provider failure must not silently allow or permanently hide ordinary messages. | Provider path not present. | `functions/index.js` | Node syntax | Admin queue review | Fixed repo-side | Provider config | Firebase/Google Cloud |
| P298-007 | Founding Supporter billing | High | Functions | Backend had no separate supporter plan and old monthly pence values. | Supporter is separate from Essential/Premium. | Function plan config lagged Dart model. | `functions/index.js` | Node syntax | Stripe sandbox checkout/webhook | Fixed repo-side | Stripe price IDs | Stripe |
| P298-008 | Admin release readiness | Medium | Admin Console | Diagnostics did not show provider/config release blockers. | Admin/dev can see release readiness states. | No shared readiness model/panel. | `lib/features/release/**`, `lib/screens/build/admin_console_screen.dart`, `lib/screens/admin_console_screen.dart` | Model tests | Admin visual QA | Fixed repo-side | Firestore config values optional | Mike |
| P298-009 | Legal operator details | Blocker | Legal | No real operator details in repo. | Missing details must block production claims. | Details not supplied. | `lib/features/legal/models/uag_legal_operator_config.dart` | Model test | Solicitor/operator review | Diagnosed | Real legal identity | Mike/legal |
| P298-010 | Blueprint photo import OCR | High | Photo import | OCR provider not configured. | Local matching safe, cloud OCR optional/config-gated. | Provider not selected/configured. | `arc_blueprint_photo_local_matching_engine.dart` | Local matching tests | Real screenshot/device/provider QA | Partially fixed safely | OCR provider and fixtures | Firebase/Google Cloud |
| P298-011 | Release deployment automation | Medium | Dev machine/Firebase | No one-command staged release validation. | Safe script validates and deploys optional stages separately. | Prior ad hoc release commands. | `scripts/deploy_release_candidate.ps1` | Static script test | Dry run and deploy with credentials | Fixed repo-side | Secrets/project access | Mike |

## Firebase

Java:

- Repository script detects Java and fails clearly when `-RequireJava21` is used.
- Previous environment had Java 17. Emulator tests must not be claimed until Java 21 is installed.

Firestore:

- `arc_map_marker_coverage_reports` is not present in `firestore.indexes.json`.
- Firestore rule gates now require age verification on high-risk create paths.
- Emulator fixture updated for verified/unverified users.

Storage:

- `firebase.json` now includes `"storage": { "rules": "storage.rules" }`.
- `storage.rules` protects:
  - Blueprint screenshots.
  - OCR sessions.
  - Conduct evidence.
  - Message evidence.
  - Contract evidence.
  - Creator content.
  - Profile media.
  - Legal exports.
- Rules require authentication, owner paths or admin/moderator access, MIME allowlists, size limits and no executable uploads.

Functions:

- `node --check functions/index.js` is required before commit.
- `uagReleaseHealthCheck` exposes safe readiness metadata without secrets.
- Stripe secrets remain Firebase secret/env configuration, not source-controlled.

## Moderation

Provider selected for implementation: Google Cloud Natural Language `documents:moderateText`.

Official documentation used:

- Google Cloud Natural Language text moderation: `https://docs.cloud.google.com/natural-language/docs/moderating-text`
- REST method: `https://docs.cloud.google.com/natural-language/docs/reference/rest/v1/documents/moderateText`
- Firebase Functions configuration/secrets: `https://firebase.google.com/docs/functions/config-env`

Implemented:

- Config-gated provider architecture.
- Provider name, project, region, timeout and audit metadata.
- Metadata-server access token retrieval inside trusted backend only.
- Category/confidence mapping.
- Provider unavailable outcome.
- Deterministic severe matches still block/escalate before provider success is needed.

Configuration required:

- Enable Cloud Natural Language API.
- Ensure deployed function service account has access.
- Set `UAG_MODERATION_PROVIDER_ENABLED=true`.
- Set project/region/timeout values as required.
- Run live provider health and moderation QA.

## OCR And Blueprint Photo Import

Official documentation used:

- ML Kit Text Recognition v2: `https://developers.google.com/ml-kit/vision/text-recognition/v2`
- ML Kit Android Text Recognition: `https://developers.google.com/ml-kit/vision/text-recognition/v2/android`
- Cloud Vision OCR: `https://docs.cloud.google.com/vision/docs/ocr`

Implemented repository-side:

- Local row/cell stitching model for generated or detected cells.
- Overlap row deduplication.
- Conflict detection.
- Blank cell preservation.
- Candidate generation.
- Confidence gates.
- Session output remains preview-only until user confirmation.

Deferred/config required:

- Real image orientation/crop/perspective/image hashing must be connected to an authorised image processing provider or local plugin.
- Cloud OCR must be opt-in and disclosed.
- Real game screenshots must not be bundled unless authorised.

## Billing And Entitlements

Official documentation used:

- Google Play subscriptions: `https://developer.android.com/google/play/billing/subscriptions`
- Google Play Billing integration: `https://developer.android.google.cn/google/play/billing/integrate`
- Google Play payments policy: `https://support.google.com/googleplay/android-developer/answer/10281818`

Implemented:

- Backend monthly pence values aligned to Dart plan model:
  - Essential: 499 pence.
  - Premium: 799 pence.
  - Founding Supporter: 399 pence.
- Founding Supporter is a separate backend plan kind.
- Supporter writes to `supporter_entitlements/{uid}` and `users/{uid}.supporter`.
- Supporter does not set `users/{uid}.tier` to Premium/Essential.
- Checkout requires server-recorded 18+ verification.

Configuration required:

- Stripe price IDs for Essential, Premium and Founding Supporter.
- Stripe webhook secret.
- Stripe sandbox checkout and webhook QA.
- Google Play product IDs and server verification path before Play-distributed digital subscriptions.

## Notifications

Repository state preserved:

- Backend FCM fan-out and invalid token cleanup remain in `functions/index.js`.
- Admin broadcasts remain in Admin Console.
- Device token registration remains client-side.

Manual required:

- Foreground push.
- Background push.
- Terminated-app push.
- Deep-link opening.
- Invalid-token cleanup against real FCM responses.

## Voice

Repository state preserved:

- PASS 297 voice item relevance uses the Personal Item Intelligence engine.
- No voice write path was broadened in PASS 298.

Manual required:

- Microphone permission.
- Speech recognition availability.
- TTS output.
- Wake/cancel/repeat/stop speaking.
- Real-device confidence and locale QA.

## Age And Safety

Implemented:

- Checkout, messaging, trading, Match Rider, creator, contracts, image import/evidence metadata and payout/referral create paths now require server-recorded 18+ verification where practical.
- DOB minimisation from PASS 297 remains intact.

Manual required:

- Existing-user migration UX.
- Under-18 rejection copy.
- Appeal/support flow.

## Onboarding And UI

PASS 298 did not redesign onboarding or the whole app. The Admin release readiness panel was added without changing main navigation.

Manual QA checklist is in:

- `docs/audits/pass_298_manual_qa_checklist.md`

Responsive areas still requiring manual/device QA:

- Onboarding mobile Next flow.
- Command Centre compact hierarchy.
- Blueprint Tracker full grid and carousel modes.
- Favourite Loadout cards.
- Raid Intelligence maps/layers.
- Communications Centre.
- Subscription/Legal Hub.

## Legal

Centralised operator config model:

- `lib/features/legal/models/uag_legal_operator_config.dart`

Missing:

- Operator legal name.
- Trading name.
- Contact email.
- Service/contact address.
- Privacy contact.
- Copyright contact.
- Moderation contact.
- Billing support contact.
- Company number if applicable.

Legal review still required:

- Terms.
- Privacy.
- Creator/Affiliate terms.
- Subscription terms.
- Moderation and appeals.
- 18+ wording.
- OCR and voice privacy.
- ICO fee/registration assessment.
- Online Safety Act assessment.
- Play Store privacy/data safety disclosures.
- Accounting/tax and creator payout review.

## Performance And Security

Security fixes completed:

- Storage rules added.
- Firestore age gates expanded.
- Supporter entitlement separated from paid tier.
- Provider credentials stay backend-only.
- No client-controlled commission writes introduced.
- No client-controlled entitlement grants introduced.

Performance changes:

- No broad query/render refactors were attempted in this release pass.

## Validation Commands

Required before commit:

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
node --check functions/index.js
flutter build web --release --no-wasm-dry-run
flutter build apk --debug
git diff --check
```

Firebase emulator command after Java 21:

```powershell
.\scripts\run_firebase_emulator_tests.ps1
```

Release validation/deploy script:

```powershell
.\scripts\deploy_release_candidate.ps1
```

Deploy stages are opt-in:

```powershell
.\scripts\deploy_release_candidate.ps1 -DeployHosting
.\scripts\deploy_release_candidate.ps1 -DeployFirestoreRules
.\scripts\deploy_release_candidate.ps1 -DeployFirestoreIndexes
.\scripts\deploy_release_candidate.ps1 -DeployStorageRules
.\scripts\deploy_release_candidate.ps1 -DeployFunctions
```

## Release Classification

**CLOSED-BETA READY AFTER CONFIGURATION**

Repository-side blockers fixed in this pass:

- Storage rules target missing.
- Java 21 validation missing.
- Age gate incomplete on high-risk paths.
- Founding Supporter backend not separate.
- Moderation provider architecture missing.
- Release diagnostics missing.

Remaining external actions:

- Mike: Java 21 install, real operator/legal details, physical device QA.
- Firebase/Google Cloud: deploy rules/indexes/storage/functions, enable Natural Language provider, optional OCR provider.
- Stripe: configure price IDs and webhook secrets; run sandbox and live-mode readiness checks.
- Google Play Console: configure billing products and server verification before Play distribution.
- Solicitor/legal: review policies, age wording, moderation, creator terms and subscription terms.
- Accountant/tax: review creator payout and supporter handling.
