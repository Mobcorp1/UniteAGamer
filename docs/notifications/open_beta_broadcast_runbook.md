# Open Beta Broadcast Runbook

Use this runbook when Mike is ready to send the Open Beta announcement.

Do not send the broadcast automatically during deploy. The final send must be triggered manually from Admin Console after testing.

## 1. Deploy Firestore Rules And Indexes

```text
firebase deploy --only firestore:rules,firestore:indexes
```

Confirm the deploy succeeds and no index creation is stuck in an error state.

## 2. Deploy Functions

```text
firebase deploy --only functions
```

Confirm these functions are live:

- `sendTradingNotificationPush`
- `sendUagNotificationBroadcast`

## 3. Build And Deploy Web

Build web with the Firebase Web Push VAPID public key:

```text
flutter build web --release --no-wasm-dry-run --dart-define=UAG_WEB_PUSH_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
```

Deploy hosting:

```text
firebase deploy --only hosting
```

## 4. Install/Test Android Build If Required

Build and install the debug or release candidate Android app.

Confirm Android notification permission can be granted and the device appears in:

```text
users/{uid}/notification_devices/{deviceId}
```

## 5. Enable Browser Notifications

In Chrome:

1. Open the deployed UAG ARC Raiders Hub.
2. Sign in.
3. Open Settings.
4. Use Enable Notifications.
5. Confirm the browser permission prompt.
6. Confirm the web device appears under the signed-in user document.

## 6. Send An Admin Test Notification

1. Sign in with an admin/dev account.
2. Open Admin Console.
3. Go to Open Beta Broadcast.
4. Press Preset.
5. Review title, body and route.
6. Press Test Send To Me.
7. Wait for the Cloud Function to process the queued request.
8. Review `notification_delivery_reports/{broadcastId}`.

## 7. Confirm Android Delivery

On the admin's Android device:

1. Confirm push notification arrives.
2. Tap it.
3. Confirm the app opens to Command Centre or the configured route.
4. Confirm the in-app notification appears in Notifications.

## 8. Confirm Chrome Delivery

In Chrome:

1. Keep one UAG tab open.
2. Send another admin test notification.
3. Confirm the notification displays.
4. Tap it.
5. Confirm the existing UAG tab focuses where possible.
6. Close all UAG tabs and test again.
7. Confirm Chrome opens the app route.

## 9. Create The Open Beta Broadcast

In Admin Console:

1. Press Preset.
2. Edit final wording if needed.
3. Keep type as `open_beta`.
4. Use audience `all_eligible` unless Mike wants a narrower send.
5. Keep push enabled.
6. Keep in-app record enabled.
7. Set expiry, usually 72 hours.
8. Press Estimate Audience.

## 10. Preview

Read the preview carefully:

- Title
- Body
- Route/deep link
- Audience
- Delivery channels
- Estimated eligible users/devices

## 11. Send

1. Press Queue Broadcast.
2. Confirm the dialog.
3. Do not refresh repeatedly.
4. Wait for Cloud Function delivery.

## 12. Review Delivery Totals And Failures

Open:

```text
notification_delivery_reports/{broadcastId}
notification_broadcasts/{broadcastId}
```

Review:

- attempted
- successful
- failed
- invalidTokens
- skippedByPreference
- inAppCreated
- eligibleUsers
- eligibleDevices
- status

If status is `partial_failed`, review failures before sending a follow-up.

## Final Safety Checks

- Admin test-send succeeded on Android.
- Admin test-send succeeded on Chrome.
- Rules and functions are deployed.
- Web was built with the VAPID public key.
- No real broadcast has been sent from local development.
- Final broadcast wording has been reviewed by Mike.

If all checks pass, Mike can safely queue the Open Beta notification from Admin Console.
