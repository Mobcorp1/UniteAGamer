# PASS 259A Core Player Experience Audit

Baseline: PASS 258D asset migration (`ded1f33ca921236dfddd6742a4bfbcf3a4f0e88b`).

## Scope Inspected

- Favourite Loadout: `favourite_loadout_screen.dart`, loadout layout engine, seed data, compatibility registry, asset registry and existing loadout tests.
- Blueprint Tracker: `blueprint_grid_screen.dart`, blueprint seed ordering, state tests and `BlueprintTile` usage.
- Scrappy and Quest Tracker: shared `scrappy_grid_screen.dart`, `ScrappyTile`, Scrappy, bench and quest seed data.
- My Hub: `my_hub_screen.dart`, Command Centre Tool Deck route, drawer routing and main app route table.
- Help: legal hub, feedback screen, onboarding legal links and drawer entry points.
- Command Centre tracker cards: compact content widget and Command Centre route actions.

## Before-State Findings

- Favourite Loadout already used canonical weapon and attachment data, but the default surface still showed three full planning panels beneath the weapon/Quick Use surface. This made secondary information compete with the weapon and slot model.
- Favourite Loadout zero-slot weapons correctly had no generated slot data, but still showed a helper block under the weapon, which looked like reserved attachment space.
- Blueprint Tracker overview used the correct seed order and `BlueprintTile`, but did not visually group the first five complete in-game rows and had no direct upper/lower overview jump controls.
- Scrappy, bench and quest trackers shared one implementation, but carousel stage height was fixed around the largest card pattern. One-item cards therefore used too much vertical space.
- `/my-hub` and drawer Home/My Hub/Tracking correctly resolve to Command Centre. The older My Hub carousel remains accessible as Command Centre Tool Deck, but one bottom dock action looked up `Trading` while the actual card title is `Trading Overview`.
- My Hub Referral Tools card opened Trading Profile instead of the existing Referral Tools screen.
- Help was split across legal screens and feedback links. There was no structured ARC Help Centre with categories, search and direct app links.
- Command Centre tracker presentation was already compact after earlier passes; no ranking or engine change was needed for PASS 259A.

## Implementation Decisions

- Keep Command Centre as the post-login and `/my-hub` destination. Treat old My Hub as the optional Tool Deck / personal configuration carousel.
- Do not modify `BlueprintTile`, ownership writes, duplicate writes, seed ordering or grid item callbacks.
- Add pure layout helpers for Blueprint overview frame/jump math and Scrappy/Quest carousel sizing so tests cover the pass behaviour without brittle golden images.
- Add a structured Help Centre catalog and screen rather than expanding legal or feedback pages into a mixed-purpose help surface.
- Add route registrations only for existing screens that already had, or now need, stable named routes.

## Favourite Loadout Decisions

- Keep weapon data, slot data, saved loadout persistence and pickers unchanged.
- Increase weapon image weight in the existing tile and keep attachment slots directly beneath the weapon.
- Replace always-visible Missing Blueprints, Trade + Bench Readiness and Beta Readiness cards with one collapsed Planning Details panel.
- Keep Quick Use exactly six visible slots; shield remains separate; augment remains inside Quick Use.
- For zero-slot weapons, show a compact "No attachment slots" pill instead of a helper block or fake empty slot row.

Verified data:

- Anvil: Muzzle Mod, Tech Mod.
- Stitcher: Muzzle Mod, Underbarrel Mod, Magazine Mod, Stock Mod.
- Ferro: Muzzle Mod, Underbarrel Mod, Stock Mod.
- Jupiter, Equalizer, Rascal: zero attachment slots.

## Blueprint Tracker Decisions

- Keep the existing overview `GridView.builder` and `BlueprintTile` untouched in behaviour.
- Add a non-interactive overlay frame around the first five complete rows, calculated from the current 10-column grid metrics.
- Add jump controls next to the existing zoom controls. Down jumps directly toward the lower grid and zooms into the overview if the full grid is still at scale 1; up jumps back toward the top.
- The frame and jumps use the same fitted overview geometry, so they remain aligned with current zoom/pan behaviour.

## Scrappy, Bench and Quest Decisions

- Keep shared tracker screen, repository, state model, completion logic and item sheets unchanged.
- Add adaptive carousel height by maximum item count in the active card set.
- One-item sections now receive a shorter carousel stage, two-item cards a middle height, and larger cards keep the existing larger stage.
- This also applies to Quest Tracker because quests already use the shared grouped tracker path.

## My Hub Decisions

- Preserve Command Centre routing as the main home and keep Tool Deck as the optional My Hub carousel.
- Fix bottom dock Trade navigation to open the existing Trading Overview card.
- Fix Referral Tools to open `ReferralToolsScreen`.
- Add a small My Hub module catalog for route/readability tests without moving systems around.

## Help Decisions

- Add `ArcHelpCentreScreen` with compact category cards, search, expandable answers and direct app links where a route exists.
- Required categories are present:
  - Getting Started
  - Blueprint Tracker
  - Favourite Loadout
  - Trading
  - Match Rider
  - Operations
  - Profile and Reputation
  - Privacy, Safety and Reporting
  - Closed Beta Feedback
- Terms, Privacy and Trader Code of Conduct remain directly accessible.
- Help Centre is registered in app routing and drawer navigation.

## Command Centre Tracker Review

- No Command Centre engine changes were made.
- Tracker density was improved at the shared Scrappy/Quest screen layer, which avoids duplicated card logic in Command Centre.
- Existing compact hierarchy, Tool Deck behaviour and `/my-hub` routing were preserved.

## Tests Added or Updated

- Blueprint overview frame bounds, jump target calculation, top/bottom jump state and seed order check.
- Compact tracker card sizing for zero, one and multi-item states.
- Help category uniqueness, category resolution and non-empty answer content.
- My Hub module route catalog and Trading Overview route resolution.
- PASS 259A exact Favourite Loadout weapon slot expectations.

## Deferred

- No visual golden tests were added because the repository does not use stable golden support.
- No persistence or Command Centre ranking changes were made; those systems were outside this pass.
- No broad My Hub redesign was attempted because Command Centre remains the approved home and the existing carousel is intentionally preserved as Tool Deck.
