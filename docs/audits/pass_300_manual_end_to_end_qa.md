# PASS 300 Manual End-to-End QA

Date: 2026-07-29

Baseline: `5252dc339616822dda296f3a92a61558915363ea`

## Scope

This checklist is scoped to the two confirmed live blockers and directly related POI CRUD repair:

- Admin Map & Intel Editor draft persistence.
- Admin Map & Intel Editor named POI create/edit/duplicate/archive.
- Admin Communications `Test Send To Me` visibility in Communications.

Optional editor safety features remain out of scope until these blocker fixes are committed.

## Map Editor Persistence

Route: `/admin-map-intel-editor`

Firestore path: `arc_admin_map_markers/{markerId}`

| Check | Viewport | Expected result | Automated coverage | Manual status |
| --- | --- | --- | --- | --- |
| Move an existing marker, press `Save Draft`, refresh the editor | Web desktop | Marker reloads from Firestore at the edited coordinate | `test/arc_admin_map_marker_test.dart`, `test/arc_admin_map_editor_screen_test.dart` | Required against production Firebase |
| Save Draft shows durable write feedback | Web desktop/mobile | Status card and snackbar show saved state, write count, and `arc_admin_map_markers` | `test/arc_admin_map_editor_screen_test.dart` | Required |
| Save failure does not clear dirty state | Web desktop/mobile | Error is visible and edits remain local until retry | Repository throws surface through screen error path | Manual auth/rules failure check required |
| Legacy local draft fallback still loads if no Firestore records exist | Web desktop | Existing local-only drafts are not discarded during migration | Repository fallback preserved | Manual spot check optional |

## POI CRUD

Route: `/admin-map-intel-editor`

| Check | Viewport | Expected result | Automated coverage | Manual status |
| --- | --- | --- | --- | --- |
| `Add POI` starts map placement | Web desktop/mobile | Next map tap opens named POI dialog at tapped coordinate | Widget exposes `Add POI`; manual tap placement required | Required |
| Create named POI | Web desktop/mobile | New draft marker appears, can be selected, saved to Firestore | Model/repository save preparation covered | Required |
| Edit selected POI | Web desktop/mobile | Name, aliases, type, description, source, confidence, and blueprint link update locally and persist on Save Draft | Marker serialization covers aliases | Required |
| Duplicate selected POI | Web desktop/mobile | Copy is offset, selected, draft state, and persists through Save Draft | Save path covered; duplicate UI manual | Required |
| Delete selected POI | Web desktop/mobile | Confirmation archives canonical marker and removes it from editor list; reload keeps it hidden | Repository archive path covered by implementation | Required |
| Marker size is usable | Mobile and desktop | Normal/selected markers no longer obscure nearby POIs | Manual visual check required | Required |

## Communications Test

Routes:

- Admin broadcast surface that hosts `UagAdminBroadcastPanel`
- Communications: `/trading-hub/arc-raiders/notifications`

Firestore path: `trading_notifications/{notificationId}`

| Check | Viewport | Expected result | Automated coverage | Manual status |
| --- | --- | --- | --- | --- |
| Press `Test Send To Me` | Web desktop/mobile | A direct inbox record is written for the signed-in admin UID | `test/notification/uag_notification_models_test.dart` | Required against production Firebase |
| Read-back diagnostic appears | Web desktop/mobile | Panel displays `trading_notifications/{notificationId}` and target UID | Schema/path test covered | Required |
| `Open Communications` navigates to inbox | Web desktop/mobile | Communications route opens and the new unread item appears under `All` / `Announcements` | Route is unchanged; manual stream check required | Required |
| Broadcast queue remains available | Web desktop/mobile | `Queue Broadcast` still writes a queued broadcast for Cloud Function delivery | Existing repository path unchanged | Manual production broadcast dry run only |

## Remaining Manual-Only Checks

- Confirm Firestore security rules allow the admin user to create/read `arc_admin_map_markers` and direct `trading_notifications`.
- Confirm production web reload reads the moved marker from Firestore, not browser cache.
- Confirm Communications item appears with the real signed-in admin UID and can be marked read/deleted.
- Confirm Android/web builds still show the same editor and Communications routes with no overflow.
