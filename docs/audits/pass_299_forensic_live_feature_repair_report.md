# PASS 299 Forensic Live Feature Repair Report

Date: 2026-07-29

Baseline commit: `136c86585d1cc13f3d32e99be3a8deece754a9f6`

Status before this pass: `NOT READY - CRITICAL END-TO-END FUNCTIONAL FAILURES`

## Executive Summary

PASS 299 repaired high-confidence repository-side causes for live feature invisibility and data appearing empty after refresh. The most important defect was an Auth timing race: blueprint and notification streams captured `FirebaseAuth.currentUser` once when widgets initialized. On web hard refresh, Auth can still be restoring at that moment, so the stream permanently emitted an empty collection even after the user signed in.

The pass also made the route-facing Admin Console expose the Map & Intel Editor, added direct in-app Communications verification that does not depend on push or Cloud Functions, corrected Admin Map Editor coordinate math to preserve map asset aspect ratio, and added runtime diagnostics to the existing Release Readiness admin panel.

No protected Blueprint Grid rendering, `BlueprintTile`, ownership write logic, duplicate write logic, `_buildGrid`, carousel, or auth-flow code was changed.

## Repaired Defects

| Area | Root cause | Fix applied | Files |
| --- | --- | --- | --- |
| Blueprint persistence appears wiped after reload | `watchMyBlueprintStates()` used `currentUser` once. If Auth had not restored, the stream stayed empty. | Stream now follows `authStateChanges()`, binds after UID is available, and maps missing `blueprintId` fields from doc IDs. | `lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart` |
| Legacy blueprint state not recoverable | Previous repository had only canonical reads. | Added additive recovery preview/merge for legacy candidate paths. Recovery runs only when canonical state is empty and legacy states exist. | `lib/features/trading_hub/arc_raiders/models/arc_blueprint_state_recovery.dart`, repository |
| Trade and Communications live state can appear empty after reload | Trading repository notification and blueprint streams had the same one-shot UID pattern. | Streams now follow `authStateChanges()` and use doc ID fallback for notification IDs. | `lib/features/trading_hub/arc_raiders/repositories/trading_repository.dart` |
| Notification preferences/devices can appear empty after reload | Notification repository preference/device streams used one-shot UID. | Streams now follow `authStateChanges()`. | `lib/features/notifications/data/uag_notification_repository.dart` |
| Admin test notification invisible when push/Cloud Functions unavailable | Admin test send queued `notification_broadcasts`; in-app inbox rows depended on Cloud Function processing. | Added direct inbox-only admin test path that writes a valid `trading_notifications/{notificationId}` record and reads it back. Broadcast path remains unchanged. | `lib/features/notifications/data/uag_notification_repository.dart`, `lib/features/notifications/widgets/uag_admin_broadcast_panel.dart` |
| Admin Map & Intel Editor existed but was not visible in the active Admin Console | `/admin-console` uses `lib/screens/build/admin_console_screen.dart`, while only `lib/screens/admin_console_screen.dart` exposed the editor card. | Added the Map & Intel Editor card to the route-facing build admin console and added a direct route case. | `lib/screens/build/admin_console_screen.dart`, `lib/main.dart` |
| Admin marker placement drifted on nonmatching panel ratios | Editor stretched map images to fill panel dimensions, so normalized tap/drag positions could diverge from asset coordinates. | Editor now centers an aspect-preserving map surface based on registered asset dimensions. | `lib/features/trading_hub/arc_raiders/screens/arc_admin_map_editor_screen.dart` |
| Map authoring lacked fixed reference grid | Editor and player map had no shared visual reference grid over renderable map assets. | Added a toggleable Admin Editor grid and a subtle player map reference grid. | Admin editor, `arc_raid_intelligence_map.dart` |
| Live build/deploy mismatches were hard to diagnose in app | Existing Release Readiness panel did not show runtime build/Firebase/Auth path diagnostics. | Added Runtime Diagnostics to the existing Release Readiness panel. | `lib/features/release/models/uag_release_runtime_diagnostics.dart`, `uag_release_readiness_panel.dart` |

## Canonical Data Paths

Blueprint persistence:

- Canonical: `users/{uid}/arc_blueprints/{blueprintId}`
- Legacy candidates scanned for additive recovery:
  - `users/{uid}/arc_blueprint_states/{blueprintId}`
  - `users/{uid}/blueprints/{blueprintId}`
  - `arc_blueprint_states/{uid}/states/{blueprintId}`
  - `arc_blueprints/{uid}/states/{blueprintId}`

Communications:

- Broadcast queue unchanged: `notification_broadcasts/{broadcastId}`
- Inbox records: `trading_notifications/{notificationId}`
- Direct admin inbox test source: `admin_direct_inbox_test`

Map Intel:

- Published/admin markers: `arc_admin_map_markers/{markerId}`
- Coverage reports remain in the existing admin map editor repository paths.

Release diagnostics:

- Feature flags: `config/feature_access`
- Release readiness: `config/release_readiness`

## Routes Verified by Code

- `/admin-console` opens `AdminConsoleScreen`.
- `/admin-map-intel-editor` now opens `ArcAdminMapEditorScreen`.
- Admin Console "Map & Intel Editor" opens `ArcAdminMapEditorScreen`.
- Admin Broadcast "Inbox Test" creates a direct in-app notification.
- Broadcast "Test Send To Me" and "Queue Broadcast" remain Cloud Function queued paths.

## Public Map Source Research

This pass used public-source research only to inform the authoring taxonomy and QA expectations. No restricted third-party marker data was copied into the app.

- [ARC Maps](https://arcmaps.com/maps/) shows live map selectors and filters for maps including Dam Battlegrounds, Buried City, Acerra Spaceport, The Blue Gate, Stella Montis, Riven Tides, and marker layers such as blueprints, sentinels, extraction points, containers, and quest objectives.
- [ARC Maps overview](https://arcmaps.com/) describes map sectors, blueprint locations, sentinel spawns, quest guides, hidden bunkers, resource farming, and community routes.
- [ARC Raiders map conditions](https://arcraiders.com/map-conditions) lists live condition types such as Close Scrutiny, Electromagnetic Storm, Hidden Bunker, Hurricane, Locked Gate, and Night Raid.
- [ARC Raiders Wiki map conditions](https://arcraiders.wiki/wiki/Category%3AMap_Conditions) lists the broader map condition category pages.
- [Raider Buddy maps](https://raiderbuddy.com/maps) exposes useful public category examples such as Extraction, Player Spawn, Supply Station, Field Depot, Raider Camp, Hatch, Locked Room, Field Crate, Breach Room, Weapon Case, Ammo Crate, Raider Cache, and ARC enemy husks.

## Automated Coverage Added

- `test/arc_blueprint_state_recovery_test.dart`
  - Confirms recovery merge is additive.
  - Confirms current state is preserved where it already exists.
  - Confirms legacy-only states are detected for migration.
- `test/arc_admin_map_editor_screen_test.dart`
  - Extended to assert the Grid control is exposed with existing calibration/import controls.

## Deferred Live Checks

These require the real Firebase project, admin credentials, a deployed web build, or physical browser/device access:

- Verify a user with existing Firestore blueprint docs survives Chrome hard refresh with correct owned/duplicate states.
- Verify legacy blueprint recovery against any real legacy collections that still exist.
- Verify direct Admin Inbox Test appears immediately in Communications on the target user account.
- Verify queued broadcast still creates in-app inbox rows when `functions/index.js` is deployed and active.
- Verify push notifications remain unchanged on Android.
- Verify Chrome FCM token registration remains working after no service-worker changes in this pass.
- Verify Admin Map Editor publish writes live markers visible to Raid Intelligence.
- Verify calibrated coordinates against real map screenshots and official/provisionally aligned assets.

## Readiness Assessment

Repository-side repair status: `REPAIRED - NEEDS LIVE QA`

Closed Beta status after this pass should not be called ready until the manual QA checklist in `docs/audits/pass_299_manual_end_to_end_qa.md` is completed against the deployed app and real Firebase environment.
