# Community Rewards, UAG Creator Program and Hunter Rats redesign

Date: 2026-09-14. Repository inspection and local implementation; no production deployment, rules change, payment change or new backend collection.

## Delivered experience

- Community Rewards is now a concise programme landing with three large ARC tactical cards: Community Rewards, UAG Creator Program and Hunter Rats. Three columns at 760px of available content width; a natural-height single column below that threshold. Cards never require a fixed carousel height.
- Community Rewards opens a focused detail page: referral identity first, progress open by default, reward locker, community growth and rules as separate expandable sections. Existing live panels and financial logic are reused.
- Creator Program keeps current application/status and active dashboard visible. It names Creator Points explicitly, displays application status and computes distance to the next tier from the existing commercial policy. Earnings, community arsenal, reward access, campaign codes, commission ladder and rules have distinct sections.
- Creator application/dashboard/campaign loading and errors are explicit. A failed stream no longer masquerades as a zero-valued activity dashboard or an empty campaign list. Errors use plain copy without Firebase exception leakage.
- Shared `UagProgrammeSection` uses existing ARC tokens, responsive text, a keyboard-focusable button, expanded semantics and a minimum 48px target. Closed content is unmounted so hidden live sections do not hold unnecessary subscriptions. These are informational/review panels; application forms remain outside collapsible content.
- Hunter Rats has an honest planned-country-leaderboard explanation and a working link to existing Raider Contracts. It displays no invented participants, counts, winners, season or prizes.
- Wall of Legends remains in its existing navigation context. Drawer, Discover hierarchy, route registrations, entitlement gates, referral and financial calculations are unchanged.
- No ads were added to financial/application/contract detail surfaces.

## Actual sources and current capability

| Concern | Repository source | Actual behaviour / consequence |
|---|---|---|
| Community referral | `models/uag_referral_commission_policy.dart`, existing referral widgets | First-purchase discount 10%; base ladder 5% to 15%; Premium uplift 2.5 percentage points. Preserved. |
| Creator commission | `models/uag_creator_commercial_policy.dart` | Essential subscriber 1 point, Premium 1.5 points; ladder thresholds 1/8/15/25/40/60/100; base rates 7.5/10/12.5/15/17.5/20/20%; 30-day validation and tier grace. No calculation change. |
| Creator dashboard | `repositories/uag_creator_live_repository.dart` | Reads latest `uag_creator_applications`, `uag_creator_dashboard_aggregates/{uid}`, own campaign requests. UI uses actual aggregate fields for points, paid audience and approved earnings. |
| Community uplift | `widgets/uag_creator_commission_rate_panel.dart` | Existing growth repository and commission rate policy calculate actual uplift. Reused unchanged. |
| Missing metrics | Creator dashboard contract | No invented follower count, reach, impressions, streak or predicted earnings. Next tier derives only from existing policy and actual Creator Points. |
| Contract truth | `lib/features/trust/models/arc_raider_contract_models.dart` | States available, accepted, inProgress, evidenceSubmitted, completed, rejected, disputed, expired, cancelled. Records reporterUid, hunterUid, evidence, moderatedByUid and resolvedAt. No issuer-verification field or season/country snapshot. |
| Acceptance | `lib/features/trust/repositories/arc_raider_contracts_repository.dart::acceptContract` | Transaction checks availability/expiry and prevents reporter and target from accepting. |
| Evidence | Repository `submitEvidence`; screen `_submitEvidence` dialog | Nonempty evidence list required by client repository. Completion dialog writes a `kind: link` evidence item from nonempty URL; does not require a verified video clip. Video upload helper elsewhere sets video MIME/kind, but completion does not mandate it. |
| Resolution | Repository `resolveContract` | Moderator access required, including for completed. Blueprint settlement additionally requires admin/dev. Reporter does not confirm completion today. |
| Existing stats | Repository `resolveContract` | `users/{hunterUid}.raiderContractStats.completed` increment happens after resolution write, outside that transaction. Not an authoritative idempotent season score. No leaderboard should rely on it. |
| Access protection | `firestore.rules`, `match /arc_raider_contracts/{contractId}` | Completed contracts are readable by participants/moderators, not a globally readable leaderboard feed. Reporter can dispute but cannot complete. Moderator branch is broad. Do not query private completed contracts as public leaderboard rows. |
| Country | Trading profile repository | `basicProfile.country` is used as a region fallback, including a UK default. Not a verified country/season eligibility record. Never silently assign UK or infer from game-server region for prizes. |
| Temporary access | `models/uag_creator_temporary_entitlement.dart`, `models/uag_user_entitlement.dart` | Existing grants have start/expiry, source claim and tier. Effective tier chooses the highest active grant/core tier; expired grants stop contributing. Founding/Beta pricing status is separate. |
| Grant issuance | `repositories/uag_creator_reward_activation_repository.dart`, `functions/index.js` | Existing creator-code reward activation handles creator/code/claim authority and idempotent grant IDs. It is not a general country-season prize issuer. Do not manufacture creator codes for hunters. |

Paths abbreviated under `lib/features/monetisation/` unless explicitly rooted.

## Launch boundary

**A moderator-completed contract is not yet an issuer-verified Hunter Rat completion.** Rebranding the current completed counter would violate the requested competition definition. This pass therefore implements the programme UX and architecture, but deliberately leaves ranked results and prizes unavailable. No parallel verification truth or client-authored award path was introduced.

## Proposed implementation specification (not deployed)

### 1. Extend the existing contract lifecycle

Keep `arc_raider_contracts/{contractId}` as the only verification source. Add a versioned issuer-confirmation record to that document only through a server-authorised operation: confirmer UID, server confirmation time, accepted evidence identifier/hash, confirmation version and optional revocation metadata. Proposed names are design suggestions, not an existing data contract.

1. Issuer places a moderated contract through current report/contract path.
2. A different eligible hunter accepts; preserve existing acceptance and Blueprint reward behaviour.
3. Hunter submits completion evidence. Require an actual supported video asset/reference with durable evidence identity, ownership, validation status and content hash; URL suffix alone is not video validation.
4. Only the original reporter/issuer can confirm that hunter's evidence. Server transaction checks evidenceSubmitted, actor equals reporterUid, actor differs from hunterUid, eligible participants and current evidence version. The confirmation must be bound to evidence so later changes invalidate it.
5. Complete through the existing settlement path without duplicating Blueprint transfers. Issuer confirmation and settlement must be coordinated atomically/idempotently; do not let the issuer invoke the existing unrestricted moderator branch.
6. A moderator can reject/dispute/reverse, with a reason and audit event. Administrative moderation is not a replacement for issuer confirmation in ranked eligibility.
7. Only a currently completed, non-revoked contract with valid issuer confirmation and required video produces one scoring result. Legacy completed rows are excluded unless revalidated through an explicitly audited migration.

Server security/emulator tests are required before deployment. Existing permissive transition/evidence paths must not permit users to synthesize confirmation fields or replay stale evidence.

### 2. Country-first materialised leaderboard

Server materialisation is a derived, rebuildable projection of the contract record, not a second verification system. Use one deterministic contribution key per contract, transactionally reconciled on completion, reversal and eligibility changes. Persist contribution version so trigger retries cannot increase score. Do not increment a count on every trigger delivery.

Public row allowlist: rank, approved public avatar preset/URL, UAG display name, verified completed-contract count and ISO country code; optional last qualifying completion if its privacy implications are accepted. No report ID, target/victim, evidence link, issuer identity, private profile fields or raw contract data in public rows. Country and season are mandatory filters. Game server is optional only after a trustworthy source exists and does not define reward country.

Canonical country should be explicitly chosen, normalised and locked for a season; profile changes affect the next season. Unknown country has an enrolment state, not a geographic guess. No county/state/province is needed. Store private eligibility data separately from public aggregate rows.

Define UTC calendar-month half-open windows [start, end). Score by issuer confirmation time, subject to successful settlement and validity. Freeze after a documented review window; retain projection and policy version for reproducibility. Recompute from source contracts before close.

Proposed tie rule for owner review: equal counts share competition rank; sort tied display rows deterministically by public name then stable opaque ID. At the prize boundary include all ties only within a published reserve budget; otherwise choose a prepublished secondary rule before the season opens. Never introduce an arbitrary UID-based prize tiebreak after play.

UI states: enrol/select country, season open, no eligible completions, ranked list, season under review, final results, claim pending/claimed/expired/revoked, recoverable loading/error. Phone rows stack name/count/country; wide view may use a compact accessible table. Do not load private contract records to render rows.

### 3. Configurable prize policy and temporary access

Keep competition disabled by default. Server-owned versioned season config should define enabled countries, minimum eligible participants/completions, Top N, rank bands, tier, duration, claim expiry, total grant/day budget, tie policy and review window. N may be 5/10/20/24; none is selected in this pass.

Reuse existing time-bounded entitlement evaluation, but introduce a separately authorised Hunter-season grant issuer with deterministic `season/country/user/prize-band` grant identity and source claim/audit metadata. Do not overload creator identity or alter subscription records. The server must validate frozen eligibility and idempotently issue the grant. Access starts on allowed claim or configured award start, expires automatically, never creates a payment subscription, never changes Founding Raider/Beta eligibility/prices and never extends another grant indefinitely. Existing paid access is not downgraded. Publish rules for already-paid winners; banked unlimited future access is not acceptable.

Existing highest-active-tier evaluation is a reusable building block, not proof that this new issuer is secure. New issuance authority, revocation semantics, anti-stacking and server enforcement require design/security work. None was written into production schemas tonight.

### 4. Commercial experiments (illustrative allocation, not revenue forecasts)

For one qualifying country, giving every winner seven days of access allocates 35/70/140/168 access-days for Top 5/10/20/24 respectively. Across C qualifying countries multiply by C. These are exposure/budget units, not cash cost or lost sales estimates.

Prefer an initial small participation-gated country pilot with a hard global access-day budget. Compare all-Premium against mixed rank bands such as Premium for leading places and Essential below; configure the actual bands only after owner review. Measure incremental engagement, subsequent paid conversion, displaced paid days, repeat-winner share, evidence-review effort and reversal/fraud rates. Stop or tighten an experiment when conversion or moderation economics do not justify it.

No cash-prize implementation. Future cash feasibility requires jurisdiction-specific promotion/competition, eligibility, tax/reporting, identity checks, payment operations and fraud review; this report makes no legal or tax conclusion.

## Anti-abuse assessment

| Control | Exists today | Required before valuable prizes |
|---|---|---|
| One completion per contract | Terminal-state client transition checks; Blueprint transaction path | Deterministic server contribution and grant keys; concurrent/retried completion tests; do not use post-write stats increment |
| No self-verification | Issuer/target cannot accept; resolution is moderator-only | Explicit server issuer!=hunter check even for privileged actors; creator/issuer relationship checks |
| Issuer/hunter relationship | IDs stored | Detect repeated pair concentration; review unusual patterns without blanket blocking legitimate squads |
| Duplicate contract farming | No reward-season dedupe found | Incident/evidence association and review thresholds; reject duplicate scoring while retaining private audit |
| Reused evidence | Evidence identifiers/kind/URL stored | Server hash/durable asset identity and replay detection; reviewer appeal path |
| Reversal/deletion | Contract delete denied; moderator may resolve | Revocation event, negative reconciliation, frozen-season correction policy and audit; no silent score deletion |
| Banned/suspended accounts | No explicit ranked eligibility check in inspected contract resolution | Server eligibility at acceptance/verification/season close/claim; documented appeal/reinstatement handling |
| Country switching | No season country snapshot | Country lock and next-season change rule; no geo default; minimise private location data |
| Account age | No leaderboard-specific rule | Configurable minimum only if pilot abuse warrants it; disclose in advance |
| Audit trail | Current moderator identity/notes/timestamps | Append-only actor/action/reason/version events for confirmation, reversal, score rebuild and prize claim |
| Recalculation | No country-season projector | Full rebuild compares with projection; idempotent repair and drift alerts |
| Tie handling | No season competition | Prepublished deterministic rank and prize policy; ties must fit reserve budget |
| Season freeze | Not present | UTC bounds, review window, frozen result version and controlled appeal correction |
| Prize claim | Existing creator reward claims only | Hunter-specific idempotent claim authority, expiry, revocation and no infinite stacking |

## Validation and handoff

Added `test/features/monetisation/uag_programme_section_test.dart` for narrow 320px/large-text layout and lazy mount/dispose behaviour. Updated the existing commercial convergence source-contract assertions to the approved programme names and explicit planned leaderboard state. Parent integration worker runs formatting, analyzer, targeted/full tests and builds once to avoid concurrent Flutter tool locks. Actual results belong in the overnight handoff, not assumed here.

Owned clean files: both monetisation screen files, new programme-section widget, new widget test, existing commercial convergence test and this report. No initially dirty files touched. No commits created by this worker.

Priority follow-up: server-authorised issuer/video confirmation design; emulator security tests; deterministic contribution/reversal projection; canonical country eligibility; frozen season policy and prize budget; secure temporary grant issuer; then live country leaderboard UI and pilot measurement.
