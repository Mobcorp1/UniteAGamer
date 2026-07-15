# Closed Beta Wiring Audit - PASS 259D

Baseline: `7ec7f9431922d7d43a6c2dc052c2c8c45ceec0a5`

This audit records the closed-beta wiring state after the PASS 259D safe repairs. It covers durable state, completion paths, Operations, Reward Vault, seasonal reset readiness, admin diagnostics and Firebase production-readiness.

## Summary

| Metric | Count |
| --- | ---: |
| Systems audited | 29 |
| Fully wired | 9 |
| Partially wired | 20 |
| Disconnected | 0 |
| Missing | 0 |
| P0 items | 2 |
| P1 items | 6 |
| Repaired in PASS 259D | 7 |
| Deferred for later pass | 4 |

## Repairs Completed

- Added a public Command Centre Expedition Reset entry point and preview/confirmation screen.
- Completed reset execution for current-season Scrappy, quest, bench and Operation progress documents, including season history archives and idempotent completion results.
- Added seasonal Reward Vault Current Season, Previous Seasons and Permanent summary sections.
- Added a canonical cosmetic equipability evaluator and startup/reset reconciliation for expired season-only equipped cosmetics.
- Added group-level confirmation before bulk-completing Scrappy, bench or quest tracker sections.
- Extended admin diagnostics with Command Centre candidate include/exclude reasons.
- Extended season reset model tests for Operation season metadata, reset classification and cosmetic expiry.
- Added a canonical per-user season state and reset preview/apply coordinator for known current-season Scrappy, quest and bench tracker state.
- Added reset preview classification for preserved, reset, recalculated and manually reconfirmed systems.
- Added season metadata to Reward Vault inventory items: source season, source Operation, permanence, historical visibility, current-season unlock and post-season equipability.
- Tagged Operations progress, telemetry events, reward claims and eligibility reconciliation with the current season ID.
- Added startup season-state creation and interrupted-reset reconciliation through `ArcUserInitializer`.
- Added read-only Closed Beta Diagnostics to the admin console for season, tracker, Operations, rewards, equipped cosmetics and last reward reconciliation.
- Added owner-scoped Firestore rules for `arc_scrappy_states`, `arc_season_state`, `arc_season_history`, `arc_operation_progress`, `arc_operation_telemetry`, `arc_rewards_inventory` and `arc_equipped_cosmetics`.

## Current Source Of Truth

| Area | Source Of Truth | PASS 259D Status |
| --- | --- | --- |
| Season state | `users/{uid}/arc_season_state/current` | Added |
| Season history | `users/{uid}/arc_season_history/{season-reset}` | Added |
| Scrappy/quest/bench tracker state | `users/{uid}/arc_scrappy_states/{itemId}` | Existing; reset coordinator can archive/delete known current-season docs |
| Operations progress | `arc_operation_progress/{uid}/operations/{operationId}` | Existing; now season-tagged |
| Operations telemetry | `arc_operation_telemetry/{uid}/events/{eventId}` | Existing; now season-tagged |
| Reward Vault inventory | `arc_rewards_inventory/{uid}/items/{rewardId}` | Existing; now supports season metadata |
| Equipped cosmetics | `arc_equipped_cosmetics/{uid}` plus profile mirror fields | Existing; rules added |
| Admin diagnostics | `AdminConsoleScreen` read-only Firestore snapshot | Candidate diagnostics added |

## Reset Policy

Persistent state remains account identity, authentication, legal consent, profile, Embark ID, archetypes, communication style, squad intent, availability, Favourite Riders, reputation, trade reputation, historical behaviour, completed season history, historical Operations and permanent rewards.

Resettable current-season state is limited in this pass to known tracker documents shared by Scrappy, quest and bench progress plus current-season Operation progress documents. Blueprint ownership and duplicate semantics remain untouched as protected systems. Reward records are archived in season history and preserved in the Reward Vault.

Recalculated state includes Command Centre priorities, active Operations, tracker guidance, Favourite Loadout gaps and Trade Intelligence relevance. PASS 259D adds public reset entry and admin candidate diagnostics, but the full dedicated quest-chain model remains deferred.

## Deferred P0/P1 Items

- Dedicated quest-chain state, prerequisite enforcement, automatic objective advancement and quest rewards are still not implemented as a separate model. Existing quest tracking remains the shared manual tracker path.
- Scrappy and bench upgrade-level state remains represented by grouped manual tracker completion. PASS 259D adds confirmation before bulk completion but does not add a separate level-advancement document model.
- Firebase emulator rules tests were not found in the repository and were not safely added/deployed in this pass.
- Firestore rules/index deployment remains blocked until rules tests and authenticated CLI deployment can be run safely.

## Audit Table

The CSV companion file contains the detailed row-by-row audit with the required columns:

`docs/design/closed_beta_wiring_audit.csv`
