# PASS 297 Closed-Beta Launch Hardening Report

Date: 2026-07-28  
Baseline: `aff633c358e192a62a6177fe971eb8ea6cdf9cb9`  
Pass: Personal Item Intelligence, Creator Programme, Messaging Safety, Production Wiring and Closed-Beta Launch Hardening

## Executive Summary

PASS 297 implemented the production-safe parts that can be completed without new external credentials or legal/operator details:

- Shared Personal Item Intelligence engine with quantity-aware KEEP/USE/EQUIP/CRAFT/TRADE/LIST/RESERVE/SELL/RECYCLE/UNKNOWN outcomes.
- Versioned UAG-owned ARC Raiders item dependency dataset derived from existing UAG data and corroborated public/official research.
- Voice response wiring into the Personal Item Intelligence engine.
- Creator Programme models, repository, campaign-code validation, dashboard aggregate shape and server-authoritative Stripe commission ledger writes.
- 18+ age-verification models, repository, Firestore rules and Cloud Function processing.
- Blocking, message outbox, server-side deterministic moderation, moderation queue, reports and Firestore protections.
- Notification type and Communications Centre routing coverage for item, creator, subscription, supporter, payment and age events.
- Blueprint photo-import models hardened for provider-required states, multi-capture sessions, overlap metadata, review changes and explicit confirmation-before-write.
- Firestore rules emulator coverage for key new server-authoritative boundaries.

No external provider success is faked. Provider-dependent features are left in safe configuration-required states.

## Item Intelligence

Implemented files:

- `lib/features/trading_hub/arc_raiders/models/arc_personal_item_intelligence_models.dart`
- `lib/features/trading_hub/arc_raiders/data/arc_personal_item_dependency_catalog.dart`
- `lib/features/trading_hub/arc_raiders/data/arc_personal_item_intelligence_engine.dart`
- `lib/features/trading_hub/arc_raiders/repositories/arc_personal_item_intelligence_repository.dart`
- `lib/features/trading_hub/arc_raiders/voice/voice_response_builder.dart`

Dataset:

- Version: `uag-arc-items-2026-07-28-pass-297`
- Game version label: `ARC Raiders 1.28 research snapshot`
- Effective date: `2026-07-28T00:00:00.000Z`
- Remote version metadata path: `arc_item_dataset_versions/active`
- User protection path: `users/{uid}/arc_item_protections/{itemId}`
- Recommendation log path: `users/{uid}/arc_item_recommendation_logs/{logId}`

Sources consulted:

- Existing UAG `UnifiedItemIndex`, voice item database, quest requirements, Scrappy seed data, bench upgrade requirements, loadout seed data, attachment database and blueprint registry.
- Official Embark patch notes: [Patch Notes 1.19.0](https://id.embark.games/arc-raiders/support/faq/237-patch-notes-1-19-0), [Patch Notes 1.28.0](https://id.embark.games/arc-raiders/support/faq/251-patch-notes-1-28-0), [Patch Notes 1.22.0](https://id.embark.games/fr/arc-raiders/support/faq/242-patch-notes-1-22-0), [November Update 1.2.0](https://id.embark.games/fr/arc-raiders/support/faq/177-november-update-1-2-0), and [ARC Raiders official news](https://arcraiders.com/en/news).
- Corroborative public references only: [Arc Raiders Item Database](https://arcraidersitemdb.com/), [Arc Blueprint Tracker](https://arcblueprinttracker.org/blueprints), and [ARC Raiders Wiki recipes](https://arcraiders.wiki/wiki/Recipes).

Recycle safety:

- RECYCLE is blocked unless the item has fresh reviewed data, a known game-version label, sufficiently high confidence, verified recycle data, no known dependencies and no user/trade/loadout protection.
- Missing, stale, conflicting or unknown records return UNKNOWN with: `Do not recycle yet - UAG does not have sufficiently verified requirement data for this item.`

## Trade And Voice Integration

Implemented:

- Live `TradingListing` scan for offered/wanted item matches.
- Quantity-aware surplus logic so required stock remains protected and only surplus is suggested for trade/listing.
- Voice responses now call the shared engine and include concise spoken output plus detail for ownership, surplus, route/farm and trade signals.

Deferred:

- Circular and multi-player chain matching is not fully expanded in PASS 297 because no already-connected chain repository was present that could be safely extended without broad trading refactors.
- Voice write actions still require explicit confirmation and remain routed to existing flows rather than writing protected state directly.

## Creator Programme

Implemented:

- Creator application model and repository.
- Campaign code policy for `LOYAL`, `FOLLOWER`, `WELCOME`, `BETA` and custom codes, with sanitisation, duplicate detection and reserved official term checks.
- Privacy-safe dashboard aggregate model.
- Server-authoritative commission ledger entries written from Stripe `invoice.paid` webhook events.
- Creator aggregate paid-conversion and pending-commission increments from trusted billing events.

Firestore paths:

- `uag_creator_applications/{applicationId}`
- `uag_creator_campaign_code_requests/{code}`
- `uag_creator_dashboard_aggregates/{creatorUid}`
- `uag_creator_commission_ledgers/{creatorUid}/entries/{entryId}`

Configuration required:

- Real payout provider/onboarding.
- Admin approval UI for creator applications and campaign codes.
- Final legal/accounting review for affiliate terms, tax, payout timing, clawback and disclosure requirements.

## Age And Messaging Safety

Implemented:

- UAG account service is represented as 18+.
- Age requests are client-created but server-decided by `processUagAgeVerificationRequest`.
- Users cannot grant themselves `verifiedOver18`.
- Messaging uses `uag_message_outbox`; delivered messages are server-created in `uag_messages`.
- Blocking prevents message outbox creates, trade offers and Match Rider invites between blocked users.
- Deterministic server moderation classifies warnings, quarantine and severe block/escalation.
- Reports and moderation queue paths are protected.

Firestore paths:

- `uag_age_verification_requests/{requestId}`
- `users/{uid}.ageVerification`
- `uag_user_blocks/{blockerUid_blockedUid}`
- `uag_message_outbox/{messageId}`
- `uag_messages/{messageId}`
- `uag_message_reports/{reportId}`
- `uag_conversation_reports/{reportId}`
- `uag_moderation_queue/{queueId}`

Configuration required:

- External moderation provider selection and credentials if UAG wants provider-backed analysis beyond deterministic rules.
- Admin moderation queue UI/actions beyond Firestore-backed data paths.
- Operator policy review for appeals, evidence retention and Online Safety Act assessment.

## Notifications And Communications

Implemented:

- Added notification types for item relevance warnings, creator referrals/conversions/commission changes, subscription events, payment failure, founding supporter events and age verification requirements.
- Backend preference mapping updated for current notification wire names.
- Communications Centre inbox parser and navigation switch handle new wire names instead of collapsing them into session updates.

Deferred:

- Real-device foreground/background/terminated push QA still requires connected devices and deployed credentials.

## Blueprint Photo Import

Implemented:

- Provider-configuration-required state.
- Multi-capture session metadata.
- Overlap signatures for stitched capture review.
- Ownership review-change model.
- Confirmation-before-write and preview-only gates.

Deferred:

- OCR/image matching provider is not faked. ML Kit/Cloud Vision/OpenCV implementation still requires the selected provider/runtime integration and privacy disclosure before screenshot recognition can be represented as successful.

## Legal And Launch Configuration

Implemented:

- Creator/referral policy text expanded to cover non-employment, disclosure, truthful promotion, spam, self-referral, fraud, refunds/chargebacks and provider-confirmed commission timing.
- 18+ age restriction policy added.
- Moderation and appeals policy text expanded to disclose automated analysis, provider configuration, human review, retention/evidence and appeals.

Missing operator/legal details:

- Operator legal name.
- Trading name.
- Service address.
- Company number, if applicable.
- Privacy/copyright/moderation/billing support contacts.
- ICO fee/registration assessment.
- Cookie consent and processor list review.
- Play Store data safety and subscription disclosure review.

## Automatically Tested

- Item intelligence outcomes, quantity-aware surplus, user protection, stale/incomplete recycle block, safe recycle and coverage report.
- Voice personal-item response uses live inventory protection context.
- Creator campaign-code sanitisation, duplicate/reserved checks, dashboard aggregate privacy and commission ledger parsing.
- 18+ age decision model.
- Messaging moderation decisions and block ID determinism.
- Notification model preferences and Communications Centre wire parsing.
- Blueprint photo-import provider/confirmation gates.
- Firestore rules emulator coverage for new item, dataset, creator, age, block, message and moderation boundaries.

## Manual Or Config-Required Checks

- Stripe live webhook delivery, refund/chargeback reconciliation and payout operations.
- Google Play subscription product IDs and restore flows.
- Real-device push matrix.
- External moderation provider integration, if selected.
- OCR/photo import provider accuracy and privacy disclosure.
- Admin moderation and creator-approval operations.
- Legal/accounting review before production launch claims.

## Remaining Closed-Beta Blockers

1. Final operator details and legal review are not present.
2. External moderation provider is not configured.
3. OCR/image recognition provider is not configured.
4. Real-device push QA remains manual.
5. Creator payout/provider onboarding remains config-required.
6. Admin UI for creator approvals, campaign code approvals and moderation queue needs follow-up polish.

