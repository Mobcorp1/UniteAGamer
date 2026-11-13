# PASS 302A Blueprint Runtime Trace

## Scope

This pass traced and repaired two live defects without changing Blueprint grid ordering, BlueprintTile behavior, ownership writes, duplicate writes, `_buildGrid`, carousel behavior, authentication, or broader Command Centre systems.

## Starting Point

- Branch: `beta-stabilisation`
- Starting HEAD: `05f5ca964280f48a8dc640043eed5b2d5b08ec98`
- Preserved previous pass: `PASS 303: stabilise closed beta core journey`
- Working tree before implementation: clean

## Blueprint Report Resolution Path

1. Firestore source: `arc_blueprint_drop_reports`
2. Deserialisation: `lib/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart`
   - `ArcBlueprintDropReport.fromMap`
   - `intelligenceMapName`
   - `intelligencePoiId`
   - `intelligencePoiName`
   - `historicalPoint`
3. Repository stream: `lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart`
   - `watchRecentReports`
   - `watchReportsForBlueprint`
4. Map screen stream composition: `lib/features/trading_hub/arc_raiders/screens/arc_raid_intelligence_screen.dart`
   - streams Blueprint states, loadout, recent reports, community reports, and published Admin map markers
5. Published Admin marker source: `lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart`
   - `watchPublished`
   - Firestore collection: `arc_admin_map_markers`
6. Canonical resolution: `lib/features/trading_hub/arc_raiders/data/arc_intelligence_location_resolver.dart`
   - `resolve`
   - `resolveBlueprintReport`
7. Population / aggregation:
   - `lib/features/trading_hub/arc_raiders/data/arc_world_intel_population_engine.dart`
   - `lib/features/trading_hub/arc_raiders/data/arc_blueprint_opportunity_engine.dart`
   - `lib/features/trading_hub/arc_raiders/data/arc_raid_intelligence_engine.dart`
8. Rendering view model:
   - `ArcRaidIntelligenceEngine.build`
   - `ArcRaidMapMarker`
   - `lib/features/trading_hub/arc_raiders/widgets/arc_raid_intelligence_map.dart`

## Root Cause: Map Resolution

The live symptoms were caused by a combination of compatibility and fallback defects:

- Persisted field parsing only treated `poiName` and `locationName` as first-class location labels. Historical payload fields such as `reportedLocation`, `dropLocation`, `sourceLocation`, `locationLabel`, `landmark`, `map`, and `mapId` were not reliably normalised into the resolver input.
- Historical `mapId` values such as `buried_city` could become `Unknown Map`, causing reports to miss the Buried City resolver path.
- The resolver matched `historicalAlias` against Admin marker aliases, but did not match the historical label against the published marker's current name. A report whose only surviving label was `Town Hall` could therefore skip the published Admin marker unless that label was duplicated into aliases.
- Coordinate fallback was allowed after a named location failed to resolve. That made stale historical coordinates capable of influencing the rendered POI even when the meaningful label said something else.
- The Raid Intelligence screen used `watchLiveMarkers`, which included provisional markers. Standard user resolution now uses `watchPublished` so draft/provisional moves do not alter standard-user report placement.
- World-intel duplicate merging allowed same-Blueprint markers near each other to merge even when the named POI was different.
- Opportunity-cluster merging allowed nearby report-driven clusters to merge without checking whether the reports shared the same resolved location identity.
- Unresolved drop reports used the same centre fallback point, which could collapse review-required reports into a misleading shared position.

## Resolution Contract Now Applied

The active resolver order is:

1. Explicit canonical POI ID / seed reference, scoped to the current map.
2. Explicit published marker ID, scoped to the current map.
3. Seed/source record ID, scoped to the current map.
4. Exact normalised published marker name, scoped to the current map.
5. Exact registered alias, scoped to the current map.
6. Static map marker / legacy POI exact match, scoped to the current map.
7. Coordinate-only resolution, only when no meaningful text label exists.
8. Review-required unresolved result when text exists but does not resolve.

When a named location exists and does not resolve, coordinates are retained only as review context and are not allowed to snap the report to a nearby marker.

## Reported Location Outcomes Covered

- `Town Hall` resolves to the published `Town Hall` Admin marker and does not become `Hospital`.
- `Main Street` resolves to the published `Main Street` Admin marker.
- `Gas Station` resolves to the published `Gas Station` Admin marker and does not become `Town Hall`.
- `Abandoned Highway Camp` resolves to the published `Abandoned Highway Camp` Admin marker and does not become `Warehouse`.
- `First Wave Cache` remains unresolved unless an explicit canonical marker ID, alias, safe legacy mapping, or coordinate-only report supports it.

## Blueprint Ownership Hydration Path

1. Authentication: `FirebaseAuth.instance.authStateChanges`
2. Repository: `lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart`
   - canonical path: `users/{uid}/arc_blueprints`
   - legacy paths scanned by `legacyStoragePathCandidatesFor`
   - recovery merge: `ArcBlueprintStateRecovery.merge`
3. State model: `lib/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart`
   - `ArcBlueprintState`
   - `ArcBlueprintStateSnapshot`
4. Grid screen: `lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart`
   - `watchMyBlueprintStateSnapshot`
   - `_buildOwnershipSynchronizingState`
   - existing `_applyFilter`, `_buildCounts`, overview, controls, and grid logic remain intact

## Root Cause: Ownership Hydration

The Blueprint grid previously used `snapshot.data ?? <String, ArcBlueprintState>{}` directly in the `StreamBuilder`. During hard refresh or delayed auth/Firestore hydration, a waiting snapshot therefore rendered as a real empty collection. The user could temporarily see zero owned Blueprints even though the remote state later recovered.

The repository now exposes `ArcBlueprintStateSnapshot` with explicit `signedOut`, `loading`, `loaded`, and `error` statuses. The grid only treats an empty map as valid after a confirmed load. While loading with no cached state, it shows a compact synchronising state. During refresh, any last valid state for the active user can remain usable until replacement data arrives.

## Performance Notes

- Published marker lookup is now constrained to published markers for standard Raid Intelligence rendering.
- Resolver matching uses map-scoped marker lists and exact normalised label sets.
- Report-driven cluster merging now checks semantic location identity before merging nearby icons.
- Unresolved review markers receive deterministic per-report review points instead of one shared map-centre fallback.

## Validation Coverage Added

- Historical report payload parsing through `ArcBlueprintDropReport.fromMap`.
- Exact Buried City report label placement for Town Hall, Main Street, Gas Station, and Abandoned Highway Camp.
- Negative assertions for Town Hall/Hospital, Gas Station/Town Hall, and Abandoned Highway Camp/Warehouse.
- First Wave Cache unresolved behavior.
- Published marker move propagation.
- Draft marker exclusion from standard resolution.
- One Blueprint reported at three POIs remains three report-driven clusters.
- Hydration snapshot loading vs confirmed empty ownership state.

## Live Firestore Inspection

No direct private Firestore data was copied into this audit. Historical compatibility was reconstructed from the current repository write paths and the field aliases listed in the PASS 302A brief.
