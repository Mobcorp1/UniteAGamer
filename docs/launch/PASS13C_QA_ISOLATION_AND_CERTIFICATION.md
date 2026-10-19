# PASS 13C — QA-isolated Smart Matching and Push Delivery

Baseline: `25d421d0d6248428bda146a1b4f93a25c6f7beed` (`codex/raid-setup-endpoints-20261005`).

## Guarantee and scope

- PASS 13A and 13B search, listings, Blueprint Watches, profile, invites, commercial entitlement checks, server notifications and screen navigation remain in the repository.
- PASS 13C **cannot** activate public automatic matching. Even an erroneous `enabled: true` flag is not enough: both accounts must be in a valid two-to-ten-user tester allowlist, `qaMode` must equal `testers`, the QA window must be unexpired and no greater than seven days, and `publicEnabled` must not equal true.
- All three discovery trigger functions start disabled unless a server-owned QA control explicitly activates testers. An automatic notification is checked again at push-dispatch time to ensure the watch/listing or squad profiles remain current, opted in, age-verified and unblocked.
- Existing manual match searches, trade offers and booking flows are preserved. This release DOES NOT implement public three-player booking, two-way proof of trade compatibility, or support for newly unverified items/quests.
- No tool may claim Android/Chrome push delivery is certified until live QA evidence is collected.

## Installation and optional deployment

The guarded `Install-UAG-PASS13C.ps1` in the ZIP applies and tests changes to the user worktree and optionally commits locally. It does not deploy or push by default.

`Stage-UAG-PASS13C-Firebase.ps1` (in the ZIP root) is a separate **explicit** operator action. It first deploys local `firestore.rules`, then ONLY the following Cloud Functions:

- `uagPass13WatchTradeListings`
- `uagPass13WatchBlueprintWatches`
- `uagPass13WatchMatchRider`
- `sendTradingNotificationPush`

Firebase CLI `--only` selection is used; no other existing 42 functions should be redeployed. Runtime project and branch are checked. Before staging, compare Firebase Console rules with the checked-in file for any console-only edits; Firebase CLI overwrites server rules.

Optional `-DeployHosting` rebuilds with the VAPID key and deploys Hosting **only if explicitly requested**. Otherwise production Hosting stays unchanged.

## Tester-only control

A control in `uag_release_controls/launch_matching` is server-owned and only writable through Admin SDK credentials with suitable permissions. Current Firestore rules prohibit client writes. Use `functions/tools/pass13c_qa_control.js` with Google Application Default Credentials for the `unite-a-gamer` project:

```
node functions/tools/pass13c_qa_control.js audit --project unite-a-gamer
node functions/tools/pass13c_qa_control.js enable --project unite-a-gamer --testers UID_A,UID_B --hours 24 --confirm QA_TESTERS_ONLY
node functions/tools/pass13c_qa_control.js disable --project unite-a-gamer --confirm STOP_QA
```

**Do not put a service account credential into the repository or send it in chat.** With no ADC configured, these commands fail rather than bypass auth. Obtain a permitted admin access path (e.g. `gcloud auth application-default login` with a suitably authorised operator account), or configure the release document through the Firebase Console only after staging. Never use `public` QA mode or remove the tester restriction in this pass.

QA control stores:

```
enabled = true
qaMode = "testers"
publicEnabled = false
tradeAlertsEnabled = true
squadAlertsEnabled = true
testerUids = ["UID_A", "UID_B"]
qaExpiresAt = <Firestore timestamp, within 1–48 hours>
```

The QA control expires automatically; disabling is immediate for *new* alert generation and push dispatch. Previously queued in-app notifications are historical records, and may remain visible in testers' inboxes.

## Acceptance script: real-device QA (not automatable off-device)

1. Check the Firebase inventory for the three `uagPass13Watch*` functions and existing `sendTradingNotificationPush` after explicit staging.
2. Register **two over-18 verified QA accounts** A and B; check active FCM tokens and current notification preferences, with trading/watch/matchmaking enabled by explicit action. Allow notifications in **Chrome on HTTPS** and **Android**; verify browser service-worker scope, web public VAPID key and app login.
3. Trade: A creates an *immediate* Blueprint Watch for a known blueprint. B creates a real, active, explicitly offered listing containing that item. Verify A receives an in-app `watch_match` and Chrome/Android push (not merely that a Firebase document exists). Open it and verify the actual live listing, then inspect the terms; no automatic trade acceptance.
4. Squad: both set compatible platform/region/activity preferences, `autoMatchAlertsEnabled`, `lookingNow`, `visibleInSearch`, and refresh their profiles within six hours. Verify the `matchmaking` candidate notifications reach both, and a tap reaches Match Raider, from foreground and background/cold start.
5. Negative: revoke A's push preference; leave a watch muted; expire a listing; block B; disable B's Auth account; use an unmatched platform or event; repeat writes in one dedup window; try an unlisted third user; and expire/disable the QA gate. No new push should be delivered for these cases.
6. Confirm no modification of Blueprint grid/order/ownership, Favourite Loadout logic, public profiles, purchase entitlements, manual listings search or manual matchmaking search. Test a legacy manual trade invitation.
7. Restore the release gate to disabled at the end and retain logs/screenshots in Downloads (omit private tokens and identifying account data). Recheck Firebase inventory and hosting behaviour.

**Passing automated local gates does not replace this live device evidence.** No automatic public activation is included. Only after this acceptance can a separate controlled public rollout be considered.

## Known limits

- Web `build/web` must be deployed to Hosting for the live domain to use the VAPID-enabled build; a local build alone does not update production.
- Android push requires FCM registration/permissions, a reachable device and matching account setup.
- This pass uses **one-way Blueprint Watch ↔ active explicit listing discovery**, not a verified reciprocal exchange of tradable blueprints. Keep notification language as *potential trade* and require both users to agree terms.
- A Firestore Cloud Functions event is not fired for an unchanged document. Refresh an existing profile/listing/watch with an actual field change during QA. Do not insert fabricated inventory data into production accounts.
- The 3,000-document candidate scan cap remains; exceeding it is an explicit failure rather than an inaccurate incomplete match.
- Server-side QA stage can incur ordinary Firebase deployment, Firestore-read and notification costs. Avoid triggering on a high-volume production dataset unnecessarily.
