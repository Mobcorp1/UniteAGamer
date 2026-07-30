# PASS 303 - Closed Beta Journey Audit

Baseline: `715fd761c3907cba268ac1617f10f30fda8ca604`

Scope: focused Closed Beta 2 stabilisation only. No protected Blueprint grid, ownership, duplicate, carousel, authentication, profile, cosmetic, trade or notification data behaviours were redesigned.

## Executive Summary

The standard tester journey is viable for a deliberately limited beta when the PASS 302 feature availability model is used as the authority. PASS 303 repaired route and surface inconsistencies that could expose hidden systems or bypass Coming Soon safety, improved admin diagnostics, clarified Coming Soon interest wording, and expanded feedback categories for beta triage.

## Journey Audit

| Journey step | Current status | Finding | PASS 303 action |
| --- | --- | --- | --- |
| Launch | Already protected | App entry remains routed through the existing auth/session gate. | No code change. |
| Authentication | Already protected | Biometric relock is real auth behaviour, not a beta feature surface. | No code change. Obsolete promotional unlock card was not found in beta-facing onboarding. |
| Registration | Needs manual testing | Registration should still lead into consent/onboarding through existing gates. | Manual checklist added. |
| Consent | Needs manual testing | Consent is blocking through existing legal flow; no code blocker found in scan. | Manual checklist added. |
| Onboarding | Needs manual testing | Hidden features must not block completion; no safe deterministic code repair found without expanding scope. | Manual checklist added. |
| Personalisation | Working with caveat | Stored interests remain authoritative. Hidden future systems are excluded from diagnostics visibility without deleting stored values. | Diagnostics tests expanded. |
| Profile & Reputation | Already protected | Existing profile route and persistence were not changed. | Manual checklist added. |
| Command Centre | Fixed in PASS 303 | Coming Soon recommendations could duplicate when multiple registry entries shared one gate. | Deduped Coming Soon recommendations by feature flag. |
| Blueprint Tracker | Fixed in PASS 303 | Direct named route and hub shortcuts could bypass canonical availability. | Route and hub title mappings now use `FeatureAccessFlag.blueprintTracker`. |
| Bench Tracker | Fixed in PASS 303 | Admin exposed a Bench flag, but direct route used Scrappy availability. | Bench route and registry now use `FeatureAccessFlag.benchTracker`. |
| Scrappy Tracker | Working | Existing Scrappy gate remains canonical. | Progress hub now hides or marks the card from availability state. |
| Quest Tracker | Fixed in PASS 303 | Admin exposed a Quest flag, but direct route used Scrappy availability. | Quest route and registry now use `FeatureAccessFlag.questTracker`. |
| Coming Soon feature | Fixed in PASS 303 | Action copy said `Notify Me`, which implied push delivery. | Reworded to `Register Interest` with accurate Personalisation/Settings guidance. |
| Feedback | Fixed in PASS 303 | Required beta categories were not all explicit. | Added Layout/display issue, Something confusing and General feedback; Feature request label clarified. |
| Logout and return login | Needs manual testing | Existing auth/session state was not changed. | Manual checklist added. |

## Fixed in PASS 303

- Direct route access for Blueprint Tracker, Bench Tracker, Quest Tracker, Raid Planner, Intel Explorer and Raid Intelligence now uses the existing `FeatureAccessRouteGate`.
- Drawer catalog entries for controlled Blueprint, Raid Planner and Raid Intelligence destinations now declare canonical access flags.
- Progress Trackers hub cards now read `FeatureAccess.watchAvailabilityMap`, omit Hidden cards, route Coming Soon cards to the reusable Coming Soon screen, and show an empty state if all tracker cards are hidden.
- My Hub and ARC Raiders hub no longer bypass Blueprint feature availability with beta-open title shortcuts.
- Feature registry now includes Scrappy, Bench and Quest tracker entries aligned to their admin flags.
- Admin diagnostics now summarize the standard closed-beta configuration from `config/feature_access` instead of the admin bypass result.
- Command Centre Coming Soon recommendations are deduped by access flag.
- Feedback categories now include the minimum beta triage labels.

## Deferred

- Full mobile/web onboarding runtime walkthrough.
- Server-side notification fan-out for Coming Soon interest.
- Screenshot attachment for feedback.
- Admin Blueprint Catalogue and safe grid editor: data-driven Blueprint definitions, stable IDs, draft validation, grid preview, image management and publish workflow.
- Live Firebase permission testing on a non-admin standard beta account.

## Not Reproducible In Code Scan

- The previously mentioned obsolete unlock/biometric message card was not found as a beta onboarding card. Secure biometric login/relock behaviour remains in the auth flow and was not removed.

## Already Protected

- PASS 302 canonical POI resolution.
- PASS 302 feature availability enum and reusable Coming Soon/Hidden screens.
- PASS 301 personalisation persistence model.
- Blueprint grid order, rendering, ownership and duplicate logic.
