# Season Reset Architecture - PASS 259D

## Source Of Truth

- Current state: `users/{uid}/arc_season_state/current`
- History: `users/{uid}/arc_season_history/{season-reset}`
- Tracker progress: `users/{uid}/arc_scrappy_states/{itemId}`
- Operations progress: `arc_operation_progress/{uid}/operations/{operationId}`
- Reward inventory: `arc_rewards_inventory/{uid}/items/{rewardId}`
- Equipped cosmetics: `arc_equipped_cosmetics/{uid}` plus profile mirror fields

## Public Flow

The public entry point is the Command Centre Expedition Reset card, which opens `ArcSeasonResetScreen`.

Opening the preview performs no reset writes. The screen loads the current season state, reconciles any interrupted reset, builds a preview, and displays reset/persist/recalculate/manual reconfirm groups. The confirm action requires a checkbox and then applies the reset through `ArcSeasonResetRepository`.

## Execution

The coordinator writes `resetStatus: inProgress`, archives the current tracker, Operation and reward snapshots into season history, deletes known current-season tracker and Operation progress documents, marks current-season reward records as historical, advances the current season id/version and records `lastResetResult`.

The same reset id is idempotent. If the reset is already completed, the repository returns an already-applied result. Startup reconciliation calls the interrupted-reset recovery path.

## Protected State

The reset coordinator does not alter Blueprint Grid rendering, `BlueprintTile`, blueprint ownership writes, duplicate writes, `_buildGrid`, carousel logic, auth providers, profile identity, legal consent, reputation, Favourite Riders or trade history.

## Known Limits

Dedicated quest-chain state and separate Scrappy/bench level documents are not present yet. The reset can archive/delete the current shared tracker docs but cannot archive richer progression models until those models exist.
