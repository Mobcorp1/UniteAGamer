# Web Push Setup

Chrome/web push is implemented, but it requires Firebase's public Web Push VAPID key at build or run time.

## Required Firebase Console Value

Get the public key from:

```text
Firebase Console > Project settings > Cloud Messaging > Web Push certificates
```

If no key exists, generate a Web Push certificate pair in Firebase Console.

## Flutter Build Value

Pass the public key as:

```text
--dart-define=UAG_WEB_PUSH_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
```

Examples:

```text
flutter run -d chrome --dart-define=UAG_WEB_PUSH_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
```

```text
flutter build web --release --no-wasm-dry-run --dart-define=UAG_WEB_PUSH_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
```

Do not commit private keys or Firebase service account credentials into the repository.

## Service Worker

The web push service worker lives at:

```text
web/firebase-messaging-sw.js
```

It:

- initializes the existing `unite-a-gamer` Firebase web app
- receives background Firebase Messaging payloads
- shows title, body, icon and optional image
- preserves notification data for routing
- focuses an existing UAG tab when possible
- otherwise opens the app route or root

## Expected Browser Flow

1. User signs in.
2. User opens Settings.
3. User presses Enable Notifications.
4. Browser permission prompt appears.
5. If granted, the app registers an FCM web token.
6. The token is stored at `users/{uid}/notification_devices/{deviceId}`.

The app intentionally does not trigger the Chrome permission prompt on first page load.

## Troubleshooting

If Settings shows `Web Push Key: Missing`, rebuild with:

```text
--dart-define=UAG_WEB_PUSH_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
```

If Chrome permission is denied:

1. Open Chrome site settings for the deployed UAG URL.
2. Reset Notifications permission.
3. Reload the app.
4. Use Enable Notifications again.

If no device record appears:

1. Confirm the user is signed in.
2. Confirm browser permission is granted.
3. Confirm the VAPID key was supplied.
4. Confirm `web/firebase-messaging-sw.js` is reachable at the deployed root.
5. Check browser dev tools for service-worker or Firebase Messaging errors.
