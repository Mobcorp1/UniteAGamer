# PASS 13A — Early-community, opt-in matching foundation

Baseline Git branch: `codex/raid-setup-endpoints-20261005`, published commit `7346217fdd84fb6e030c6b1c10e2877595a07609`.

## Deliberate preservation

- **No source code is deleted.** Legacy TradingListingsScreen and Match Raider live candidate feed still compile; set `--dart-define=UAG_SHOW_MANUAL_SEARCH=true` at Flutter build time to show them again. Default release UI opens Blueprint Watches rather than the marketplace and shows Squad Match Watch rather than an empty rider feed. Routes, offers, invite and repository contracts remain.
- The Blueprint Grid, `_buildGrid`, `BlueprintTile`, ownership/duplicate/acquisition tracking, and Favourite Loadout are unchanged.
- Current secure personal Raider link remains. Shared images show spares only. Needed blueprints remain internally available for creating the approved trading listings.
- Quest Tracker adds a multiselect batch-complete dialog and `Track visible results` (up to 25) without changing quest progression storage or prerequisite truth. User must confirm selections.
- ARC Frigate and Redirection become selectable event preferences; Pendola Pass is added to matchmaking map choices. These are interests, **not** claims of live schedule or event rewards.

## Push behavior (server module staged but NOT deployed)

- New Functions are opt-in and additive: watch relevant trade listings, watch Blueprint Watch changes and discover mutually opted-in Match Raider profiles. Existing `trading_notifications` trigger remains responsible for FCM delivery.
- No trade/squad transaction is automatically accepted. Notification deep-links lead to review screens. Exact-match watch logic requires an active unexpired published listing, an active watch and distinct accounts. Group safety checks read age verification and `uag_user_blocks` in both directions.
- Squad alerts require both Raiders to set `Looking now`, `Notify me about suitable squadmates`, visible profile, nonblocked pairing, region/server/platform compatibility and overlapping maps/events/playstyle. They are **candidate alerts**, not the existing client match-percentage score.
- Per-pair and per-watch deterministic notification IDs deduplicate alerts; no repeated pushes on repeated profile changes. Categories respect user settings and registered device preferences.
- Immediate Watch push occurs only for explicit `immediate` preference. `nextLogin` and availability-only Watch notifications create in-app records but **do not** issue immediate push, because robust timezone scheduling is not implemented. Digest/favourite-only are excluded rather than misdelivered.
- **Beta limits:** scans at most 400 watches / 300 listings / 250 riders per write, with no pagination. This is for initial small populations, not a scalable matchmaking service. Notification volume & Firestore billing require monitoring. Account identity and block changes after a notification must still be rechecked on opening the target.
- Web push needs VAPID public key and verified active Functions; building Hosting by itself does NOT activate Functions. Do not auto-deploy these triggers without emulator/integration tests and operator approval. No production Firebase writes or permissions are made by the installer.

## OUT OF SCOPE, not falsely certified complete

- New Frozen Trail quest names/objectives/prerequisites/rewards, item art and complete map pins require authoritative in-game/source verification; no invented quests or assets are shipped.
- The two-person Session Planner/calendar export is preserved but *public shareable event squad slot with secure RSVP* is a follow-on backend/API and rules change, not implemented by this pass. Do not claim otherwise.
- User-facing trading and matchmaking notification badges could be refined after end-to-end device testing; this pass only reuses existing channels and deep links.
- The existing `arc_match_rider_profiles` collection stores public profile fields; age, blocks, trade inventory and private signals must not leak in public alert bodies.

## Validation / publication

Installer checks exact certified Git blobs and a clean scoped worktree, preserves pre-existing Hosting cache and robots line-ending residue, backs up all touched files, runs Node tests, Flutter targeted tests, static analysis, full suite and Android/web builds. It stages only exact PASS13 files, commits locally only with `-Commit`. **Never pushes/deploys**. Firebase Functions deploy and production validation require a separate approved rollout.
