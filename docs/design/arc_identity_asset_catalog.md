# ARC Identity And Reward Asset Catalogue

Generated from commit: `d86bc796e2fc7cbde9ae46a47da6ac319f017516`

This catalogue records canonical names, identifiers, unlock logic and asset needs found in the live application code. It does not rename or redesign any production item.

## Source Map

| Area | Canonical source |
| --- | --- |
| Player archetypes | `lib/features/trading_hub/arc_raiders/data/arc_player_archetype_catalog.dart`, `ArcPlayerArchetypeCatalog` |
| Squad/session intents and priorities | `lib/features/trading_hub/arc_raiders/data/arc_player_session_catalog.dart`, `ArcPlayerSessionCatalog` |
| Social energy states | `lib/reg/onboarding_basic_profile_screen.dart`, `_socialEnergyOptions` and `_socialEnergyDescription` |
| Profile identity fields | `lib/features/trading_hub/arc_raiders/models/arc_trader_profile.dart`, `ArcTraderProfile`; `lib/features/trading_hub/arc_raiders/models/trading_profile.dart`, `TradingProfile` |
| Operations and rewards | `lib/features/trading_hub/arc_raiders/data/arc_operations_seed_data.dart`, `ArcOperationsSeedData` |
| Cosmetic inventory and equipped state | `lib/features/trading_hub/arc_raiders/models/arc_operations_models.dart`, `ArcRewardInventoryItem`, `ArcEquippedCosmetics`; `lib/features/trading_hub/arc_raiders/repositories/arc_operations_repository.dart` |
| Profile/trading cosmetic display | `lib/features/trading_hub/arc_raiders/models/trading_cosmetic_identity.dart`; `lib/features/trading_hub/arc_raiders/widgets/trading_cosmetic_identity_strip.dart` |
| Asset declarations | `pubspec.yaml`, `flutter.assets` |

## 1. Player Archetypes

All archetypes are selectable profile identities. They are reachable from onboarding, profile setup/edit, trader profile, and Match Rider compatibility.

| Display name | Stable identifier | Description | Unlock condition | Reward type | Rarity/tier | Current asset path | Fallback icon | Artwork exists | Unique artwork | Reachable | Source | Design notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Balanced Raider | `balanced-raider` | Blends quests, blueprints, loot, trading and squad play. | Always selectable | Profile archetype | Not defined | Not defined | `Icons.explore_rounded` | No | No | Yes | `ArcPlayerArchetypeCatalog.balanced` | Broad all-rounder identity. |
| Quest-driven Raider | `quest-driven-raider` | Prioritises quests, unlocks and guided progression. | Always selectable | Profile archetype | Not defined | Not defined | `Icons.flag_rounded` | No | No | Yes | `ArcPlayerArchetypeCatalog.questDriven` | Quest/progression focused identity. |
| Blueprint Grinder | `blueprint-grinder` | Prioritises blueprint collection, duplicates and trade value. | Always selectable | Profile archetype | Not defined | Not defined | `Icons.description_rounded` | No | No | Yes | `ArcPlayerArchetypeCatalog.blueprintGrinder` | Blueprint collector and duplicate trader. |
| Helper / Support Player | `helper-support-player` | Focuses on team utility, survival and helping the squad. | Always selectable | Profile archetype | Not defined | Not defined | `Icons.volunteer_activism_rounded` | No | No | Yes | `ArcPlayerArchetypeCatalog.helper` | Support/guardian-style identity. |
| Trader / Resource Runner | `trader-resource-runner` | Builds stash value, materials and safe extraction routes. | Always selectable | Profile archetype | Not defined | Not defined | `Icons.handshake_rounded` | No | No | Yes | `ArcPlayerArchetypeCatalog.trader` | Marketplace/resource identity. |
| PvP Hunter | `pvp-hunter` | Prioritises combat readiness and confident raids. | Always selectable | Profile archetype | Not defined | Not defined | `Icons.local_fire_department_rounded` | No | No | Yes | `ArcPlayerArchetypeCatalog.pvpHunter` | Combat-forward player identity. |
| Rat Hunter | `rat-hunter` | Actively hunts campers, ambushers, hidden threats and opportunistic attackers. | Always selectable | Profile archetype | Not defined | Not defined | `Icons.radar_rounded` | No | No | Yes | `ArcPlayerArchetypeCatalog.ratHunter` | Anti-ambush identity; tested in match compatibility. |
| Casual Squad Player | `casual-squad-player` | Prefers low-pressure play, discovery and flexible goals. | Always selectable | Profile archetype | Not defined | Not defined | `Icons.groups_rounded` | No | No | Yes | `ArcPlayerArchetypeCatalog.casual` | Lower-pressure squad identity. |

## 2. Match-Fit Profile Identities

These are persisted profile identity fields used by profile, trading, Match Rider and Command Centre logic.

| Display name | Stable identifier | Description | Unlock condition | Reward type | Rarity/tier | Current asset path | Fallback icon | Artwork exists | Unique artwork | Reachable | Source | Design notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| UAG ID | `uagId` | Stable UAG identity value. | Profile setup | Profile identity field | Not defined | Not defined | Not defined | No | No | Yes | `ArcTraderProfile.uagId` | Used for profile identity and referral/trader lookup. |
| UAG Name | `uagName` | Public UAG display name. | Profile setup | Profile identity field | Not defined | Not defined | Not defined | No | No | Yes | `ArcTraderProfile.uagName` | Main profile name in ARC surfaces. |
| Embark ID | `embarkId` | Used to help players find you outside the app. | Profile setup | Profile identity field | Not defined | Not defined | Not defined | No | No | Yes | `ArcTraderProfile.embarkId`, `TradingProfile.embarkId` | Critical for trade session handoff. |
| Region | `region` | Used for squad fit and better timing. | Profile setup | Profile identity field | Not defined | Not defined | Not defined | No | No | Yes | `ArcTraderProfile.region`, `TradingProfile.region` | Match/trade filtering field. |
| Platform | `platform` / `preferredPlatform` | Where the player usually raids from. | Profile setup | Profile identity field | Not defined | Not defined | Not defined | No | No | Yes | `ArcTraderProfile.platform`, `TradingProfile.preferredPlatform` | Match/trade compatibility field. |
| Communication Style | `communicationStyle` | Persisted communication preference. | Profile setup/edit | Profile identity field | Not defined | Not defined | Not defined | No | No | Yes | `ArcTraderProfile.communicationStyle` | Used by Match Rider compatibility. |
| Social Energy | `socialEnergy` | Current session mood/voice energy. | Profile setup/edit | Profile identity field | Not defined | Not defined | `Icons.mood_rounded` | No | No | Yes | `ArcTraderProfile.socialEnergy`; onboarding `_socialEnergyOptions` | Personalises matchmaking tone. |
| Session Intent | `sessionIntent` | Current session focus. | Profile setup/edit | Profile identity field | Not defined | Not defined | `ArcPlayerSessionCatalog.iconFor` | No | No | Yes | `ArcTraderProfile.sessionIntent` | Feeds Command Centre and matching. |
| Current Priority | `currentPriority` | Current progression priority. | Profile setup/edit | Profile identity field | Not defined | Not defined | `ArcPlayerSessionCatalog.iconFor` | No | No | Yes | `ArcTraderProfile.currentPriority` | Feeds Command Centre and matching. |
| Referral Code | `referralCode` | User referral identity code. | Generated/reserved by profile repository | Profile identity field | Not defined | Not defined | Not defined | No | No | Yes | `ArcTraderProfile.referralCode` | Used by referral rewards and tools. |
| Founding Trader | `foundingTrader` | Boolean flag on trading profile. | Not defined | Trading reputation identity | Not defined | Not defined | Not defined | No | No | Yes | `TradingProfile.foundingTrader` | No linked cosmetic reward found. |

## 3. Squad Intents

These are canonical onboarding squad intents from `_squadIntents`. Session intent normalization maps related values into `ArcPlayerSessionCatalog.sessionIntents`.

| Display name | Stable identifier | Description | Unlock condition | Reward type | Rarity/tier | Current asset path | Fallback icon | Artwork exists | Unique artwork | Reachable | Source | Design notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Flexible | `flexible` | Keep recommendations flexible depending on your session. | Always selectable | Squad intent | Not defined | Not defined | `Icons.hub_rounded` | No | No | Yes | `_squadIntents`; `_squadIntentDescription` | Default low-commitment state. |
| Squad up | `squad-up` | You actively want teammates and voice-ready sessions. | Always selectable | Squad intent | Not defined | Not defined | `Icons.groups_rounded` | No | No | Yes | `_squadIntents`; `_squadIntentDescription` | Strong matchmaking signal. |
| Quest team | `quest-team` | Match with players chasing similar quests. | Always selectable | Squad intent | Not defined | Not defined | `Icons.flag_rounded` | No | No | Yes | `_squadIntents`; `_squadIntentDescription` | Normalizes to Quests when used as session intent. |
| Blueprint runs | `blueprint-runs` | Match with players farming blueprints or duplicates. | Always selectable | Squad intent | Not defined | Not defined | `Icons.description_rounded` | No | No | Yes | `_squadIntents`; `_squadIntentDescription` | Normalizes to Blueprint farming. |
| Trade focused | `trade-focused` | Prioritise trade-ready players and inventory value. | Always selectable | Squad intent | Not defined | Not defined | `Icons.swap_horiz_rounded` | No | No | Yes | `_squadIntents`; `_squadIntentDescription` | Normalizes to Trading. |
| Trials | `trials` | Find players who want to focus on Trials progress. | Always selectable | Squad intent | Not defined | Not defined | `Icons.emoji_events_rounded` | No | No | Yes | `_squadIntents`; `_squadIntentDescription` | Added as tested Trials intent. |
| Solo for now | `solo-for-now` | Keep matchmaking light and avoid forced squad prompts. | Always selectable | Squad intent | Not defined | Not defined | `Icons.person_rounded` | No | No | Yes | `_squadIntents`; `_squadIntentDescription` | Opt-out/low matchmaking pressure. |

## 4. Social-Energy States

| Display name | Stable identifier | Description | Unlock condition | Reward type | Rarity/tier | Current asset path | Fallback icon | Artwork exists | Unique artwork | Reachable | Source | Design notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Depends on the day | `depends-on-the-day` | Let your session mood change without locking your whole profile. | Always selectable | Social-energy state | Not defined | Not defined | `Icons.mood_rounded` | No | No | Yes | `_socialEnergyOptions`; `_socialEnergyDescription` | Default flexible mood. |
| Chatty and outgoing | `chatty-and-outgoing` | Good day for voice, squad calls and social runs. | Always selectable | Social-energy state | Not defined | Not defined | `Icons.mood_rounded` | No | No | Yes | `_socialEnergyOptions`; `_socialEnergyDescription` | Voice-forward state. |
| Quiet but cooperative | `quiet-but-cooperative` | Team-friendly without needing constant chat. | Always selectable | Social-energy state | Not defined | Not defined | `Icons.mood_rounded` | No | No | Yes | `_socialEnergyOptions`; `_socialEnergyDescription` | Low-chat team state. |
| High energy | `high-energy` | Good day for faster, more intense raids. | Always selectable | Social-energy state | Not defined | Not defined | `Icons.mood_rounded` | No | No | Yes | `_socialEnergyOptions`; `_socialEnergyDescription` | High-intensity session state. |
| Low energy today | `low-energy-today` | Prefer calmer routes, clear plans and less pressure. | Always selectable | Social-energy state | Not defined | Not defined | `Icons.mood_rounded` | No | No | Yes | `_socialEnergyOptions`; `_socialEnergyDescription` | Calmer route state. |
| Prefer pings over voice | `prefer-pings-over-voice` | Matchmaking should favour low-voice communication. | Always selectable | Social-energy state | Not defined | Not defined | `Icons.mood_rounded` | No | No | Yes | `_socialEnergyOptions`; `_socialEnergyDescription` | Low-voice matching signal. |

## 5. Operations

Operation tasks are seeded in `ArcOperationsSeedData` and selected by `ArcDynamicOperationsEngine`. The Operation task card uses the first reward asset if one exists; otherwise it falls back to `Icons.military_tech_rounded`. Command Centre uses separate operation/system artwork from `assets/arc_raiders/operations/`.

| Display name | Stable identifier | Category | Description | Unlock condition | Rewards | Rarity/tier | Current icon or asset path | Artwork exists | Reachable |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| First Contact | `beta_complete_profile` | onboarding | Complete your Raider profile so trading, squads and Operations can personalise around you. | Beta Operation; target 1 profile completion | Beta Access Badge, +10 Intel XP | Beta cadence | `assets/arc_raiders/operations/badges/beta_access_plus.png` | Yes, reward asset | Yes |
| Open The Market | `beta_first_listing` | trading | Create your first trade listing and help seed the beta economy. | Beta Operation; target 1 listing | +1 Extra Trade Slot, +10 Intel XP | Beta cadence | Fallback `Icons.military_tech_rounded` | No task art | Yes |
| Trade Pioneer | `beta_first_trade` | trading | Complete your first successful trade during the closed beta. | Beta Operation; target 1 trade | Trade Pioneer Badge, +25 Intel XP | Beta cadence | `assets/arc_raiders/operations/badges/pathfinder.png` | Yes, reward asset | Yes |
| Verified Intel | `beta_verified_intel` | intel | Submit intel that is confirmed by the community. Raw reports are low value; verified reports earn real rewards. | Beta Operation; target 3 verified intel interactions | Intel Officer Badge, +25 Intel XP | Beta cadence | `assets/arc_raiders/operations/badges/golden_pathfinder.png` | Yes, reward asset | Yes |
| Squad Signal | `beta_match_raider` | matchmaking | Complete a Match Raider session and rate your squadmates afterwards. | Beta Operation; target 1 match session | +1 Extra Match Request, +10 Intel XP | Beta cadence | Fallback `Icons.military_tech_rounded` | No task art | Yes |
| Personal Build Online | `beta_loadout_saved` | loadout | Save your first Favourite Loadout so trades and goals can target your build. | Beta Operation; target 1 saved loadout | Founding Raider Badge, +10 Intel XP | Beta cadence | `assets/arc_raiders/operations/badges/founding_raider.png` | Yes, reward asset | Yes |
| Field Tester | `beta_feedback` | beta | Submit actionable feedback during closed beta. Bugs, missing images, bad flows and unclear screens all count. | Beta Operation; target 3 feedback submissions | Field Tester Title, Beta Signal Frame, +25 Intel XP | Beta cadence | Fallback `Icons.military_tech_rounded` | No task art | Yes |
| Guardian Run | `beta_guardian` | guardian | Help another Raider complete a goal, trade or early build step with nothing expected back. | Beta Operation; target 1 guardian action | Community Raider Badge, Guardian Signal Frame, Guardian Banner, +25 Intel XP | Beta cadence | `assets/arc_raiders/operations/badges/community_heart.png` | Yes, reward asset | Yes |
| Closed Beta Veteran | `beta_return_days` | beta | Return on 10 separate beta days and help keep the hub active while systems are being tested. | Beta Operation; target 10 beta days | OG Legend Badge, UAG Inner Circle Badge, Beta Command Banner | Beta cadence | `assets/arc_raiders/operations/badges/og_legend.png` | Yes, reward asset | Yes |
| Keep The Market Alive | `daily_refresh_listing` | trading | Create or refresh one active listing. Operations will prioritise this when marketplace activity is low. | Daily Operation; target 1 listing refresh | +5 Intel XP | Daily cadence | Fallback `Icons.military_tech_rounded` | No task art | Yes |
| Update Availability | `daily_update_availability` | matchmaking | Set your current availability so Match Raider and Trade reminders can recommend active players. | Daily Operation; target 1 availability update | +5 Intel XP | Daily cadence | Fallback `Icons.military_tech_rounded` | No task art | Yes |
| Confirm Intel | `daily_verify_intel` | intel | Confirm a community blueprint report. Verified intel is worth more than raw report spam. | Daily Operation; target 1 verified intel action | +5 Intel XP | Daily cadence | Fallback `Icons.military_tech_rounded` | No task art | Yes |
| Market Operator | `weekly_trade_run` | trading | Complete 3 successful trades this week. | Weekly Operation; target 3 trades | +1 Extra Trade Slot, +25 Intel XP | Weekly cadence | Fallback `Icons.military_tech_rounded` | No task art | Yes |
| Intel Network | `weekly_verified_intel` | intel | Earn 5 confirmed intel interactions. This rewards quality instead of spam reports. | Weekly Operation; target 5 verified intel interactions | +25 Intel XP | Weekly cadence | Fallback `Icons.military_tech_rounded` | No task art | Yes |
| Build Progress | `weekly_loadout_progress` | loadout | Acquire, craft or trade towards 50% completion on your Favourite Loadout. | Weekly Operation; target 1 loadout progress event | +25 Intel XP | Weekly cadence | Fallback `Icons.military_tech_rounded` | No task art | Yes |
| Trader Bronze | `monthly_trader_bronze` | trading | Complete 10 successful trades this month. | Monthly Operation; target 10 trades | +1 Extra Trade Slot, +25 Intel XP | Monthly cadence | Fallback `Icons.military_tech_rounded` | No task art | Yes |
| Guardian Detail | `monthly_guardian` | guardian | Help 5 Raiders through trades, advice, first builds or squad support. | Monthly Operation; target 5 helped players | Community Raider Badge, +25 Intel XP | Monthly cadence | `assets/arc_raiders/operations/badges/community_heart.png` | Yes, reward asset | Yes |
| First Trade | `life_first_trade` | trading | Complete your first successful trade. | Lifetime Operation; target 1 trade | Trade Pioneer Badge | Lifetime cadence | `assets/arc_raiders/operations/badges/pathfinder.png` | Yes, reward asset | Yes |
| Trader I | `life_trader_50` | trading | Complete 50 successful trades. Lifetime progress never resets after wipes. | Lifetime Operation; target 50 trades | +1 Extra Trade Slot, +25 Intel XP | Lifetime cadence | Fallback `Icons.military_tech_rounded` | No task art | Yes |
| Guardian | `life_guardian_10` | guardian | Help 10 Raiders through trades, matchmaking or early progression. | Lifetime Operation; target 10 helped players | Community Raider Badge | Lifetime cadence | `assets/arc_raiders/operations/badges/community_heart.png` | Yes, reward asset | Yes |
| Recruitment Cell | `life_recruit_3` | referral | Refer 3 active Raiders who complete profile setup and return on 3 separate days. | Lifetime Operation; target 3 referrals | UAG Inner Circle Badge | Lifetime cadence | `assets/arc_raiders/operations/badges/inner_circle.png` | Yes, reward asset | Yes |

## 6. Badges

| Display name | Stable identifier | Category | Description | Unlock condition | Reward type | Rarity/tier | Current asset path | Fallback icon | Artwork exists | Unique artwork | Reachable | Source |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Beta Access Badge | `beta_access` | Closed Beta rewards | Not defined | First Contact | badge | Common, beta exclusive | `assets/arc_raiders/operations/badges/beta_access_plus.png` | `Icons.military_tech_rounded` | Yes | Yes | Yes | `ArcOperationsSeedData.rewards` |
| Founding Raider Badge | `founding_raider` | Founder and Closed Beta rewards | Not defined | Personal Build Online | badge | Common, beta exclusive | `assets/arc_raiders/operations/badges/founding_raider.png` | `Icons.military_tech_rounded` | Yes | Yes | Yes | `ArcOperationsSeedData.rewards` |
| Trade Pioneer Badge | `trade_pioneer` | Trading and reputation rewards | Not defined | Trade Pioneer or First Trade | badge | Common, beta exclusive | `assets/arc_raiders/operations/badges/pathfinder.png` | `Icons.military_tech_rounded` | Yes | Yes | Yes | `ArcOperationsSeedData.rewards` |
| Intel Officer Badge | `intel_officer` | Intel rewards | Not defined | Verified Intel | badge | Common, beta exclusive | `assets/arc_raiders/operations/badges/golden_pathfinder.png` | `Icons.military_tech_rounded` | Yes | Yes | Yes | `ArcOperationsSeedData.rewards` |
| Community Raider Badge | `community_raider` | Guardian and community rewards | Not defined | Guardian Run, Guardian Detail or Guardian | badge | Common, beta exclusive | `assets/arc_raiders/operations/badges/community_heart.png` | `Icons.military_tech_rounded` | Yes | Yes | Yes | `ArcOperationsSeedData.rewards` |
| OG Legend Badge | `og_legend` | Founder and Closed Beta rewards | Not defined | Closed Beta Veteran | badge | Common, beta exclusive | `assets/arc_raiders/operations/badges/og_legend.png` | `Icons.military_tech_rounded` | Yes | Yes | Yes | `ArcOperationsSeedData.rewards` |
| UAG Inner Circle Badge | `inner_circle` | Founder and Closed Beta rewards | Not defined | Closed Beta Veteran or Recruitment Cell | badge | Common, beta exclusive | `assets/arc_raiders/operations/badges/inner_circle.png` | `Icons.military_tech_rounded` | Yes | Yes | Yes | `ArcOperationsSeedData.rewards` |

## 7. Titles

| Display name | Stable identifier | Category | Description | Unlock condition | Reward type | Rarity/tier | Current asset path | Fallback icon | Artwork exists | Unique artwork | Reachable | Source |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Field Tester Title | `field_tester` | Founder and Closed Beta rewards | Not defined | Field Tester | title | Closed Beta, beta exclusive | Not defined | `Icons.title_rounded`, `Icons.workspace_premium_rounded` when equipped | No | No | Yes | `ArcOperationsSeedData.rewards` |

## 8. Profile Frames

| Display name | Stable identifier | Category | Description | Unlock condition | Reward type | Rarity/tier | Current asset path | Fallback icon | Artwork exists | Unique artwork | Reachable | Source |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Beta Signal Frame | `beta_signal_frame` | Founder and Closed Beta rewards | Not defined | Field Tester | profileFrame | Closed Beta, beta exclusive | Not defined | `Icons.person_rounded` inside generated frame shell; `Icons.crop_square_rounded` in summary | No | No | Yes | `ArcOperationsSeedData.rewards` |
| Guardian Signal Frame | `guardian_signal_frame` | Guardian and community rewards | Not defined | Guardian Run | profileFrame | Community, beta exclusive | Not defined | `Icons.person_rounded` inside generated frame shell; `Icons.crop_square_rounded` in summary | No | No | Yes | `ArcOperationsSeedData.rewards` |

## 9. Profile Banners

| Display name | Stable identifier | Category | Description | Unlock condition | Reward type | Rarity/tier | Current asset path | Fallback icon | Artwork exists | Unique artwork | Reachable | Source |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Beta Command Banner | `beta_command_banner` | Founder and Closed Beta rewards | Not defined | Closed Beta Veteran | profileBanner | Closed Beta, beta exclusive | Not defined | `Icons.view_day_rounded` inside generated gradient banner | No | No | Yes | `ArcOperationsSeedData.rewards` |
| Guardian Banner | `guardian_banner` | Guardian and community rewards | Not defined | Guardian Run | profileBanner | Community, beta exclusive | Not defined | `Icons.view_day_rounded` inside generated gradient banner | No | No | Yes | `ArcOperationsSeedData.rewards` |

## 10. Founder And Closed Beta Rewards

Canonical beta/founder-associated rewards: Beta Access Badge, Founding Raider Badge, Field Tester Title, Beta Signal Frame, Beta Command Banner, Trade Pioneer Badge, Intel Officer Badge, OG Legend Badge, UAG Inner Circle Badge. `ArcCosmeticRarity.founder` exists in the model but no seeded reward currently uses the founder rarity value.

## 11. Trading And Reputation Rewards

Canonical trading/reputation rewards: Trade Pioneer Badge, +1 Extra Trade Slot, +25 Intel XP, +10 Intel XP, +5 Intel XP. Trading reputation profile fields include completed trades, no-shows, betrayal flags, cancelled trades, successful trade streak, total offers sent, total offers received and founding trader.

## 12. Guardian And Community Rewards

Canonical guardian/community rewards: Community Raider Badge, Guardian Signal Frame, Guardian Banner, UAG Inner Circle Badge where earned through Recruitment Cell. Community rarity exists and is used by Guardian Signal Frame and Guardian Banner.

## 13. Creator And Partner Rewards

`ArcCosmeticRarity.creator` exists in the model. No seeded creator or partner reward definitions were found in `ArcOperationsSeedData`.

## 14. Intel Rewards

Canonical Intel rewards: Intel Officer Badge, +5 Intel XP, +10 Intel XP, +25 Intel XP. Intel XP rewards do not define artwork and are represented as operation/reward text.

## 15. Missing Or Placeholder Assets

| Item | Current behaviour | Status |
| --- | --- | --- |
| All player archetypes | IconData only; no asset path | Missing unique artwork |
| Squad intents and session priorities | IconData only via `ArcPlayerSessionCatalog.iconFor` | Missing unique artwork |
| Social-energy states | Shared mood icon in onboarding | Missing unique artwork |
| Field Tester Title | Text-only title card/preview | Missing unique artwork |
| Beta Signal Frame and Guardian Signal Frame | Generated frame shell with `Icons.person_rounded` if no asset path | Shared placeholder |
| Beta Command Banner and Guardian Banner | Generated gradient banner with `Icons.view_day_rounded` if no asset path | Shared placeholder |
| Extra Trade Slot, Extra Match Request, Intel XP rewards | Text reward chips, no asset path | Missing unique reward artwork |
| Operation tasks without a badge reward | Operation card falls back to `Icons.military_tech_rounded` | Missing task-specific artwork |
| Extra badge files in `assets/arc_raiders/operations/badges/` | Files exist but are not mapped to seeded rewards | Unused/unreachable artwork |

## Asset Validation

Declared asset directories in `pubspec.yaml`: `assets/images/arc_raiders/hub/`, `assets/images/arc_raiders/loadouts/weapons/`, `assets/icon/`, `assets/arc_raiders/banners/`, `assets/arc_raiders/blueprints/`, `assets/arc_raiders/scrappy_resources/`, `assets/arc_raiders/items/`, `assets/arc_raiders/operations/`, `assets/arc_raiders/operations/badges/`, `assets/arc_raiders/hero_cards/`.

All asset paths referenced by seeded Operation badge rewards exist with exact casing and are included by the declared `assets/arc_raiders/operations/badges/` directory.

No asset filenames differing only by casing were found under tracked `assets/`.
