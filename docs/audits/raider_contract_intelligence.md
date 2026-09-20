# Raider Contract incident intelligence — implementation audit

Starting checkout: `codex/full-arc-ui-convergence`, `8467c5becccfac21a2591248a56d6337289cd269`, clean, ahead 45. No subagents, remote replacement, push, Firebase deployment, Play upload, dependency changes, or project identity changes.

## Audited authorities and boundaries

The current `TradingRepository.markMySessionOutcome` treated either party's betrayal flag as a terminal trade status. Those flags are accusations, not independent evidence. Existing issuer-confirmed Contract video verification lives in `functions/raider_contract_verification.js`; Blueprint reward settlement remains in `ArcRaiderBlueprintRewardService`. There is no existing authoritative numeric reputation penalty for a verified trading betrayal to invoke. This pass therefore records incident and lifecycle history and invalidates overturned verified results, without inventing a competing score or changing Blueprint ownership.

Existing raw `available` Contract reads disclosed the entire document to every signed-in account, including the target. Discovery now uses a callable allowlist projection. Planner Hunt Targets, trackers, map data, onboarding, entitlements, advertising, Android/Play and Firebase project identity remain outside this pass.

## Lifecycle and evidence

1. A signed-in, age-verified eligible trade participant flags an existing scheduled/ready interaction. The server reads both participants from the trade, never from request-supplied identities. A deterministic session + reporter key makes retries and concurrent duplicate events idempotent. The same transaction sets that participant's betrayal flag and creates a private report and pending Contract.
2. The reporter adds an MP4 in Activity. The existing report evidence upload path and MP4 parser are reused. The backend checks report ownership, immutable report-specific storage path, media metadata, video track, maximum 25 MB, object generation and content hash. The report becomes pendingReview and the Contract verifying. A flag alone never activates discovery.
3. An independent moderator reviews the clip, verifies the canonical UAG account and records review notes. A manual report without a bound target UID cannot activate. Moderator approval, not MP4 structure alone, establishes incident validity. The transaction records approved/verified evidence and makes a requested Contract available for 14 days. Duplicate clip content from the same reporter against the same target cannot activate a second report. Different reports of the same clip also cannot inflate the intelligence sample.
4. Eligible discovery and acceptance check canonical target exclusion, issuer exclusion, verification, expiry, age verification, disabled Auth account, Contract restrictions and blocks in both directions. Acceptance checks block documents inside its transaction.
5. Assigned-hunter start, video submission, issuer confirmation/rejection and Blueprint settlement retain their existing authority. Completion submission/review now reject expired Contracts. A backend Date is used inside the evidence array because Firestore prohibits serverTimestamp sentinels in arrays.
6. Expiry is enforced immediately in discovery/acceptance/target status/completion, with an hourly persistence sweep. Withdrawal cancels pending/verifying Contracts. Status-change events append idempotent server audit records. Pending incidents never deduct reputation.
7. Every target can read a separate account-case projection and submit one challenge without an entitlement check. Independent moderator review can uphold or overturn. Overturn marks the report and Contract, excludes it from newly derived intelligence and invalidates any `raider_verified_results` attestation. It does not silently reverse already settled Blueprint inventory: that requires existing administrative reconciliation. No new irreversible numeric penalty is introduced.

## Data and retention

Intelligence is **ephemeral**, derived by Admin SDK on request rather than copied into a permanent behavioral collection. `CONTRACT_INTELLIGENCE_WINDOW_DAYS` defaults to 30 and is clamped to 7–90 days. Only moderator-approved, incident-verified reports whose incident time lies in the rolling window count. Duplicate evidence hashes are collapsed. The implementation computes coarse UTC six-hour/day buckets, map/server counts, sample count, confidence and window bounds internally. These counters are not stored or returned through hunter or target serializers.

Map/server affinity requires at least three incidents, two independent reporters, a recent incident within seven days, and a dominant known game map/server group with at least three observations and 60% support. Sparse, stale, unsupported or out-of-window data becomes UNKNOWN/LOW. No HIGH confidence is asserted from this limited evidence. Hunter server matching uses the hunter's existing game `serverPreference`; it never uses profile country/region, IP, device information, availability schedules or raw login/session history. Trade booking time is not actual activity and is not used. Automated betrayal cases have no invented incident location/time, so remain unknown unless independently verified contextual reports exist.

`TARGET ACTIVITY` remains UNKNOWN: incident reports cannot establish live presence or usual activity. A region match ranks otherwise eligible discovery results. This is verified incident context, not a live location service.

## Visibility

- **Public/community:** no raw Contract/result document endpoint is exposed. This pass does not introduce a public individual-case DTO or a public hunter leaderboard join.
- **Eligible hunter discovery:** explicit fields only: Contract ID, display name, category, available status, verified evidence label, reward summary, coarse map affinity, coarse region match, confidence and UNKNOWN activity likelihood. No target UID, reporter, hunter, evidence path, raw timestamp, schedule, source session or internal buckets.
- **Assigned hunter / issuer:** existing private Contract details remain available to the participants under existing disclosure policy, excluding the target. No internal intelligence is added to those documents.
- **Target account:** case ID, category, lifecycle status, evidence-review state, challenge state and challenge eligibility. No reporter/hunter identity or counts, views, rewards, operational timing, map/server history, confidence calculations or relevance rules. Supplied display names, aliases, casing and request UID cannot override the authenticated UID.
- **Moderator:** report/evidence review, canonical identity binding, source trade/report, lifecycle audit and a separate coarse intelligence summary. Internal temporal buckets are not returned by the moderation callable. The moderator cannot use raw Contract reads or incident-summary calls for their own target record.
- **Internal:** Admin SDK-only calculations; reserved `arc_target_intelligence` and duplicate-evidence claims deny all client access.

The canonical restriction applies to the authenticated account; it does not claim to identify alternate accounts controlled by the same person.

## Rules, indexes and rollout (NOT deployed)

Firestore removes unrestricted available-Contract reads, client Contract creation/acceptance and direct report moderation. Reporter withdrawal is an exact field whitelist. Existing reward immutability/selection/settlement conditions remain. Raw verified results and verification audits become participant/moderator-private and target-excluded. Incident audits are independent-moderator-only. Challenges are written only by the backend, with moderator reads; target status uses its separate callable. Contract restriction records are moderator-managed. Root collection placement avoids the existing user-subcollection owner wildcard. Storage adds an explicit target exclusion for Contract video reads.

Moderators can set or remove `reportingRestricted` / `huntingRestricted` booleans in `arc_contract_restrictions/{canonicalUid}` using trusted administration. Disabled Auth accounts are rejected for reporting/hunting/moderation. The pass does not automatically label repeated reporters malicious, and adds no general-purpose suspension UI.

The protected `firebase.json`, `.firebaserc` and existing `firestore.indexes.json` are unchanged. `raider_contract_indexes.json` is an additive rollout manifest, **not a replacement** for existing indexes. A separately authorized rollout must merge/create these five indexes and wait for readiness, then coordinate backend, rules and client release. Without those indexes, the new participant/moderation compound queries can fail in production; the UI reports the failure. Emulator tests do not enforce production composite-index readiness. Do not ship only the client or only a subset of the rules/backend changes.

Legacy available records without server incident verification or canonical target identity deliberately do not surface in discovery. Existing verified hunter completion/settlement remains readable to valid participants. Legacy incident activation needs an explicitly reviewed migration; it is not silently grandfathered into verified discovery. Functions and rules have not been exercised against production.

Discovery currently returns at most 100 matched projections and scans available Contracts plus target reports through the Admin SDK. At larger scale, server pagination/caching and operational rate limits should replace this scan without weakening projection or identity checks. The source report/evidence retention policy is unchanged; only derived intelligence uses this new rolling window.

## Validation

Validation results are recorded after the final runs below. UI tests exercise real discovery/account widgets with injected repository callbacks, including loading, error versus empty, retained stale data, search, acceptance failure, phone width, unknown intelligence and target field exclusion. Node tests exercise the actual handler authority with injected dependencies. The emulator test exercises actual Firestore/Storage rules and real Firestore transactions with injected Auth/media dependencies. It does not claim live Firebase authentication, production indexes, manual moderator content judgment, or device end-to-end testing.

## Scope

Concurrent Command Centre edits appeared after the clean starting checkpoint. Those are another workstream and must not be staged with this pass. Full Flutter validation runs against the shared checkout; Contract paths are staged explicitly.
