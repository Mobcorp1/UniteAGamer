# PASS 263 Closed Beta Readiness Audit

Repository: Mobcorp1/UniteAGamer
Branch: beta-stabilisation
Baseline commit: e8cf29715b9a1bedcaaf512fa003fc17ab444042

Scope: repository-wide audit and prioritisation only. No implementation files were changed for this pass.

## Executive Summary

Estimated Closed Beta readiness: 72%.

Recommendation: conditional No-Go for an external Closed Beta until the top release/security blockers are repaired. Go for internal seeded QA and stakeholder walkthroughs because the app compiles, tests pass at baseline, the global layout migration is in place, and the core player surfaces are reachable.

The project is now past the "foundation only" stage. Command Centre, Blueprint Tracker, Favourite Loadout, Operations, Reward Vault, profile cosmetics, trading intelligence, quest/bench/resource intelligence, and route layout migration all have meaningful working implementations. The remaining risk is concentrated in release readiness, Firebase rule/index validation, live account state verification, reminders/feedback automation, and a few beta-scope decisions around social/profile, Player Locker Pro, Wall of Legends, referrals, and Guardian/Sherpa flows.

Classification snapshot:

| Classification | Count | Notes |
| --- | ---: | --- |
| Closed Beta ready | 6 | Stable or low-risk surfaces that can ship after final QA. |
| Usable but needs polish | 19 | Functional enough for beta, but needs seeded-account QA, copy, tuning, or small repairs. |
| Foundational / incomplete | 6 | Present in code or data, but not enough for a polished beta promise. |
| Blocked | 1 | Firebase rules/index deployment validation is a release blocker. |
| Post-beta | 0 | Some foundational systems should be scoped as beta follow-ups or post-beta features. |

Readiness model: weighted assessment across reachability, persistence, rule safety, runtime stability, responsive layout, beta user value, and operational/deployment risk. This is an audit estimate, not a product metric.

## Audit Method

Reviewed the live repository at the stated baseline, including:

- Route map and post-login home routing in `lib/main.dart`.
- PASS 262B/262C layout manifest and QA checklist.
- Command Centre, decision, trade, quest, bench, resource, nomadic trader, operations, and reward-vault documentation and source structure.
- Onboarding/profile completion audit and closed-beta wiring audit from previous passes.
- Firebase rules and indexes.
- Android Gradle release/deploy configuration.
- Web entrypoint and build-readiness files.
- Notifications/session reminder service and calendar integration surfaces.
- Favourite Loadout, weapon/attachment asset registry, and compatibility database.

No protected systems were modified. Blueprint Grid ordering, `BlueprintTile`, ownership writes, duplicate writes, `_buildGrid`, carousel behaviour, and auth flow were only considered from an audit perspective.

## Top 10 Blockers

| Rank | Blocker | Why It Matters | Recommended Action | Size |
| ---: | --- | --- | --- | --- |
| 1 | Firebase rules/index validation and deploy readiness are not proven by emulator tests | A beta with unverified security rules can leak or block live user data | Add rules/index audit tests, verify query coverage, deploy safely | large |
| 2 | Android release signing still needs production-safe configuration | Debug signing is not acceptable for external distribution | Configure release signing and final Android deploy checklist | medium |
| 3 | Live onboarding walkthrough still needs device QA | Earlier passes repaired focus/scroll issues, but beta entry must be flawless | Run authenticated onboarding on Android portrait, landscape, tablet, and web | medium |
| 4 | Quest, Scrappy, and Bench progression proof remains partially manual/grouped | Operations and Command Centre need reliable completion signals | Add dedicated progression proof fields or bridge events where safe | large |
| 5 | Session reminders do not match the 15-minute beta requirement | Existing local reminder logic is 30 minutes and web push is limited | Implement 15-minute reminders and post-session feedback prompt design | medium |
| 6 | Trading privacy and collection/index drift need review | Multiple legacy and current trade collections exist, and one session rule is broad | Tighten session read rules and confirm all active queries have indexes | medium |
| 7 | Social profile links are not fully wired for public identity | TikTok, YouTube, Twitch, and Kick are beta-visible user expectations | Add explicit persisted fields and profile display/edit flow | medium |
| 8 | Player Locker Pro needs a minimum beta scope decision | The route is feature-gated, but the complete product promise is larger than beta | Define MVP panels or keep it hidden for Closed Beta | small |
| 9 | Wall of Legends is not a clear beta-ready product surface | Rules/data exist, but the route and MVP behaviour are not clearly established | Ship read-only MVP or defer from beta navigation | small |
| 10 | Reward and XP balance needs seeded-account review | Operations and Reward Vault work, but beta economy balance is product-sensitive | Run seeded user paths and tune reward cadence | medium |

## Top 10 High-Value Improvements

| Rank | Improvement | Benefit | Timing | Size |
| ---: | --- | --- | --- | --- |
| 1 | Firebase emulator security test suite | Converts a major release risk into repeatable validation | pre-beta | large |
| 2 | Command Centre seeded-account tuning | Ensures the first screen shows only current, useful next actions | pre-beta | medium |
| 3 | Onboarding live QA and admin replay checklist | Protects first-run conversion and reduces support pain | pre-beta | medium |
| 4 | Dedicated Quest/Scrappy/Bench progress events | Makes Operations and rewards feel earned and reliable | pre-beta | large |
| 5 | 15-minute reminder and feedback prompt wiring | Supports session trust, accountability, and retention | pre-beta | medium |
| 6 | Trading privacy/index cleanup | Reduces risk in the most user-data-sensitive area | pre-beta | medium |
| 7 | Public profile social-link model | Makes profiles feel complete for streamers and creators | beta follow-up | medium |
| 8 | Reward balance matrix and asset gap sweep | Prevents over/under-rewarding beta users | beta follow-up | medium |
| 9 | Player Locker Pro MVP scope | Keeps the beta promise focused and understandable | beta follow-up | small |
| 10 | Wall of Legends read-only MVP | Adds community motivation without a large feature build | beta follow-up | small |

## Systems Safe To Defer

- Referrals payout and monetisation depth.
- Wall of Legends expansion beyond a simple read-only beta surface.
- Guardian/Sherpa matching beyond reputation and operations hooks.
- Full Player Locker Pro monetised feature set.
- External calendar automation beyond existing export/share support.
- Advanced notification queues, push campaigns, and web push.
- Post-beta public social graph expansion.

## Ordered Implementation Roadmap

1. PASS 264A - Firebase rules, indexes, and deployment readiness.
2. PASS 264B - Onboarding live QA repair and admin replay hardening.
3. PASS 264C - Quest, Scrappy, and Bench progression proof bridges.
4. PASS 264D - Session reminders, feedback prompts, and notification readiness.
5. PASS 264E - Trading privacy/index cleanup and live trade QA.
6. PASS 264F - Command Centre seeded-account tuning and completion visibility.
7. PASS 264G - Reward Vault and Operations balance review.
8. PASS 264H - Public profile social links and reputation polish.
9. PASS 264I - Android release signing and final deploy checklist.
10. PASS 264J - Beta scope gating for Player Locker Pro, Wall of Legends, Guardian/Sherpa, and Referrals.

Recommended next pass: PASS 264A Firebase rules, indexes, and deployment readiness. This has the highest release-risk reduction and should happen before more feature polish.

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Firestore rules allow too much or block valid beta queries | medium | high | Add emulator tests and review broad recursive/user and trade-session rules. |
| Required Firestore indexes drift from live queries | medium | high | Run query audit against current repositories and deploy index file. |
| Android external build cannot be released safely | medium | high | Replace debug signing for release and verify Play/App Distribution path. |
| Onboarding fails on small mobile devices | medium | high | Run live device QA for focus, scrolling, consent, and profile completion. |
| Command Centre shows stale/completed actions | medium | medium | Seed users with completed milestones and verify priorities disappear. |
| Operations reward economy feels unbalanced | medium | medium | Create a beta reward matrix and test fast/slow user paths. |
| Session reminders do not arrive at expected beta timing | high | medium | Adjust local reminder timing and design web/push fallback messaging. |
| Trading privacy semantics are unclear across legacy collections | medium | high | Consolidate active collection usage and tighten session read scope. |
| Public profile lacks creator links or consistent cosmetics | medium | medium | Add explicit social-link fields and profile presentation QA. |
| Feature-gated foundation screens create expectation debt | medium | medium | Gate or label Player Locker Pro, Wall of Legends, Referrals, and Guardian/Sherpa scope. |

## Manual QA Requirements

- Authenticated smoke test from login to Command Centre and `/my-hub`.
- Onboarding replay on Android portrait, Android landscape, tablet, desktop, and web.
- Consent/Terms visibility and progression on small height devices.
- Command Centre compact hierarchy with fresh, partial, and completed seeded accounts.
- Blueprint Tracker full-grid and in-game framed view without altering protected order.
- Favourite Loadout image fit, six quick-use slots, shield, augment, and attachment compatibility.
- Scrappy/Bench/Quest tracker carousel density and completion visibility.
- Operations claim/reward/equip loop for Closed Beta, Founder, and earned operations.
- Reward Vault preview/equip/persistence across badge, title, profile frame, and profile banner.
- Trading Listings, Smart Trade, Trading Sessions, Match Rider, Raid Planner, and Hunt Targets on mobile/web.
- Calendar export/share and local reminder behaviour.
- Public profile and reputation surfaces with equipped cosmetics.
- Admin preview tools and route guards.
- Android debug/release deploy path and web deploy path.

## Go / No-Go

Current recommendation: No-Go for external Closed Beta until P0/P1 blockers are repaired and verified. Go for internal seeded QA because the codebase is clean at baseline, all tests pass, routing is stable, and most primary user journeys are available enough to exercise.

## Detailed System Audit

### Command Centre

- Classification: Usable but needs polish.
- Current status: Compact home is routed as post-login and `/my-hub`, with Decision Engine-backed mission, objectives, alerts, recommendations, trade summary, system summaries, and Tool Deck.
- Main files: `lib/main.dart`; `lib/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart`; `lib/features/trading_hub/arc_raiders/data/arc_command_centre_engine.dart`; command-centre widgets under `lib/features/trading_hub/arc_raiders/widgets/command_centre/`.
- What works: Home routing, compact hierarchy, top-three caps, optional detail panels, Tool Deck access, live data adapters.
- Incomplete: Needs seeded-account QA to prove completed actions disappear across every source system.
- UX issues: Card density should be checked on small devices and authenticated web sessions.
- Technical debt: Many signals are fed by separate repositories; completion semantics still depend on each source being accurate.
- Blocks Closed Beta: No, provided seeded-account QA passes.
- Recommended next action: Add Command Centre seed-state QA after Firebase/rules hardening.
- Estimated pass size: medium.
- Timing: pre-beta.

### My Hub

- Classification: Closed Beta ready.
- Current status: `/my-hub` opens Command Centre, while legacy My Hub/carousel remains available through Tool Deck behaviour.
- Main files: `lib/main.dart`; `lib/features/trading_hub/arc_raiders/screens/my_hub_screen.dart`; Command Centre screen/widgets.
- What works: Main home no longer surfaces old My Hub as the primary route.
- Incomplete: Confirm all drawer, tracking, and deep-link entries use the intended route.
- UX issues: Tool Deck should remain useful but visually secondary.
- Technical debt: Legacy naming can confuse future maintainers because `MyHubScreen.routeName` maps to Command Centre.
- Blocks Closed Beta: No.
- Recommended next action: Keep route naming note in release QA.
- Estimated pass size: small.
- Timing: pre-beta.

### Blueprint Tracker

- Classification: Closed Beta ready.
- Current status: Stable tracker with protected grid logic, ownership/duplicate state, asset mapping, in-game framed view, and jump controls.
- Main files: `lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart`; `lib/features/trading_hub/arc_raiders/widgets/blueprint_tile.dart`; blueprint catalog/data files.
- What works: Full-grid view, ownership display, duplicate display, canonical assets, protected grid order.
- Incomplete: Optional beta polish around framed in-game presentation only.
- UX issues: Needs final manual check for mobile portrait/landscape and desktop jump controls.
- Technical debt: Protected areas constrain future refactors, which is intentional.
- Blocks Closed Beta: No.
- Recommended next action: Manual QA only; do not alter protected logic.
- Estimated pass size: small.
- Timing: beta follow-up.

### Scrappy / Bench / Quest Trackers

- Classification: Usable but needs polish.
- Current status: Shared tracker screens and intelligence feed Command Centre and Operations, with manual/grouped completion support.
- Main files: `lib/features/trading_hub/arc_raiders/screens/scrappy_and_quests_screen.dart`; quest, bench, and resource intelligence files under `lib/features/trading_hub/arc_raiders/data/`.
- What works: Trackers are reachable, responsive layout has been migrated, and intelligence can surface blockers and resource needs.
- Incomplete: Dedicated quest-chain state, prerequisite enforcement, Scrappy upgrade-level state, and bench upgrade proof docs remain incomplete.
- UX issues: Carousel/card density should be checked on mobile.
- Technical debt: Manual tracker completion can blur distinction between true game progression and user checklist state.
- Blocks Closed Beta: Partially, if Operations rewards depend on these milestones.
- Recommended next action: Add dedicated proof bridges for beta-critical milestones.
- Estimated pass size: large.
- Timing: pre-beta.

### Favourite Loadout

- Classification: Closed Beta ready.
- Current status: Saved favourite loadout, canonical weapon/attachment database, compatibility registry, image mapping, and six quick-use slots are in place.
- Main files: `lib/features/trading_hub/arc_raiders/screens/favourite_loadout_screen.dart`; `lib/features/trading_hub/arc_raiders/data/arc_loadout_seed_data.dart`; `lib/features/trading_hub/arc_raiders/data/arc_weapon_attachment_database.dart`; `lib/features/trading_hub/arc_raiders/data/arc_loadout_asset_registry.dart`; `lib/features/trading_hub/arc_raiders/data/arc_saved_loadout_repository.dart`.
- What works: Persistence, attachment mapping, safe fallbacks, weapon/equipment/augment support, Command Centre intelligence links.
- Incomplete: Needs final compatibility sweep as real data evolves.
- UX issues: Image fill and card fit should be spot-checked on all viewport classes.
- Technical debt: Compatibility data will need maintenance as the game database changes.
- Blocks Closed Beta: No.
- Recommended next action: Seeded QA with owned/missing assets.
- Estimated pass size: small.
- Timing: pre-beta.

### Smart Trade Assist

- Classification: Usable but needs polish.
- Current status: Trade Intelligence can score matches, duplicates, wanted items, resources, and recommended actions.
- Main files: `lib/features/trading_hub/arc_raiders/screens/smart_trade_assist_screen.dart`; trade intelligence engine/model files; resource intelligence engine/model files.
- What works: Suggestions are deterministic and use existing data where safe.
- Incomplete: Live volume, reputation weighting, and listing quality need beta data to tune.
- UX issues: Helper labels need manual review for clarity on small cards.
- Technical debt: Multiple trade/listing repositories create integration complexity.
- Blocks Closed Beta: No, but should be monitored closely.
- Recommended next action: Trading privacy/index cleanup and seed trade scenarios.
- Estimated pass size: medium.
- Timing: pre-beta.

### Trading Listings

- Classification: Usable but needs polish.
- Current status: Listings are reachable, integrated with trade intelligence, and governed by Firestore rules/indexes.
- Main files: trading hub listing screens/repositories; `firestore.rules`; `firestore.indexes.json`.
- What works: Listing surfaces and counts feed Command Centre where safe.
- Incomplete: Active legacy/current collection usage needs final audit.
- UX issues: Mobile card density and action reachability need live QA.
- Technical debt: `trading_listings` and `arc_trade_listings` both exist in indexes/rules.
- Blocks Closed Beta: Only if privacy/index review finds a defect.
- Recommended next action: Confirm canonical collection and query/index coverage.
- Estimated pass size: medium.
- Timing: pre-beta.

### Trading Sessions

- Classification: Usable but needs polish.
- Current status: Session planner, trade session models, reminders, calendar export/share, ready/complete/no-show actions exist.
- Main files: `lib/features/trading_hub/arc_raiders/screens/session_planner_screen.dart`; `lib/features/trading_hub/arc_raiders/services/trading_push_service.dart`; session repositories/models.
- What works: Session planning, local reminders on supported platforms, calendar/share hooks.
- Incomplete: 15-minute pre-session reminder and 15-minute post-session feedback prompt are not fully aligned with beta requirement.
- UX issues: One inspected session status string contains mojibake and should be cleaned.
- Technical debt: Web push fallback is limited.
- Blocks Closed Beta: Yes for reminder/feedback promise if marketed.
- Recommended next action: Implement exact reminder timing and feedback prompt flow.
- Estimated pass size: medium.
- Timing: pre-beta.

### Trading Intel

- Classification: Usable but needs polish.
- Current status: Intel reports, confirmations, demand signals, and Command Centre summaries are present.
- Main files: Intel report screens/repositories; trade intelligence; operations seed/progress data.
- What works: Intel reporting can contribute to operations and recommendations.
- Incomplete: Verified intel quality and anti-spam moderation need live beta policy.
- UX issues: Empty states should remain quiet when no reports exist.
- Technical debt: Reputation weighting depends on trustworthy report history.
- Blocks Closed Beta: No.
- Recommended next action: Add beta moderation/admin review checklist.
- Estimated pass size: medium.
- Timing: beta follow-up.

### Match Rider / Matchmaking

- Classification: Usable but needs polish.
- Current status: Feature-gated Match Rider flows, matchmaking/session models, favourite riders, and operations hooks exist.
- Main files: Match Rider screens/repositories/models; `lib/features/trading_hub/arc_raiders/data/arc_operations_seed_data.dart`; route gates in `lib/main.dart`.
- What works: Sessions can be created/joined and tracked enough for beta testing.
- Incomplete: Live matchmaking quality, trust hints, and notification loops need QA.
- UX issues: Mobile route/action reachability needs live testing.
- Technical debt: Multiple session collections require rule/index discipline.
- Blocks Closed Beta: No if scoped as beta feature; yes if real-time guarantees are promised.
- Recommended next action: Seed two-user QA and notification flow test.
- Estimated pass size: medium.
- Timing: pre-beta.

### Raid Planner

- Classification: Usable but needs polish.
- Current status: Route exists and is feature-gated; layout migration covers the screen.
- Main files: `lib/features/trading_hub/arc_raiders/screens/raid_planner_screen.dart`; route gates in `lib/main.dart`.
- What works: Planner is reachable and should share global layout chrome.
- Incomplete: Needs beta feature-scope review against real planner data.
- UX issues: Empty/detail panels must be checked on mobile and web.
- Technical debt: Planner intelligence is less central than Command Centre and may be secondary.
- Blocks Closed Beta: No.
- Recommended next action: Manual QA and hide if not useful enough.
- Estimated pass size: small.
- Timing: beta follow-up.

### Hunt Targets

- Classification: Usable but needs polish.
- Current status: Route exists and is feature-gated; layout migration covers the screen.
- Main files: `lib/features/trading_hub/arc_raiders/screens/hunt_targets_screen.dart`; route gates in `lib/main.dart`.
- What works: Destination is reachable through the ARC hub ecosystem.
- Incomplete: Needs real target data/value review.
- UX issues: Empty states should not feel like filler.
- Technical debt: Lower-priority feature relative to onboarding/trading/rules.
- Blocks Closed Beta: No.
- Recommended next action: Keep gated unless beta content is ready.
- Estimated pass size: small.
- Timing: beta follow-up.

### Operations

- Classification: Usable but needs polish.
- Current status: Operation progress, claims, eligibility, season reset, diagnostics, and reward inventory writes are implemented.
- Main files: `lib/features/trading_hub/arc_raiders/screens/arc_operations_screen.dart`; `lib/features/trading_hub/arc_raiders/data/arc_operations_repository.dart`; `lib/features/trading_hub/arc_raiders/data/arc_operations_seed_data.dart`; `lib/features/trading_hub/arc_raiders/data/arc_season_reset_coordinator.dart`.
- What works: Idempotent progress, reward claims, cosmetic inventory updates, beta/founder eligibility.
- Incomplete: Some Quest/Scrappy/Bench operation milestones still need dedicated progression proof.
- UX issues: Reward/XP balance and density need seeded-account review.
- Technical debt: Operations depend on upstream systems emitting clean milestone signals.
- Blocks Closed Beta: Partially until beta-critical progress bridges and balance are verified.
- Recommended next action: Add proof bridges and run reward balance matrix.
- Estimated pass size: large.
- Timing: pre-beta.

### Reward Vault

- Classification: Usable but needs polish.
- Current status: Badge, title, profile frame, and profile banner inventory, previews, equip state, persistence, and profile/trading integration exist.
- Main files: Reward Vault widgets/screens; `lib/features/trading_hub/arc_raiders/data/arc_operations_repository.dart`; cosmetic profile display widgets.
- What works: Cosmetic ownership/equip/persistence and active profile display.
- Incomplete: Some reward assets still use generated/placeholder treatments where final art is missing.
- UX issues: Final mobile/web preview and banner/frame clipping QA required.
- Technical debt: Asset catalogue gaps must stay visible.
- Blocks Closed Beta: No if placeholder cosmetics are accepted.
- Recommended next action: Balance and asset gap pass after progression proof.
- Estimated pass size: medium.
- Timing: beta follow-up.

### Profile & Reputation

- Classification: Usable but needs polish.
- Current status: Profile completion, equipped cosmetics, availability/away state, trader identity, and reputation hints are wired.
- Main files: profile setup/edit screens; profile repositories/models; cosmetic display widgets; trading profile surfaces.
- What works: Equipped badge/title/frame/banner can display from persisted Reward Vault state.
- Incomplete: Guardian/Trader/Intel/Community reputation needs clearer public beta rules and display consistency.
- UX issues: Public/private identity layouts need mobile/web QA.
- Technical debt: Social links and reputation concepts are split across onboarding, profile, trading, and operations.
- Blocks Closed Beta: No, but social/reputation promises should be scoped.
- Recommended next action: Public profile and social-link polish pass.
- Estimated pass size: medium.
- Timing: beta follow-up.

### Guardian / Sherpa

- Classification: Foundational / incomplete.
- Current status: Guardian language exists in operations/rewards/reputation, but a complete Guardian/Sherpa workflow is not clearly beta-ready.
- Main files: operations seed data; profile/reputation surfaces; Match Rider/community flows.
- What works: Guardian-related rewards and reputation hooks can be represented.
- Incomplete: No clearly complete Guardian/Sherpa matching, validation, or public identity loop was confirmed.
- UX issues: Could over-promise if surfaced too strongly.
- Technical debt: Needs product scope and abuse/safety model.
- Blocks Closed Beta: No if kept scoped or gated.
- Recommended next action: Define MVP or defer.
- Estimated pass size: medium.
- Timing: beta follow-up.

### Favourite Riders

- Classification: Usable but needs polish.
- Current status: Favourite rider data/rules and matching hooks exist.
- Main files: favourite rider models/repositories/rules; Match Rider/profile screens.
- What works: User-to-user preference state can be persisted.
- Incomplete: Notification and ranking effects need confirmation.
- UX issues: Needs discoverability and clear privacy language.
- Technical debt: Depends on stable public profile identity.
- Blocks Closed Beta: No.
- Recommended next action: Include in Match Rider seeded QA.
- Estimated pass size: small.
- Timing: beta follow-up.

### Watches / Queues / Notifications

- Classification: Foundational / incomplete.
- Current status: Notification queue indexes, Firebase Messaging setup, and local trade reminder service exist.
- Main files: `lib/features/trading_hub/arc_raiders/services/trading_push_service.dart`; notification repositories/models; `firestore.indexes.json`; `firestore.rules`.
- What works: Local notification channel and scheduled trade reminder support on non-web platforms.
- Incomplete: 15-minute reminders, post-session feedback prompts, web push, and external push queue behaviour need work.
- UX issues: Users need clear fallback when notifications are unavailable.
- Technical debt: Cross-platform push requires careful permission and background handling.
- Blocks Closed Beta: Yes if beta depends on reminder reliability.
- Recommended next action: PASS 264D reminder/feedback readiness.
- Estimated pass size: medium.
- Timing: pre-beta.

### Referrals

- Classification: Foundational / incomplete.
- Current status: Referral rules and at least one tool screen exist, but referral business flow is not clearly beta-ready.
- Main files: referral screens/repositories; `firestore.rules`.
- What works: Referral data paths are represented.
- Incomplete: End-to-end invite, attribution, rewards, abuse checks, and payout rules need beta policy.
- UX issues: Should not be prominent unless the flow is complete.
- Technical debt: Referral systems can create support and abuse risk.
- Blocks Closed Beta: No if hidden or scoped.
- Recommended next action: Defer monetised referral depth.
- Estimated pass size: medium.
- Timing: post-beta.

### Player Locker Pro

- Classification: Foundational / incomplete.
- Current status: Feature-gated route exists and layout migration includes the screen.
- Main files: `lib/features/trading_hub/arc_raiders/screens/play_like_a_pro_screen.dart`; feature access route gate in `lib/main.dart`.
- What works: The surface is reachable behind a gate.
- Incomplete: Minimum beta value and complete pro feature promise are not settled.
- UX issues: Avoid surfacing as a dominant beta feature if content is thin.
- Technical debt: Premium/pro positioning needs product/legal clarity.
- Blocks Closed Beta: No if gated.
- Recommended next action: Define MVP or leave disabled.
- Estimated pass size: small.
- Timing: beta follow-up.

### Wall of Legends

- Classification: Foundational / incomplete.
- Current status: Rules/data support exists, but a clear beta route/MVP was not confirmed in the route manifest.
- Main files: Wall of Legends rules/data; possible community/profile screens.
- What works: Admin-write/read model can support a controlled leaderboard/showcase.
- Incomplete: Public surface, criteria, moderation, and reset policy.
- UX issues: Should avoid empty/filler presentation.
- Technical debt: Needs anti-abuse and eligibility definition.
- Blocks Closed Beta: No.
- Recommended next action: Ship read-only MVP or defer.
- Estimated pass size: small.
- Timing: beta follow-up.

### Social Profile Links

- Classification: Foundational / incomplete.
- Current status: Social energy/profile concepts exist, but explicit TikTok, YouTube, Twitch, and Kick profile links were not confirmed as fully persisted/displayed.
- Main files: profile setup/edit screens; profile models/repositories; public profile widgets.
- What works: Profile identity and communication preferences exist.
- Incomplete: Explicit creator/social link fields and validation/display.
- UX issues: Streamer/community users may expect visible links.
- Technical debt: Link validation and moderation policy are needed.
- Blocks Closed Beta: No unless promised.
- Recommended next action: Add social-link model and profile UI polish.
- Estimated pass size: medium.
- Timing: beta follow-up.

### Calendar / Reminders

- Classification: Usable but needs polish.
- Current status: Session planner includes calendar/share support and local reminders on supported platforms.
- Main files: `lib/features/trading_hub/arc_raiders/screens/session_planner_screen.dart`; `lib/features/trading_hub/arc_raiders/services/trading_push_service.dart`.
- What works: Calendar integration feasibility is positive through existing `add_2_calendar` and share support.
- Incomplete: 15-minute pre-session and 15-minute post-session prompt behaviour need exact implementation.
- UX issues: One visible mojibake separator should be repaired.
- Technical debt: Web reminder behaviour is intentionally limited.
- Blocks Closed Beta: Only if session reminders are a core beta promise.
- Recommended next action: Reminder/feedback pass.
- Estimated pass size: medium.
- Timing: pre-beta.

### Onboarding

- Classification: Usable but needs polish.
- Current status: Onboarding persistence, active-card focus/surge, archetype multi-select, profile completion, and legal consent have been wired in prior passes.
- Main files: onboarding screens/models/controllers; profile completion evaluator/repository; admin replay tools.
- What works: Core steps persist and drive Command Centre/profile completion.
- Incomplete: Live replay/device QA is still required for Player Type, Wipe State, Blueprint Tracker, archetypes, communication fields, Embark ID, and Level 25 gate.
- UX issues: Mobile overflow and hidden Next button were historical concerns; verify no regression.
- Technical debt: Onboarding state fans out to profile, operations, and Command Centre.
- Blocks Closed Beta: Yes until live QA confirms first-run flow.
- Recommended next action: Authenticated onboarding QA and any focused repairs.
- Estimated pass size: medium.
- Timing: pre-beta.

### Consent / Terms

- Classification: Closed Beta ready.
- Current status: Legal consent is part of onboarding/profile completion and persisted to user state.
- Main files: legal/terms screens; onboarding/profile completion repositories; `lib/main.dart` route map.
- What works: Consent completion can be recorded and affect onboarding completion.
- Incomplete: Final legal copy and versioning policy should be product-reviewed.
- UX issues: Must remain visible on small mobile screens.
- Technical debt: Version migrations should be tested when legal text changes.
- Blocks Closed Beta: No if live QA passes.
- Recommended next action: Include in onboarding QA.
- Estimated pass size: small.
- Timing: pre-beta.

### Admin Tools

- Classification: Usable but needs polish.
- Current status: Admin preview/diagnostic tools exist for onboarding, operations, rewards, and release support.
- Main files: admin console and preview screens; admin route guards; Firebase rules.
- What works: Admin-only routes and diagnostics support beta operations.
- Incomplete: Need final access-control verification against live admin claims.
- UX issues: Admin tools should not be discoverable for ordinary beta users.
- Technical debt: Admin diagnostics can drift if source models change.
- Blocks Closed Beta: No, but access-control failure would.
- Recommended next action: Admin claims/rules QA.
- Estimated pass size: small.
- Timing: pre-beta.

### Subscriptions / Ads

- Classification: Usable but needs polish.
- Current status: Ads/subscription-related dependencies and surfaces exist, with layout QA covering ad/dock collision risk.
- Main files: subscription/ad screens/services; global layout/ad container files.
- What works: Build compatibility is currently clean.
- Incomplete: Monetisation beta policy, entitlement checks, and store readiness need final review.
- UX issues: Ads or bottom docks must not cover page content.
- Technical debt: Major-risk package upgrades were intentionally deferred in dependency stabilisation.
- Blocks Closed Beta: No if monetisation is disabled or limited.
- Recommended next action: Keep simple for Closed Beta and verify no layout collisions.
- Estimated pass size: medium.
- Timing: beta follow-up.

### Settings

- Classification: Closed Beta ready.
- Current status: Settings route exists and global layout migration covers the destination.
- Main files: settings screen; route map; auth/profile preference repositories.
- What works: User settings are reachable within the app shell.
- Incomplete: Final preference inventory should be checked against beta support needs.
- UX issues: No major issue identified in audit.
- Technical debt: Settings often accumulate cross-feature toggles and need naming discipline.
- Blocks Closed Beta: No.
- Recommended next action: Manual smoke test.
- Estimated pass size: small.
- Timing: pre-beta.

### Web Login / Autofill

- Classification: Usable but needs polish.
- Current status: Web builds pass and auth flow remains protected, but autocomplete/autofill and accessibility-specific login checks need manual browser QA.
- Main files: auth/login screens; `web/index.html`; `lib/main.dart`.
- What works: Web build readiness is proven by prior baseline.
- Incomplete: Confirm email/password fields expose correct autofill hints and browser behaviour.
- UX issues: `web/index.html` disables user scaling, which is an accessibility concern for beta users.
- Technical debt: Web and mobile auth UX can diverge.
- Blocks Closed Beta: No, unless browser login QA fails.
- Recommended next action: Browser login/autofill test pass.
- Estimated pass size: small.
- Timing: pre-beta.

### Firebase Rules / Indexes

- Classification: Blocked.
- Current status: `firestore.rules` uses rules version 2 and covers many user/trading/operations paths; `firestore.indexes.json` has broad query support.
- Main files: `firestore.rules`; `firestore.indexes.json`; Firebase repositories.
- What works: Rules are present and structured for owner/admin access across major paths.
- Incomplete: Emulator rules tests and deploy verification are not present/confirmed.
- UX issues: Rule/index failures surface as broken live screens.
- Technical debt: Broad nested user rule and parallel legacy/current trade collections require review.
- Blocks Closed Beta: Yes.
- Recommended next action: PASS 264A Firebase rules/index/security validation.
- Estimated pass size: large.
- Timing: pre-beta.

### Android Build / Deploy Readiness

- Classification: Usable but needs polish.
- Current status: Debug APK build passes at baseline, Java 17 compatibility is configured, and core library desugaring is enabled.
- Main files: `android/app/build.gradle.kts`; Android manifest and Gradle files.
- What works: Debug build readiness is proven.
- Incomplete: Release signing/configuration needs production-safe setup; release distribution path must be verified.
- UX issues: Device QA still required for orientation/layout.
- Technical debt: Debug signing for release is a deployment risk.
- Blocks Closed Beta: Yes for external Android distribution.
- Recommended next action: Android release signing and deploy checklist.
- Estimated pass size: medium.
- Timing: pre-beta.

### Web Build / Deploy Readiness

- Classification: Closed Beta ready.
- Current status: Web release build passes at baseline and route/layout migration covers web surfaces.
- Main files: `web/index.html`; `web/manifest.json`; Firebase hosting config; app route map.
- What works: Release build is proven.
- Incomplete: Final hosted smoke test and Firebase hosting cache hygiene.
- UX issues: Desktop widths and mobile browser zoom/accessibility should be manually checked.
- Technical debt: Generated hosting cache files should remain out of feature commits.
- Blocks Closed Beta: No if Firebase deploy path is verified.
- Recommended next action: Hosted smoke test after Firebase rules/index pass.
- Estimated pass size: small.
- Timing: pre-beta.
