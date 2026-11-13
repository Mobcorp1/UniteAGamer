# PASS 302 Intelligence Resolution Audit

## Scope

PASS 302 makes Admin Map Markers the positional authority for Blueprint intelligence and introduces a reusable resolver for future intelligence systems.

Protected systems were not modified:

- Blueprint Grid rendering
- BlueprintTile
- Blueprint ownership writes
- Blueprint duplicate writes
- Stable tracker behavior
- Existing trading logic

## Blueprint Pipeline

Current Blueprint intelligence flow:

1. `ArcBlueprintDropReport` stores map, POI, source, acquisition and confirmation evidence.
2. Repositories load persisted reports.
3. `ArcRaidIntelligenceEngine` receives reports and Admin Map markers.
4. `ArcBlueprintOpportunityEngine` groups reports by blueprint and historical location key.
5. `ArcIntelligenceLocationResolver` resolves the report location dynamically.
6. Raid Intelligence renders the cluster using the resolved current marker point.

Historical Blueprint reports are not rewritten during rendering.

## Stored Location Evidence

`ArcBlueprintDropReport` supports:

- map names via `mapName`, `originalFindMapName`
- POI IDs via `poiId`, `originalFindPoiId`
- POI names via `poiName`, `originalFindPoiName`
- layer via `originalFindLayer`
- source/enemy/container labels

Blueprint reports do not need to own canonical coordinates for current rendering. Coordinates belong to Admin Map markers.

## Resolver

Reusable resolver:

`lib/features/trading_hub/arc_raiders/data/arc_intelligence_location_resolver.dart`

Resolution order implemented:

1. Canonical POI ID
2. Published marker ID
3. `seedReferenceId`
4. `sourceRecordId`
5. Current POI name
6. Historical alias
7. Static map marker
8. Legacy POI
9. Legacy coordinates

For coordinate-only legacy reports, low confidence results are marked `needsAdminReview` and are not silently attached to a POI.

## Blueprint Fix

`ArcBlueprintOpportunityEngine` now resolves Blueprint report clusters through `ArcIntelligenceLocationResolver`.

Result:

- A historical report attached to an old POI name follows the current Admin marker.
- Admin marker aliases handle renamed POIs.
- Moved Admin markers update rendered Blueprint intelligence immediately.
- Static marker and legacy POI fallbacks remain deterministic.

## World Intel Population

`ArcWorldIntelPopulationEngine` also uses the resolver when creating draft world-intel markers from Blueprint reports.

Resolved reports are tagged with resolver coordinate space, for example:

- `uag_canonicalPoiId`
- `uag_historicalAlias`
- `uag_staticMarker`

Unresolved or low-confidence reports remain draft review candidates.

## Backfill Behavior

Safe backfill signal:

- `ArcIntelligenceLocationResolution.canBackfillCanonicalReference`

This is true only when a report resolves through a canonical Admin marker with enough confidence and without admin-review requirements.

PASS 302 does not bulk rewrite reports. Future admin tooling can use the backfill signal to save canonical references safely.

## Tests

Coverage added:

- canonical POI ID resolution
- alias resolution
- moved marker rendering
- Raid Intelligence passing Admin anchors
- static marker fallback
- legacy POI fallback
- coordinate-only admin review behavior

