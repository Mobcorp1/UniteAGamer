# PASS 274 Manual QA Checklist

## Blueprint Grid Orientation

| Viewport | Scenario | Expected result |
| --- | --- | --- |
| Android portrait | Open Blueprint Tracker, switch to In-Game View | Rotate prompt appears; Full Grid button is reachable. |
| Android landscape | Open Blueprint Tracker, switch to In-Game View | Framed grid renders; no portrait rotate prompt. |
| Tablet portrait | Open Blueprint Tracker, switch to In-Game View | Framed grid remains usable; no rotate prompt. |
| Desktop/web | Open Blueprint Tracker, switch to In-Game View | Framed grid is centered and controls remain reachable. |

## Search Results

| Viewport | Scenario | Expected result |
| --- | --- | --- |
| Android portrait | Search for a single blueprint such as `Bobcat` | One large readable card renders; no tiny full-grid scaling. |
| Android portrait | Search for two results | Results stack when width is narrow; text remains readable. |
| Android landscape | Search for two to four results | Results use larger two-column cards when width allows. |
| Desktop/web | Search for five or more results | Results use compact grid density without overflow. |

## Favourite Loadout Bridge

| Scenario | Expected result |
| --- | --- |
| Owned loadout-eligible weapon tile | Loadout action is visible without replacing ownership or duplicate controls. |
| Tap loadout action for a weapon | User can choose Primary Weapon or Secondary Weapon. |
| Tap loadout action for a compatible attachment | Only compatible primary/secondary attachment slots are offered. |
| Tap loadout action for a quick-use item with empty slots | Empty quick-use slots are offered first. |
| Tap loadout action with all quick-use slots full | Replacement slots are offered. |
| Tap loadout action for an ineligible part/resource | No Favourite Loadout action is shown. |

## Intel Reporting

| Scenario | Expected result |
| --- | --- |
| Open report sheet | Acquisition Source order is Normal Drop, Quest Reward, Trade, Gifted, Trial. |
| Open raid phase selector | Raid phases read Full, Mid, Late. |
| Open condition selector | Neutral option reads No Map Event and appears first. |
| Submit raid report with local time | Local time accepts valid `HH:mm`, derives the time-of-day bucket, and saves. |
| Enter invalid local time | Submit is disabled until a valid `HH:mm` value is entered. |
| Choose The Blue Gate | The POI list contains the canonical 20 named POIs. |
| Change map after choosing a POI | Invalid previous map POI selection clears before submit. |
| View Market Intelligence details | Saved local time appears when a report has it. |

## Responsive Risks To Recheck

- No Blueprint search card overflows on Android portrait or landscape.
- Loadout action chips do not cover blueprint title text or ownership badges.
- Report sheet remains scrollable with the keyboard open on mobile.
- Intel dropdowns remain reachable with long POI names.
- Bottom dock and ad banner do not cover report submit actions.
