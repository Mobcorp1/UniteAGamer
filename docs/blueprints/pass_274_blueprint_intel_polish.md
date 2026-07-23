# PASS 274 Blueprint Tracker and Intel Reporting Polish

## Scope

PASS 274 tightened the Blueprint Tracker, Favourite Loadout bridge, and Intel reporting flow without changing protected Blueprint Grid ordering, ownership writes, duplicate writes, `_buildGrid`, `BlueprintTile` core tap behavior, carousel behavior, authentication, ads, or subscription tiers.

## Blueprint Grid

- In-Game View now shows a rotate prompt only on narrow portrait phones where the framed game-style grid is too compressed to use safely.
- Landscape phones, tablet portrait, desktop, and web keep the framed view available.
- Full Grid Overview remains available and is the safe fallback from the rotate prompt.
- Search results now use a separate responsive policy:
  - 1 result renders as one readable large card.
  - 2 results stay one column on narrow phones and two columns when width allows.
  - 3-4 results remain larger than the full-grid density.
  - 5+ results return to compact grid density by viewport width.
- The protected blueprint order and state interactions remain unchanged.

## Favourite Loadout Bridge

Blueprint tiles can now expose an additive Favourite Loadout action for items that already exist in the loadout catalogues:

- Weapons can be added as Primary Weapon or Secondary Weapon.
- Attachments are offered only for compatible slots on the currently selected primary or secondary weapon.
- Quick-use eligible items fill empty quick-use slots first.
- When all quick-use slots are full, the bridge exposes replacement destinations rather than silently failing.
- Ineligible blueprint items, such as crafting parts/resources, do not show a loadout action.
- If a player has no saved Favourite Loadout, the bridge creates the existing safe default `favourite-loadout` shape before applying the item.
- Applying/removing an item updates the existing Favourite Loadout repository path; no new persistence system was introduced.

## Intel Reporting

The drop report flow now captures clearer raid metadata:

- Acquisition Source order: Normal Drop, Quest Reward, Trade, Gifted, Trial.
- Raid round labels: Full, Mid, Late.
- Map condition neutral option: No Map Event.
- Raid reports capture local raid time as `HH:mm` and store `localTimeLabel` plus `timezoneOffsetMinutes`.
- The local time field derives the time-of-day bucket, while the raid phase selector remains available for manual correction.
- Report signatures include acquisition source so gifted/trade/trial reports do not collapse into normal drop reports.
- Market Intelligence details display the saved local time when present.

## Blue Gate POI Catalogue

The Blue Gate blueprint Intel catalogue now uses the current named POIs documented in `docs/blueprints/blue_gate_poi_catalogue.md`.

Legacy and misspelled report values are canonicalised where safe. Examples:

- `Abanndened Housing Project` becomes `Abandoned Housing Project`.
- `Olive Garden` becomes `Olive Grove`.
- `Maintenance Wing` becomes `Maintenance Bunker`.
- `Security Wing` and `Traffic Tunnel` become `Checkpoint`.

## Automated Coverage

Added focused regression tests for:

- In-Game View rotate prompt rules.
- Search result card sizing policy.
- Favourite Loadout blueprint eligibility.
- Weapon, attachment, and quick-use loadout destinations.
- Full quick-use replacement behavior.
- Acquisition source labels and legacy parsing.
- Raid round labels and legacy parsing.
- Blue Gate POI catalogue presence and alias canonicalisation.
- Local time metadata round-trip.

## Deferred

- No new attachment compatibility rules were invented; the bridge uses the existing compatibility registry.
- No direct UI automation was added for every viewport; manual QA is documented in `docs/testing/pass_274_manual_qa_checklist.md`.
- The legacy duplicate drop report model under data was not removed in this pass because removal was outside the polish scope.
