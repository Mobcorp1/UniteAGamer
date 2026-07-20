# PASS 264 Unified Notifications

Scope: unified UAG push notifications, in-app announcements, admin broadcast queueing, and Open Beta broadcast readiness.

## Existing Flow Before PASS 264

- `TradingPushService` initialized Firebase Messaging and local notifications only on non-web platforms.
- FCM tokens were stored as legacy documents at `users/{uid}/notification_tokens/{token}`.
- `functions/index.js` listened for `trading_notifications/{notificationId}` and sent pushes to the target user's legacy tokens.
- Invalid legacy FCM tokens were deleted from `notification_tokens`.
- `web/firebase-messaging-sw.js` was a placeholder and Chrome/web push was intentionally disabled.
- Trading notifications were displayed in `TradingNotificationsScreen` and counted by Command Centre.

## Implemented Flow

### Device Registration

Authenticated devices now register under:

```text
users/{uid}/notification_devices/{deviceId}
```

Each device record stores:

- `token`
- `userId`
- `platform`
- `enabled`
- `createdAt`
- `updatedAt`
- `lastSeenAt`
- `appVersion`
- `installationId`
- `preferences`
- `permissionStatus`
- `tokenValid`

The app also continues writing the legacy token document:

```text
users/{uid}/notification_tokens/{token}
```

That compatibility write keeps the existing trading notification trigger safe while the server moves to the new registry.

### Preferences

User notification preferences are stored at:

```text
users/{uid}/notification_preferences/current
```

Supported categories:

- announcements
- openBetaUpdates
- trading
- matchmaking
- favouriteRiders
- watchesAndQueues
- operationsAndRewards
- communityEvents
- reminders
- postSessionFeedback

Settings now exposes device status, permission state, category toggles, an Enable Notifications action, and a safe local test action where supported.

### Runtime Permissions

Android:

- Uses the existing `POST_NOTIFICATIONS` manifest permission.
- Requests Firebase Messaging notification permission during push initialization.
- Preserves the `trading_alerts` Android channel, now labelled as UAG Alerts.
- Handles foreground messages with local notifications.
- Handles background and terminated-app notification taps through existing FCM callbacks.

Web:

- Push is initialized without prompting automatically.
- Browser permission is requested only through the explicit Enable Notifications action.
- Web token generation requires a public VAPID key passed at build/run time:

```text
--dart-define=UAG_WEB_PUSH_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
```

### In-App Notifications

Broadcasts create in-app records in the existing notification stream:

```text
trading_notifications/{notificationId}
```

The model now understands announcement, Open Beta, operations, reward, community event, reminder, post-session feedback, and maintenance notification types.

### Admin Broadcasts

Admin Console now contains an Open Beta Broadcast panel with:

- editable Open Beta preset
- title/body/type/audience/priority/expiry fields
- optional image URL
- optional route/deep link
- push toggle
- in-app toggle
- preview
- audience estimate
- test-send to the current admin user
- confirmation before queueing a full broadcast

The Flutter client never sends FCM directly. It creates a queued broadcast request at:

```text
notification_broadcasts/{broadcastId}
```

Cloud Functions validates admin status server-side before sending.

### Cloud Functions

Functions added or changed:

- `sendTradingNotificationPush`
  - still triggers from `trading_notifications`
  - now reads `notification_devices` and legacy `notification_tokens`
  - respects device enabled state, permission state and preferences where available
  - disables invalid new device tokens and deletes invalid legacy token docs

- `sendUagNotificationBroadcast`
  - triggers from `notification_broadcasts/{broadcastId}`
  - validates sender admin/dev status from Firestore
  - claims only broadcasts with `status == queued`
  - marks `sending`, then `sent`, `partial_failed`, `failed`, or `rejected`
  - filters devices by platform, audience, permission status, enabled state, token validity and preferences
  - deduplicates tokens
  - sends push batches through Firebase Admin SDK
  - creates in-app notification records when requested
  - records delivery totals at `notification_delivery_reports/{broadcastId}`
  - disables or deletes invalid tokens safely

### Scheduling Foundations

The trade reminder foundation now persists schedule documents at:

```text
uag_notification_schedules/{scheduleId}
```

Created schedule examples:

- 15 minutes before a scheduled trade
- 15 minutes after the expected session end for feedback

These are data foundations only. A reliable server scheduler still needs Firebase scheduled functions or Cloud Tasks before the schedule queue can deliver notifications without the app being open.

## Firestore Collections Added Or Changed

- `users/{uid}/notification_devices/{deviceId}`
- `users/{uid}/notification_preferences/current`
- `notification_broadcasts/{broadcastId}`
- `notification_delivery_reports/{broadcastId}`
- `uag_notification_schedules/{scheduleId}`
- `trading_notifications/{notificationId}` extended for announcement/broadcast metadata
- `users/{uid}/notification_tokens/{token}` preserved for compatibility

## Security Notes

- Users can manage only their own device registrations and preferences.
- Users cannot grant themselves admin rights.
- Broadcast creation is admin/dev only by Firestore rules.
- Broadcast status and delivery reports cannot be forged by clients.
- Cloud Functions re-checks admin/dev status server-side.
- Server-owned delivery status is written by Admin SDK only.

## Remaining Manual Configuration

Chrome/web push requires the Firebase Web Push certificate public key:

```text
--dart-define=UAG_WEB_PUSH_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
```

Do not invent this key. Generate or copy it from Firebase Console:

```text
Firebase Console > Project settings > Cloud Messaging > Web Push certificates
```

Reliable scheduled delivery for trade reminders and post-session feedback still needs one of:

- Firebase scheduled function polling `uag_notification_schedules`, or
- Cloud Tasks queueing per schedule item.

This pass does not enable paid/billing-dependent scheduling automatically.
