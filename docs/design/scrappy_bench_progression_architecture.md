# Scrappy And Bench Progression Architecture - PASS 259D

## Shared Tracker State

Scrappy upgrades and bench upgrades use the same persisted item progress model:

- Screen: `ScrappyGridScreen`
- Scrappy seed: `ArcScrappySeedData`
- Bench seed: `ArcBenchUpgradeSeedData`
- State: `users/{uid}/arc_scrappy_states/{itemId}`
- Repository: `ArcScrappyRepository`

Collected counts are persisted per item. Completion is derived from collected count versus the item's required count.

## Confirmation

PASS 259D adds explicit confirmation before the shared COMPLETE button bulk-fills incomplete items in a Scrappy, bench or quest group. The confirmation dialog states how many items will be set to their required target and writes through the existing repository.

Destructive reset and single-item clear actions already use confirmation dialogs.

## Reset Behaviour

Season reset archives/deletes known current-season Scrappy and bench tracker documents. Historical archives retain the completed-season snapshot, while the next season starts from the approved empty tracker baseline.

## Deferred Dedicated Level Model

There is no separate current-level document yet for Scrappy or each bench station. PASS 259D therefore does not add automatic level advancement, one-time level reward grants or per-level history beyond the shared tracker archive. Those require a dedicated level model in a later pass.
