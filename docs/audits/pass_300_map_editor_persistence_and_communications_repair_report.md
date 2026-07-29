# PASS 300 Map Editor Persistence and Communications Repair Report

Date: 2026-07-29

Baseline: `5252dc339616822dda296f3a92a61558915363ea`

## Summary

PASS 300 repairs the two confirmed live blockers first:

1. `Save Draft` in the Admin Map & Intel Editor now writes durable marker records to Firestore at `arc_admin_map_markers/{markerId}` instead of only saving browser-local `SharedPreferences`.
2. The visible admin `Test Send To Me` action now writes a direct Communications inbox record to `trading_notifications/{notificationId}` for the signed-in admin, then reports the document path and offers a direct route to Communications.

The same pass also completes the directly related POI CRUD repair needed for production map editing: create named POI, edit selected POI, duplicate selected POI, and archive selected POI.

## Firestore Paths

- Map editor markers: `arc_admin_map_markers/{markerId}`
- Communications inbox: `trading_notifications/{notificationId}`
- Broadcast queue retained: `notification_broadcasts/{broadcastId}`

## Map Editor Repairs

Files:

- `lib/features/trading_hub/arc_raiders/models/arc_admin_map_marker.dart`
- `lib/features/trading_hub/arc_raiders/repositories/arc_admin_map_editor_repository.dart`
- `lib/features/trading_hub/arc_raiders/screens/arc_admin_map_editor_screen.dart`
- `test/arc_admin_map_marker_test.dart`
- `test/arc_admin_map_editor_screen_test.dart`

Implemented:

- `loadDrafts` now reads `arc_admin_map_markers` for the active map/layer, falling back to legacy local drafts only when Firestore has no records.
- `saveDraftMarkers` batch-writes current non-archived markers into `arc_admin_map_markers`.
- Saved markers retain draft/published state, aliases, coordinates, admin metadata, `createdByUid`, `updatedByUid`, `createdAt`, and `updatedAt`.
- `Save Draft` reports saved/failed state without clearing unsaved edits on failure.
- `Add POI` starts map placement; the next map tap opens a named marker dialog at the tapped coordinate.
- Selected markers can be edited, duplicated, or archived.
- Archived markers are persisted as `state: archived` and hidden after reload.
- Marker hit areas remain usable while visible marker diameter is reduced for precision.

## Communications Repairs

Files:

- `lib/features/notifications/data/uag_notification_repository.dart`
- `lib/features/notifications/widgets/uag_admin_broadcast_panel.dart`
- `test/notification/uag_notification_models_test.dart`

Implemented:

- Added a direct inbox schema builder for admin test messages.
- Direct tests write to `trading_notifications`, the same collection used by `TradingRepository.watchNotifications`.
- `Test Send To Me` now targets the current admin UID and creates the visible in-app Communications item immediately.
- Read-back diagnostics show whether the document can be read and display `trading_notifications/{notificationId}`.
- `Open Communications` opens `/trading-hub/arc-raiders/notifications`.
- `Queue Broadcast` remains unchanged for Cloud Function-driven broadcast delivery.

## Tests Added or Updated

- `test/arc_admin_map_marker_test.dart`
  - Marker aliases round-trip.
  - Durable draft preparation excludes archived markers and writes admin metadata.
- `test/arc_admin_map_editor_screen_test.dart`
  - Editor exposes `Add POI`.
  - Save Draft invokes the durable save adapter and reports success.
- `test/notification/uag_notification_models_test.dart`
  - Direct admin inbox payload matches the Communications query shape and parses as a `TradingNotification`.

## Deferred Items

These were intentionally left for later passes after the two live blockers are committed:

- Full browser-driven manual QA against production Firebase.
- Optional editor safety enhancements, including unsaved-exit confirmation and advanced conflict handling.
- Bulk editor workflows and advanced conflict resolution.
- Emulator-backed Firestore rule tests if the local Java/Firebase emulator environment is available.

## Validation Results

Completed:

- `flutter pub get`: passed.
- `dart format --output=none --set-exit-if-changed lib test`: passed, 527 files, 0 changed.
- `flutter analyze --no-pub`: passed, no issues found.
- `flutter test`: passed, 363 tests.
- `node --check functions/index.js`: passed.
- `flutter build web --release --no-wasm-dry-run`: passed, built `build\web`.
- `flutter build apk --debug`: passed, built `build\app\outputs\flutter-apk\app-debug.apk`.
- `git diff --check`: passed.

Unavailable in this local environment:

- Functions Node tests: `functions/package.json` declares no test script, and the local `npm` shim fails before script discovery because `C:\Users\mikem\AppData\Roaming\npm\node_modules\npm\bin\npm-cli.js` is missing.
- Firebase emulator/rules checks: no `firebase` CLI or local Firebase CLI binary is available on PATH/in-repo. Java 21 runtime exists at `C:\Program Files\Android\Android Studio\jbr\bin\java.exe`, but the Firebase CLI required to start emulator checks is unavailable.
