# Blue Gate POI Catalogue

This catalogue records the canonical The Blue Gate POIs used by Blueprint Intel reporting after PASS 274.

## Canonical POIs

1. Village
2. Barracks Parking
3. Raider's Refuge
4. Trapper's Glade
5. Adorned Wreckage
6. Highway Collapse
7. Olive Grove
8. Ruined Homestead
9. Ancient Fort
10. Checkpoint
11. Outer Gates
12. Gate Control Room
13. Warehouse Complex
14. Reinforced Reception
15. Headhouse
16. Data Vault
17. Maintenance Bunker
18. Broken Earth
19. Ridgeline
20. Abandoned Housing Project

## Legacy Alias Handling

The Intel model canonicalises these old or misspelled values when reading existing reports:

| Legacy value | Canonical POI |
| --- | --- |
| Abandoned | Abandoned Housing Project |
| Abanndened Housing Project | Abandoned Housing Project |
| Abandoned Housing | Abandoned Housing Project |
| Abandoned Housing Projects | Abandoned Housing Project |
| Olive Garden | Olive Grove |
| Maintenance Wing | Maintenance Bunker |
| Security Wing | Checkpoint |
| Traffic Tunnel | Checkpoint |
| Airshaft | Maintenance Bunker |
| Raider Hatch | Outer Gates |
| Pilgrim's Peak | Ridgeline |
| Underground Entrance | Gate Control Room |
| Mantikor Room | Reinforced Reception |

## Notes

- Both `The Blue Gate` and `Blue Gate` resolve to the same catalogue.
- Weapon-cache POIs remain available through the existing POI data store where they are explicitly marked for blueprint reporting.
- This document is a catalogue reference only; it does not change protected Blueprint Grid ordering or ownership behavior.
