# PASS 299 Manual End-to-End QA

Date: 2026-07-29

Use this checklist against the deployed Firebase app and at least one Android debug/installable build. Record tester account UID, browser/device, build commit, and Firebase project ID from the new Admin Console Release Readiness runtime diagnostics.

## Required Test Accounts

- Admin/dev account with access to `/admin-console`.
- Existing regular account with saved blueprint ownership and duplicate state.
- Fresh or near-empty regular account.
- Optional second account for notification target and map/intel visibility checks.

## Environment Checks

| Check | Route/surface | Expected result | Result |
| --- | --- | --- | --- |
| Build commit visible | `/admin-console` -> Release Readiness -> Runtime Diagnostics | Build commit is supplied or clearly marked `not supplied`. | Manual |
| Firebase project visible | `/admin-console` -> Runtime Diagnostics | Project ID matches the intended beta Firebase project. | Manual |
| Signed-in UID visible | `/admin-console` -> Runtime Diagnostics | UID matches current account. | Manual |
| Admin role diagnostic visible | `/admin-console` -> Runtime Diagnostics | Token claims and user-doc flags are both shown. | Manual |
| Feature flag doc visible | `/admin-console` -> Runtime Diagnostics | `config/feature_access` is ready or clearly missing. | Manual |

## Blueprint Persistence and Recovery

| Check | Steps | Expected result | Result |
| --- | --- | --- | --- |
| Hard refresh preserves blueprint state | Sign in as existing user, open Blueprint Tracker, confirm owned/dupe states, hard refresh browser. | Owned and duplicate states return after Auth restores. No permanent empty grid state. | Manual |
| Canonical storage path | Inspect Firestore for tested UID. | State exists at `users/{uid}/arc_blueprints/{blueprintId}`. | Manual |
| Doc ID fallback | Manually inspect a state doc that lacks `blueprintId`, if one exists. | App still keys the row by Firestore doc ID. | Manual |
| Legacy recovery preview | If legacy candidate collections exist, test with an account whose canonical collection is empty. | Legacy states merge into canonical path without deleting legacy docs. | Manual |
| New user empty state | Sign in as fresh account. | Empty/missing blueprint state stays empty without false migration or fake owned data. | Manual |

Protected areas not changed in this pass:

- Blueprint Grid rendering
- `BlueprintTile`
- ownership write logic
- duplicate write logic
- `_buildGrid`
- carousel behavior

## Communications and Notifications

| Check | Route/surface | Steps | Expected result | Result |
| --- | --- | --- | --- | --- |
| Direct inbox test | `/admin-console` -> Communications Centre Broadcast | Fill title/body, press `Inbox Test`. | UI reports a readable `trading_notifications/{id}` record. | Manual |
| Inbox visibility | Communications/notifications route | Open notification inbox for target user. | Direct inbox test appears without requiring push or Cloud Functions. | Manual |
| Broadcast test unchanged | `/admin-console` | Press `Test Send To Me`. | A `notification_broadcasts/{id}` request is queued for Cloud Function delivery. | Manual |
| Broadcast in-app rows | Firebase Functions deployed | Confirm Cloud Function creates `trading_notifications/{broadcastId}_{uid}` rows. | In-app rows appear for eligible users. | Manual |
| Android push regression | Android device | Register device, send admin test/broadcast. | Android push behavior remains unchanged. | Manual |
| Web push regression | Chrome deployed app | Register device, request FCM token, send test. | Web FCM remains registered; no service-worker regression. | Manual |

## Admin Map and Intel Editor

| Check | Route/surface | Steps | Expected result | Result |
| --- | --- | --- | --- | --- |
| Admin Console entry visible | `/admin-console` | Scroll ARC Rollout Controls. | `Map & Intel Editor` card is visible in the route-facing admin console. | Manual |
| Direct route works | `/admin-map-intel-editor` | Open route directly while signed in. | Admin Map & Intel Editor opens. | Manual |
| Map selector | Editor toolbar | Switch maps including Dam Battlegrounds and Spaceport. | Registered maps load without broken image UI where assets exist. | Manual |
| Layer selector | Editor toolbar | Switch Spaceport Surface and Level 2. | Layer changes reload editor state. | Manual |
| Reference grid toggle | Editor toolbar | Toggle `Grid`. | Grid appears/disappears without changing marker positions or panel size. | Manual |
| Aspect-preserving placement | Editor map | Create marker, tap/drag near several grid cells, save draft. | Normalized coordinates match the visible map, not the outer panel. | Manual |
| Import cache | Editor | Paste permitted JSON marker payload and import. | Markers import, duplicate/provisional/exception counts report accurately. | Manual |
| Publish selected | Editor | Publish a selected marker as admin. | Marker writes to `arc_admin_map_markers/{markerId}` with `state: published`. | Manual |
| Player map visibility | Raid Intelligence | Open same map/layer after publish. | Published marker appears with subtle reference grid overlay. | Manual |

## Raid Intelligence Public-Source Guardrails

| Check | Expected result | Result |
| --- | --- | --- |
| Public research only | Any external marker data used in future import must be permitted, internally authored, or cached as provisional/manual-review only. | Manual |
| No copied restricted data | Do not bulk-copy third-party marker coordinates without permission. | Manual |
| Official map conditions | Conditions remain sourced from official/public descriptions and existing app models. | Manual |

Useful public references reviewed during PASS 299:

- `https://arcmaps.com/maps/`
- `https://arcmaps.com/`
- `https://arcraiders.com/map-conditions`
- `https://arcraiders.wiki/wiki/Category%3AMap_Conditions`
- `https://raiderbuddy.com/maps`

## Final Go/No-Go Criteria

Go requires all of the following:

- `flutter analyze` has no issues.
- `flutter test` passes.
- Web release build passes.
- Android debug build passes.
- `node --check functions/index.js` passes.
- Firebase deploy target has current hosting/functions/rules as intended.
- Existing-user blueprint ownership survives hard refresh.
- Direct in-app notification test appears immediately.
- Cloud Function broadcast path still creates push and/or in-app delivery rows.
- Admin Map Editor is reachable from Admin Console and direct route.
- At least one published marker is visible in Raid Intelligence.

If any of the live checks fail, keep status as `NOT READY - LIVE QA BLOCKED` and open the next repair pass with concrete Firestore document IDs, browser console errors, and route/device details.
