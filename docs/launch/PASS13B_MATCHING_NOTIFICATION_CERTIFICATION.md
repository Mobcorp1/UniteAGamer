# PASS 13B — Matching and Notification Integration Certification

Release-base requirement: `70318f74dd3f1e8c64388dd06833e3806d840f19` on `codex/raid-setup-endpoints-20261005`.

## Scope completed by this pass

- Correct server listing trigger to `trading_listings`, the authoritative collection used by `TradingRepository`. PASS 13A mistakenly subscribed to `arc_trade_listings`, which is not the existing market.
- Keep the existing marketplace screens, searches, offers and booking flows. `UAG_SHOW_MANUAL_SEARCH=true` still re-enables the original browsing interfaces at build time.
- Make match checking use documented server-owned candidate logic and explicit match-notification opt-in; no auto-accept, invented score or private blueprint exposure.
- Require mutual squad opt-in, 'Looking now' plus a fresh profile edit within six hours, compatible platforms/regions/servers, activity overlap, verified adults, active Auth accounts and bilateral block checks.
- Reject expired, paused and self-owned watch/listing matches. Non-immediate watch preferences only receive in-app candidates; `digest`, `favouriteRidersOnly` are not incorrectly sent as immediate messages.
- Deduplicate by watch+listing, and squad pair+six-hour window, with deterministic IDs and create-only writes.
- Respect account-level notification preferences at both match creation and moment of push dispatch. Do not reinstate disabled legacy tokens when any modern device records exist.
- Fix FCM web link to a same-origin absolute HTTPS URL and route in-app Watch taps to the actual still-live listing where possible.
- Add `uag_release_controls/launch_matching` as a server-only control, **default OFF** until explicit rollout.
- Keep original automated PASS 13A match tests; add integration and source-wiring tests.

## Activation switch (no automatic production activation)

The release switch document is read using the Cloud Functions Admin SDK and defaults to disabled when absent:

```
uag_release_controls/launch_matching
  enabled: false
  tradeAlertsEnabled: false
  squadAlertsEnabled: false
```

This installer does not set these fields. Admins must use Firebase Console under controlled rollout and explicitly enable one category only after representative Android + Chrome tests. Do not enable while QA accounts have unconsented profiles. Firestore rules deny all client writes.

## Production dependencies & acceptance requirements

1. Ensure Firebase has Blaze/Cloud Functions V2/Eventarc/Cloud Scheduler eligibility as needed. Deploy only the specifically audited changed Functions after emulator checks, not the whole project by reflex.
2. Confirm the index and Firestore rules are deployed and data writes obey actual authorization. Query pagination reads each candidate collection ordered by document ID; it has a protective hard limit of 3,000 documents per invocation and will fail rather than silently ignoring matches above the cap. Design a query/index-based strategy before reaching this scale.
3. Chrome web push: build with `--dart-define=UAG_WEB_PUSH_VAPID_KEY=<real public Firebase VAPID key>`, then verify service worker scope, user permission, `notification_devices` record and real push when the tab is closed.
4. Android: notification permissions granted, token registered, background and terminated-app push tested on two **separate** adult test accounts.
5. Consent checks: disabled channel, disabled device, muted Blueprint Watch, blocked Raider in both directions, unverified account, disabled Auth account, stale squad profile, crossplay mismatch and expired listings must send **no push**.
6. Check the notification count is exactly once for a listing+watch combination, and at most once per six-hour pair window for squad candidate alerts. Changes to a second listing create a separate opportunity.
7. User tap: live watched blueprint opens its actual listing; expired listing falls back to Watches. Squad alert opens Match Raider with invitations, manual search kept behind build flag.
8. Check 6-hour expiry and prompt users to save/refresh 'Looking now' so it is not a permanent availability claim.
9. Run an independent Firestore emulator and Cloud Functions event test on the real schema to certify authoritative security and triggers. Pure Node tests and Flutter builds do not prove live Firebase event delivery.
10. Sign off QA logs and choose a narrowly controlled deployment; no live pushes should be sent before completing the checklist.

## Deliberately out of scope / not launch complete yet

- **Public RSVP squad-slot links** ('Frigate tonight: reserve a place') require a separate transactional invite-gateway and lifecycle design; existing Session Planner can already schedule two-party sessions and export calendars. This pass does not claim public three-person slots are implemented.
- Confirming all new ARC Raiders quests, assets, layouts and map pins remains dependent on verified content and artwork.
- Existing private-profile matching percentages are intentionally not recomputed by this backend; these are *potential* compatible candidates, not guaranteed high matches.
- This pass does not integrate subscription billing or alter current entitlements.
- No GitHub push, Firebase changes, Cloud Functions activation, or production SEO update performed by installer.
