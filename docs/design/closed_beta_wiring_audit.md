# Closed Beta Wiring Audit - PASS 259C

Baseline: `704b2e0217f4f3b1d8fa98e8334467711e232705`

This audit records the closed-beta wiring state after the PASS 259C safe repairs. It covers durable state, completion paths, Operations, Reward Vault, seasonal reset readiness, admin diagnostics and Firebase production-readiness.

## Summary

| Metric | Count |
| --- | ---: |
| Systems audited | 29 |
| Fully wired | 7 |
| Partially wired | 22 |
| Disconnected | 0 |
| Missing | 0 |
| P0 items | 2 |
| P1 items | 10 |
| Repaired in PASS 259C | 5 |
| Deferred for later pass | 9 |

## Repairs Completed

- Added a canonical per-user season state and reset preview/apply coordinator for known current-season Scrappy, quest and bench tracker state.
- Added reset preview classification for preserved, reset, recalculated and manually reconfirmed systems.
- Added season metadata to Reward Vault inventory items: source season, source Operation, permanence, historical visibility, current-season unlock and post-season equipability.
- Tagged Operations progress, telemetry events, reward claims and eligibility reconciliation with the current season ID.
- Added startup season-state creation and interrupted-reset reconciliation through `ArcUserInitializer`.
- Added read-only Closed Beta Diagnostics to the admin console for season, tracker, Operations, rewards, equipped cosmetics and last reward reconciliation.
- Added owner-scoped Firestore rules for `arc_scrappy_states`, `arc_season_state`, `arc_season_history`, `arc_operation_progress`, `arc_operation_telemetry`, `arc_rewards_inventory` and `arc_equipped_cosmetics`.

## Current Source Of Truth

| Area | Source Of Truth | PASS 259C Status |
| --- | --- | --- |
| Season state | `users/{uid}/arc_season_state/current` | Added |
| Season history | `users/{uid}/arc_season_history/{season-reset}` | Added |
| Scrappy/quest/bench tracker state | `users/{uid}/arc_scrappy_states/{itemId}` | Existing; reset coordinator can archive/delete known current-season docs |
| Operations progress | `arc_operation_progress/{uid}/operations/{operationId}` | Existing; now season-tagged |
| Operations telemetry | `arc_operation_telemetry/{uid}/events/{eventId}` | Existing; now season-tagged |
| Reward Vault inventory | `arc_rewards_inventory/{uid}/items/{rewardId}` | Existing; now supports season metadata |
| Equipped cosmetics | `arc_equipped_cosmetics/{uid}` plus profile mirror fields | Existing; rules added |
| Admin diagnostics | `AdminConsoleScreen` read-only Firestore snapshot | Added |

## Reset Policy

Persistent state remains account identity, authentication, legal consent, profile, Embark ID, archetypes, communication style, squad intent, availability, Favourite Riders, reputation, trade reputation, historical behaviour, completed season history, historical Operations and permanent rewards.

Resettable current-season state is limited in this pass to known tracker documents shared by Scrappy, quest and bench progress. Blueprint ownership and duplicate semantics remain untouched as protected systems. Reward records are archived in season history and preserved in the Reward Vault.

Recalculated state includes Command Centre priorities, active Operations, tracker guidance, Favourite Loadout gaps and Trade Intelligence relevance. PASS 259C creates the durable season hooks, but deeper per-candidate exclusion reason reporting remains deferred.

## Deferred P0/P1 Items

- Full user-facing expedition reset preview and confirmation screen is not wired yet.
- Reset coordinator does not yet reset every current-season Operation progress document; it season-tags new progress so a later flow can distinguish historical/current progress safely.
- Reward Vault UI does not yet split Current Season, Previous Seasons and Permanent Rewards sections.
- Quest and bench progression still use the shared manual tracker document model where automatic proof is unavailable.
- Scrappy upgrade-level advancement is still limited by existing tracker mechanics; this pass avoids inventing automatic resource ownership.
- Command Centre candidate exclusion reasons are not exposed in admin diagnostics yet.
- Firebase rules were updated locally but not deployed in this pass.
- Emulator rules tests were not found in the repository.
- Existing admin "Reset beta progress" remains an onboarding/tutorial reset; it was not converted into a destructive season reset because the new policy preserves profile/legal identity.

## Audit Table

The CSV companion file contains the detailed row-by-row audit with the required columns:

`docs/design/closed_beta_wiring_audit.csv`
