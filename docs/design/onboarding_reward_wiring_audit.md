# Onboarding, Completion and Reward Wiring Audit

PASS 259B audit status after the focused wiring repair.

## Canonical State

| Area | Source of truth | Status |
| --- | --- | --- |
| Profile completion | `ArcProfileCompletionEvaluator`, persisted to `users/{uid}` and `users/{uid}/trading_activity/profile` under `profileCompletion` | Working for Embark ID, archetypes, communication style, squad intent, social/session state, availability, onboarding and legal acceptance. |
| Operation progress | `arc_operation_progress/{uid}/operations/{operationId}` plus telemetry summaries under `arc_operation_telemetry/{uid}` | Partial. Core low-risk events now write idempotent progress, but Scrappy, quest and reset milestones still need dedicated proof sources. |
| Reward Vault ownership | `arc_rewards_inventory/{uid}/items/{rewardId}` | Partial. Operation claims and eligibility reconciliation unlock canonical cosmetic IDs. Wider backfill for every historical operation remains incomplete. |
| Equipped cosmetics | `users/{uid}/trading_activity/profile` and legacy `arc_equipped_cosmetics/{uid}` read path | Working for existing Reward Vault equip flows. |
| Eligibility backfill | `ArcRewardEligibilityEngine` during `ArcUserInitializer.initialize()` | Partial. Closed Beta, Closed Beta Veteran and Founder/Early Supporter rewards are gated and idempotent. |

## Action Wiring Matrix

| Action | Source screen | Saved field/document | Completion condition | Command Centre effect | Operation effect | Reward granted | Reward Vault item ID | Existing-user backfill | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Onboarding completed | Mandatory onboarding | `users/{uid}.arcMandatoryOnboardingComplete`, `onboardingComplete`, `arcOnboarding.completedAt` | Stored completion flag exists | Complete Profile priority can clear once all profile requirements pass | `profileCompleted` telemetry after evaluator completes | Beta Access via First Contact claim or beta eligibility | `beta_access` | Re-evaluated at startup | Working |
| Legal consent completed | Mandatory onboarding / auth legal flow | `users/{uid}.legalAccepted`, `arcOnboarding.legalAccepted` | Terms and privacy, or onboarding legal trio accepted | Missing legal blocks Complete Profile | Included in profile completion | None directly | None | Re-evaluated at startup | Working |
| Embark ID saved | Profile setup/edit | `users/{uid}/trading_activity/profile.embarkId` and profile mirrors | Non-empty Embark ID | Missing Embark ID opens profile setup | Profile completion can advance | None directly | None | Re-evaluated at startup | Working |
| Raider level/wipe state answered | Onboarding basic profile | Basic/onboarding profile state | Non-empty persisted answer | Used by decision/intelligence where available | No durable operation event yet | None | None | Not inferred | Partial |
| Blueprint Tracker state selected | Onboarding basic profile | Basic/onboarding tracker state | Non-empty persisted answer | Used by blueprint summaries where available | No durable operation event yet | None | None | Not inferred | Partial |
| Archetypes selected | Profile setup/edit/onboarding | `archetypes` list, legacy `playStyle` accepted | At least one normalized archetype | Missing archetype opens profile setup | Profile completion can advance | None directly | None | Legacy single value accepted | Working |
| Profile completed | Profile setup/edit/onboarding/availability | `profileCompletion.complete`, `isProfileComplete` | Evaluator has no missing fields | Complete Profile disappears immediately through stream | `beta_complete_profile` progress idempotently increments | Beta Access via operation claim or eligibility | `beta_access` | Startup refresh records completion | Working |
| Availability completed | Availability editor | `users/{uid}/trading_activity/availability` | At least one enabled slot or legacy completion proof | Missing availability opens availability route | `daily_update_availability` progress increments | Intel XP via claim | None | Re-evaluated at startup for profile, not daily op | Partial |
| First Favourite Loadout completed | Favourite Loadout | Saved loadout repository | First successful save | Loadout summaries update from saved state | `beta_loadout_saved`, `weekly_loadout_progress` idempotently advance | Intel XP only; Founder badge removed from this task | None | Existing saved loadouts are not backfilled yet | Partial |
| First blueprint marked owned | Blueprint tracker | Existing blueprint ownership docs | Ownership exists | Blueprint intelligence updates | No new operation event added; protected write semantics unchanged | None | None | Not inferred | Disconnected |
| First trade listing created | Trade listing flows | Existing listing docs | Listing created successfully | Trade snapshot/objectives update | `beta_first_listing`, `daily_refresh_listing` idempotently advance | Extra trade slot / XP by claim | `extra_trade` | Historical listings not backfilled yet | Partial |
| First trade completed | Trade session outcome | Existing trade session status | Session reaches completed | Trade objectives update | `beta_first_trade`, weekly/monthly/lifetime trade ops advance idempotently by session ID | Trade Pioneer / slots / XP by claim | `trade_pioneer`, `extra_trade` | Historical completed trades not backfilled yet | Partial |
| First Intel report submitted | Blueprint intel report | Existing blueprint report docs | New report created | Intel signals update | `blueprintReportSubmitted` advances raw report task | None until verified task claimed | None | Historical reports not backfilled yet | Partial |
| Intel confirmed | Blueprint intel confirmation | Existing report confirmation fields | User confirmation is newly added | Intel signals update | `intelConfirmed` advances verified intel tasks by confirmation ID | Intel Officer by claim | `intel_officer` | Historical confirmations not backfilled yet | Partial |
| First Match Rider session created/joined | Match Rider invite response | Existing invite/session docs | Invite accepted | Matchmaking objectives update | `beta_match_raider` advances by match ID | Extra match request / XP by claim | `extra_match` | Historical sessions not backfilled yet | Partial |
| Closed Beta participation | User flags/roles | `users/{uid}` beta flags or roles | Durable beta flag/role exists | Vault can unlock after startup reconciliation | Eligibility reconciliation grants directly | Beta Access Badge | `beta_access` | Startup reconciliation | Working |
| Founder/Early Supporter qualification | User flags/roles | `users/{uid}` founder/supporter flags or roles | Durable founder/early supporter flag/role exists | Vault can unlock after startup reconciliation | Eligibility reconciliation grants directly | Founding Raider | `founding_raider` | Startup reconciliation | Working |
| Operation completion | Operations Command | `arc_operation_progress/{uid}/operations/{operationId}` | Progress reaches target | Completed/claimed states suppress action per existing rules | Progress persists | Rewards granted when claimed | Canonical operation reward IDs | Partial reconciliation only for eligibility rewards | Partial |
| Reward claim/equip | Operations Command / Reward Vault | Inventory docs and equipped cosmetic fields | Claim or equip write succeeds | Profile/trading cosmetics reflect equipped state | Claim is idempotent through `claimed` flag | Operation rewards | Badge/title/frame/banner IDs | Existing inventory read path works | Working |
| Scrappy milestone | Scrappy tracker | Existing Scrappy tracker state | Current upgrade requirements complete | Scrappy intelligence contributes priorities | No operation telemetry bridge added in this pass | None wired | None | Not implemented | Missing |
| Quest milestone | Quest tracker | Existing quest tracker state | Active quest objective/quest complete | Quest intelligence contributes priorities | No operation telemetry bridge added in this pass | None wired | None | Not implemented | Missing |
| Bench milestone | Bench intelligence/tracker | Existing bench state | Bench requirement complete | Bench intelligence contributes priorities | No operation telemetry bridge added in this pass | None wired | None | Not implemented | Missing |
| Expedition reset | Existing wipe/expedition answers and trackers | No single reset coordinator yet | Versioned reset ID applied once | Early-wipe priorities should recalc | Not implemented | None | None | Not implemented | Missing |

## Repairs Completed In This Pass

- Added one profile completion evaluator and stored its result for profile, Command Centre, Operations and reward logic.
- Repaired onboarding completion routing so mandatory onboarding lands on Command Centre and refreshes profile completion.
- Added active-card focus/scrolling and reusable electric border support to the basic onboarding profile flow.
- Normalized visible copy from `Trader Profile` to `Your Hub Profile` without renaming stable IDs.
- Added idempotent telemetry writes for profile completion, availability, loadout save, listings, completed trade sessions, beta feedback, intel report submission, intel confirmation and Match Rider acceptance.
- Added explicit beta/founder eligibility evaluation and startup reward reconciliation for canonical reward IDs.
- Removed the unsafe Founding Raider reward from the first Favourite Loadout operation.

## Deferred

- Scrappy milestone operation bridge, level advancement audit and reset-safe coordinator.
- Quest objective operation bridge, reward grant audit and reset-safe coordinator.
- Bench milestone operation bridge.
- Full historical operation reconciliation from every provable source.
- Admin-only diagnostic panel with candidate inclusion/exclusion reasons.
- Canonical expedition/wipe reset coordinator.
