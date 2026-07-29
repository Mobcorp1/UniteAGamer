# PASS 300 Preimplementation Forensic Audit

Date: 2026-07-29

Baseline: `5252dc339616822dda296f3a92a61558915363ea`

## Active Routes

| Route | Active screen | Notes |
| --- | --- | --- |
| `/admin-map-intel-editor` | `ArcAdminMapEditorScreen` in `lib/features/trading_hub/arc_raiders/screens/arc_admin_map_editor_screen.dart` | Registered in `lib/main.dart`; opened from the route-facing `lib/screens/build/admin_console_screen.dart`. |
| `/trading-hub/arc-raiders/notifications` | `TradingNotificationsScreen` in `lib/features/trading_hub/arc_raiders/screens/trading_notifications_screen.dart` | Labelled "Communications Centre" in the UI and drawer. |

## Map Editor Data Flow

Classes involved:

- `ArcAdminMapEditorScreen`
  - Loads seed markers from `ArcRaidIntelligenceSeedData`.
  - Loads draft markers via `ArcAdminMapEditorRepository.loadDrafts`.
  - Loads imported markers via `ArcAdminMapEditorRepository.loadImportCache`.
  - Mutates marker coordinates in local `_markers`.
  - Calls `_repository.saveDrafts(_mapId, _layer, _markers)` from `Save Draft`.
  - Calls `_repository.publish` / `publishAll` for published markers.
- `ArcAdminMapEditorRepository`
  - Current `loadDrafts` / `saveDrafts` uses `SharedPreferences` key `arc_admin_map_editor_drafts_v1:{mapId}:{layer}`.
  - Firestore publish uses `arc_admin_map_markers/{markerId}`.
  - Live map reads use `arc_admin_map_markers` filtered by `mapId`, `layer`, and either `state == published` or `provisionalVisible == true`.
- `ArcAdminMapMarker`
  - Serializes `id`, `mapId`, `layer`, `kind`, `name`, `description`, `point`, source metadata, confidence, state, evidence, `createdByUid`, `createdAt`, and `updatedAt`.

Current Firestore/rule paths:

- Published/admin markers: `arc_admin_map_markers/{markerId}`
- Coverage reports: `arc_map_marker_coverage_reports/{reportId}`
- Blueprint drop reports: `arc_blueprint_drop_reports/{reportId}`
- Community Intel reports: `arc_community_intel_reports/{reportId}`

Firestore rules:

- `arc_admin_map_markers` read: admin/dev, published markers, or permitted provisional markers.
- `arc_admin_map_markers` create/update/delete: admin/dev only.

## Map Editor Root Cause

`Save Draft` appears to do nothing in production because it does not write to the canonical Firestore marker collection. The active method `ArcAdminMapEditorRepository.saveDrafts` writes only to browser-local `SharedPreferences`. Those records are not the same canonical path used by the live map/Intel repository, are not durable across browsers/devices, and cannot be inspected as production map editor data in Firestore.

Secondary issues in the current editor flow:

- New marker creation is labelled "New Intel", opens a dialog first, and creates the marker at map centre rather than placing it with a map click/tap.
- Existing delete is local-only: `_deleteSelected` removes the marker from `_markers` but does not archive/delete a canonical Firestore record.
- Existing "Copy" copies JSON to clipboard; it does not duplicate a marker into editable draft state.
- Marker visible diameter is 36px normal / 42px selected, which is too large for precise POI placement.
- `Save Draft` has no durable saved/dirty/failed state and does not report the canonical collection path or write count.

## Communications Data Flow

Active Communications query:

- `TradingRepository.watchNotifications`
- Collection: `trading_notifications`
- Filters:
  - `targetUid == current signed-in UID`
  - `orderBy('createdAt', descending: true)`
- Model: `TradingNotification.fromMap`
- Screen: `TradingNotificationsScreen`
- UI filters are local only; the default filter is `All`.

Required schema for visible inbox records:

- `id`
- `targetUid`
- `actorUid`
- `title`
- `body`
- `type`
- `listingId`
- `offerId`
- `sessionId`
- `watchId`
- `queueId`
- `preparationId`
- `opportunityId`
- `route`
- `deepLink`
- `imageUrl`
- `entityId`
- `read`
- `createdAt`
- `updatedAt`

Firestore rules:

- `trading_notifications/{notificationId}` read: target user or admin/dev.
- Create: signed-in actor with `request.resource.data.actorUid == request.auth.uid`, non-empty `targetUid`, and `id == notificationId`.
- Update: target/admin/dev preserving `id`, `targetUid`, and `actorUid`.

## Communications Root Cause

PASS 299 added a direct `Inbox Test` button, but the existing and more discoverable `Test Send To Me` action still writes a queued `notification_broadcasts/{broadcastId}` document. That path depends on Cloud Functions to materialize `trading_notifications/{notificationId}` inbox rows. If Functions are unavailable, delayed, undeployed, or misconfigured, pressing the visible test action creates no immediate Communications item.

The production-facing test action must write a complete `trading_notifications/{notificationId}` inbox document directly for the currently authenticated admin UID, then show the document path/id and let the live Communications stream pick it up. Queued broadcast creation can remain for actual broadcast delivery, but it cannot be the primary in-app Communications test.

## Implementation Direction

1. Move map draft persistence to `arc_admin_map_markers/{markerId}` while keeping seed markers as fallback only.
2. Preserve draft, published and archived states in the canonical marker model.
3. Add aliases and `updatedByUid` to marker serialization.
4. Make create, edit, duplicate and delete/soft-archive write through the canonical repository.
5. Make the main admin "Test Send To Me" action create a complete direct inbox record in `trading_notifications/{notificationId}` for the signed-in admin.
6. Keep Cloud Function broadcast queuing as a separate broadcast action.
