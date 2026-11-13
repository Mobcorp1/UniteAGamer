# Season Reward Classification - PASS 259D

## Reward Fields

Reward Vault inventory records support:

- `sourceSeasonId`
- `sourceOperationId`
- `permanent`
- `historicalVisible`
- `equipableAfterSeason`
- `currentSeasonUnlock`
- `archivedSeasonId`
- `archivedByResetId`

## Vault Sections

Reward Vault now displays compact seasonal sections:

- Current Season: earned items with `currentSeasonUnlock == true`.
- Previous Seasons: earned historical season-only items where `currentSeasonUnlock == false && permanent == false`.
- Permanent: permanent earned items after they are no longer current-season unlocks.

These sections sit above the existing badge, title, frame and banner inventory grids. They do not replace the existing grids or equip flows.

## Equipability

`ArcCosmeticEquipability` is the canonical evaluator:

- Permanent cosmetics remain equipable.
- Cosmetics marked `equipableAfterSeason` remain equipable.
- Season-only cosmetics are equipable only while they belong to the active season and remain current-season unlocks.
- Expired season-only cosmetics stay visible historically but are not valid equipped cosmetics.

## Reconciliation

`ArcOperationsRepository.reconcileEquippedCosmetics()` inspects badge, title, profile frame and profile banner equipped ids. Invalid expired season-only cosmetics are removed from both the profile mirror and `arc_equipped_cosmetics/{uid}`. Ownership is never deleted.
