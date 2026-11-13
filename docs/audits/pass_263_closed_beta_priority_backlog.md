# PASS 263 Closed Beta Priority Backlog

Repository: Mobcorp1/UniteAGamer
Branch: beta-stabilisation
Baseline commit: e8cf29715b9a1bedcaaf512fa003fc17ab444042

This backlog is ordered by release risk and beta value. It is intentionally scoped from the PASS 263 audit and does not introduce implementation changes.

## Recommended Next Pass

PASS 264A - Firebase rules, indexes, and deployment readiness.

Reason: the app validates locally, but Firebase rule/index correctness is the highest-risk external Closed Beta blocker. A beta can survive visual polish gaps; it cannot safely survive broken or overly broad data access.

## Ordered Pass Sequence

| Order | Proposed Pass | Scope | Priority | Size | Timing |
| ---: | --- | --- | --- | --- | --- |
| 1 | PASS 264A Firebase rules/index/security validation | Add emulator security tests, review broad trade/session/user rules, verify query/index coverage, prepare deploy checklist | P0 | large | pre-beta |
| 2 | PASS 264B Onboarding live QA repair | Authenticated mobile/web onboarding replay, consent visibility, Next/Back focus, profile completion routing, admin replay | P0 | medium | pre-beta |
| 3 | PASS 264C Quest/Scrappy/Bench proof bridges | Add beta-critical dedicated completion signals that feed Operations, rewards, and Command Centre | P0 | large | pre-beta |
| 4 | PASS 264D Session reminders and feedback prompts | Align reminders to 15 minutes, add post-session feedback prompt path, document web fallback | P1 | medium | pre-beta |
| 5 | PASS 264E Trading privacy and index cleanup | Confirm canonical listing/session collections, tighten read scope where needed, verify live query indexes | P1 | medium | pre-beta |
| 6 | PASS 264F Command Centre seeded-account tuning | Test fresh/partial/completed accounts, hide completed actions, reduce irrelevant system clutter | P1 | medium | pre-beta |
| 7 | PASS 264G Reward balance and asset gap review | Tune beta operations XP/rewards, reconcile Closed Beta/Founder rewards, list remaining art gaps | P1 | medium | beta follow-up |
| 8 | PASS 264H Public profile social/reputation polish | Add TikTok YouTube Twitch Kick links if in beta scope, unify reputation labels, QA cosmetic display | P2 | medium | beta follow-up |
| 9 | PASS 264I Android release deploy readiness | Configure release signing safely, verify debug/release build path, produce beta distribution checklist | P0 | medium | pre-beta |
| 10 | PASS 264J Feature scope gating | Decide and gate Player Locker Pro, Wall of Legends, Guardian/Sherpa, Referrals, Hunt Targets, Raid Planner | P2 | small | beta follow-up |

## P0 Release Blockers

| Item | System | Action | Acceptance Signal |
| --- | --- | --- | --- |
| Firebase emulator coverage | Firebase rules/indexes | Create focused rules tests for owner/admin/public paths and trade/session privacy | Tests pass locally and rule deploy checklist is documented |
| Index coverage | Firebase indexes | Match current repository queries to `firestore.indexes.json` | No known live query lacks an index |
| Android release signing | Android deploy | Replace debug release signing with safe release path | Release build can be produced for distribution without debug signing |
| Onboarding live flow | Onboarding | Verify first-run, consent, profile completion, Embark ID, archetypes, level gate, admin replay | No mobile overflow or hidden primary action |
| Progress proof bridges | Operations and trackers | Ensure Quest/Scrappy/Bench beta-critical milestones have reliable completion state | Command Centre and Reward Vault reflect real completion |

## P1 High-Value Improvements

| Item | System | Action | Acceptance Signal |
| --- | --- | --- | --- |
| Session timing | Notifications/calendar | Implement 15-minute pre-session reminder behaviour and post-session feedback prompt path | Reminder and feedback flows work on supported platforms |
| Trading privacy cleanup | Trading | Resolve legacy/current collection ambiguity and review broad read rules | No unintended trade/session reads in rules tests |
| Command Centre relevance | Command Centre | Seed completed users and verify completed priorities disappear | First screen answers "what should I do next?" |
| Reward balance matrix | Operations/Reward Vault | Review XP/reward cadence across beta operations | Beta user paths feel achievable without reward spam |
| Hosted web smoke | Web deploy | Test deployed build after rules/index pass | Login/home/key routes work on hosted web |

## P2 Beta Follow-Ups

| Item | System | Action | Timing |
| --- | --- | --- | --- |
| Public social links | Profile | Add or defer TikTok YouTube Twitch Kick link fields and display | beta follow-up |
| Reputation clarity | Profile/Trading | Unify Guardian Trader Intel and Community reputation labels | beta follow-up |
| Player Locker Pro MVP | Player Locker Pro | Keep gated or define minimum useful panels | beta follow-up |
| Wall of Legends MVP | Wall of Legends | Ship read-only admin-curated surface or defer | beta follow-up |
| Referrals scope | Referrals | Defer monetised referral depth unless invite attribution is required | post-beta |
| Guardian/Sherpa workflow | Guardian/Sherpa | Define matching/validation/safety model before public promise | beta follow-up |

## Manual QA Checklist For Next Release Candidate

- Fresh account signs in and lands on Command Centre.
- `/my-hub` opens Command Centre.
- Old My Hub/tool carousel is only available as a secondary Tool Deck path.
- Onboarding Next/Back focus scrolls the active card into view.
- Consent/Terms are visible and completable on small devices.
- Completed onboarding/profile items disappear from Command Centre priorities.
- Blueprint Tracker full grid remains in protected order.
- Favourite Loadout saves and reloads with real weapon and attachment images.
- Operations claim updates Reward Vault inventory.
- Equipped badge, title, frame, and banner survive reload and display on profile/trading identity surfaces.
- Trading listing/session screens load without permission or index failures.
- Session reminder timing matches beta requirement on supported platforms.
- Admin tools are inaccessible to non-admin users.
- Android debug and release distribution paths are verified.
- Hosted web build logs in and reaches main routes.

## Deferred From Closed Beta Unless Product Scope Changes

- Full referral payout/monetisation flow.
- Full Guardian/Sherpa trust and validation workflow.
- Advanced Wall of Legends eligibility, moderation, and reset logic.
- Player Locker Pro paid/pro depth.
- External push campaigns and advanced notification queues.
- Deep external calendar two-way sync.

## Go / No-Go Gate

No-Go for external Closed Beta until P0 items are complete and validated.

Go for internal seeded QA immediately after this audit because the baseline is clean and the app has enough working systems to exercise realistic beta flows.
