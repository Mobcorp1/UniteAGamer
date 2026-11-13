# Admin map layer moves and published Blueprint POI links

Starting branch: `codex/full-arc-ui-convergence`.
Starting HEAD: `3a2985c2b3dee46796c223e215893ffb4ed27ea5`.

The Hunter Rat implementation already in the working tree was paused when Mike supplied this pass. Those files, Firestore/Storage rules, functions, functions/node_modules, hosting cache, existing audits and backups were not staged or changed by this map/POI pass. No deployment, branch switch, reset, restore, clean, stash, map artwork change or live-data backfill was performed.

## Pass A

Edit Marker exposes only the current map's registered layers and preselects the marker's current layer. Single-layer maps omit the selector. Applying a different layer opens a second explicit move confirmation. Cancellation leaves the marker unchanged.

The repository runs a transaction against `arc_admin_map_markers/{existingDocumentId}`. It refuses missing records and stale layer/state/edited fields; it never creates a replacement or duplicate. Only layer and intentionally edited form fields are patched, with server update time and admin UID. Published state, map ID, X/Y, verification, evidence, seed/source identities and unknown future fields survive. No republish is needed.

The editor changes local state only after persistence succeeds, retains it on failure, and blocks map/layer switches while saving. Undo snapshots are cleared after a persisted move so undo cannot resurrect the old layer. Canonical records from all layers override seed/import caches on reload, preventing old-layer seed resurrection. Unrelated draft edits remain in memory. A previously unsaved local-only marker must be saved before it can be moved.

## Pass B

The report sheet subscribes to `watchPublishedMap` for the selected map. Location choices use current published POI, extraction and hatch markers (the existing named-location categories), excluding drafts, archives, other maps, loot and enemies. IDs are selection values and current names are labels. Loading, empty and retry states are shown; renamed/moved locations retain selection by identity.

`addDropReport(publishedMarkerId: ...)` reloads the actual document and checks eligibility. It stores `markerId` as the actual Firestore document ID, `poiId` as the existing seed reference where available (otherwise the marker ID), `poiName`, `intelligenceLayer`, and `historicalPoint`. The model exposes readable fields through existing intelligence getters. Report signatures distinguish actual marker IDs, so distinct locations sharing a name cannot be merged accidentally. Ownership/dupe calculations and grid ordering are unchanged.

The resolver gives exact published document IDs priority over seed/name hints and reads the current marker point and layer. Raid Intelligence already subscribes to all published markers for the map; the opportunity engine uses that resolved location and current label. Later admin moves therefore update existing reports' displayed Intel without rewriting report coordinates.

## Historical compatibility

No historical reports were deleted or rewritten. Exact normalized names and aliases resolve automatically only when unique. Ambiguous matches never choose a quality-ranked winner; they retain a legacy fallback with `needsAdminReview`, or remain unresolved when no fallback exists. Unmatched reports retain existing static/legacy coordinate resolution.

`canonicalBackfillPatch(existingMarkerId: ...)` supplies a reviewable, non-writing patch only for a unique high-confidence resolution. It refuses to replace an existing marker ID and preserves historical coordinates. A persisted migration is optional; runtime compatibility works without it. Ambiguous records still need an admin decision.

## Exact implementation and test files

Pass A:
- `lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart`
- `lib/features/trading_hub/arc_raiders/screens/arc_admin_map_editor_screen.dart`
- `test/arc_admin_map_editor_screen_test.dart`
- `test/arc_marker_single_update_test.dart`

Pass B:
- `lib/features/trading_hub/arc_raiders/data/arc_published_report_pois.dart`
- `lib/features/trading_hub/arc_raiders/data/arc_intelligence_location_resolver.dart`
- `lib/features/trading_hub/arc_raiders/data/arc_blueprint_opportunity_engine.dart`
- `lib/features/trading_hub/arc_raiders/models/arc_blueprint_drop_report.dart`
- `lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart`
- `lib/features/trading_hub/arc_raiders/widgets/arc_blueprint_drop_report_sheet.dart`
- `test/arc_published_poi_linking_test.dart`
- `test/arc_published_poi_picker_test.dart`

## Validation

Final validation and commits are recorded below after completion.
