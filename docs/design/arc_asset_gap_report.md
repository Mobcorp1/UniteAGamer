# ARC Asset Gap Report

Generated from commit: `d86bc796e2fc7cbde9ae46a47da6ac319f017516`

Priority definitions:

- P0: broken path or missing asset causing a runtime or build problem.
- P1: multiple distinct rewards unintentionally using the same generic asset.
- P2: canonical reward or archetype has no unique artwork.
- P3: optional visual polish or future variation.

## P0 - Broken Runtime Or Build Asset Paths

No P0 asset path issues were found. Seeded Operation badge reward paths exist with exact casing and are included by `pubspec.yaml`.

Validated seeded reward assets:

- `assets/arc_raiders/operations/badges/beta_access_plus.png`
- `assets/arc_raiders/operations/badges/founding_raider.png`
- `assets/arc_raiders/operations/badges/pathfinder.png`
- `assets/arc_raiders/operations/badges/golden_pathfinder.png`
- `assets/arc_raiders/operations/badges/community_heart.png`
- `assets/arc_raiders/operations/badges/og_legend.png`
- `assets/arc_raiders/operations/badges/inner_circle.png`

## P1 - Shared Generic Asset Or Placeholder Across Distinct Rewards

| Canonical item | Current behaviour | Source file | Intended UI location | Recommended asset filename | Priority | Implementation dependency |
| --- | --- | --- | --- | --- | --- | --- |
| Beta Signal Frame | Uses generated frame shell with `Icons.person_rounded`; no asset path. | `arc_operations_seed_data.dart` | Reward Vault frame inventory/preview, profile avatar frame, trading identity | `frame_beta_signal.webp` | P1 | Add asset path to `ArcOperationsSeedData.rewards['beta_signal_frame']`. |
| Guardian Signal Frame | Uses same generated frame shell with `Icons.person_rounded`; no asset path. | `arc_operations_seed_data.dart` | Reward Vault frame inventory/preview, profile avatar frame, trading identity | `frame_guardian_signal.webp` | P1 | Add asset path to `ArcOperationsSeedData.rewards['guardian_signal_frame']`. |
| Beta Command Banner | Uses generated gradient banner with `Icons.view_day_rounded`; no asset path. | `arc_operations_seed_data.dart` | Reward Vault banner inventory/preview, profile header, trading identity | `banner_beta_command.webp` | P1 | Add asset path to `ArcOperationsSeedData.rewards['beta_command_banner']`. |
| Guardian Banner | Uses same generated gradient banner with `Icons.view_day_rounded`; no asset path. | `arc_operations_seed_data.dart` | Reward Vault banner inventory/preview, profile header, trading identity | `banner_guardian.webp` | P1 | Add asset path to `ArcOperationsSeedData.rewards['guardian_banner']`. |

## P2 - Canonical Item Has No Unique Artwork

| Canonical item | Current behaviour | Source file | Intended UI location | Recommended asset filename | Priority | Implementation dependency |
| --- | --- | --- | --- | --- | --- | --- |
| Balanced Raider | IconData only. | `arc_player_archetype_catalog.dart` | Onboarding, profile setup/edit, Match Rider | `archetype_balanced_raider.webp` | P2 | Add archetype asset support if production UI should use image art. |
| Quest-driven Raider | IconData only. | `arc_player_archetype_catalog.dart` | Onboarding, profile setup/edit, Match Rider | `archetype_quest_driven_raider.webp` | P2 | Add archetype asset support if production UI should use image art. |
| Blueprint Grinder | IconData only. | `arc_player_archetype_catalog.dart` | Onboarding, profile setup/edit, Match Rider | `archetype_blueprint_grinder.webp` | P2 | Add archetype asset support if production UI should use image art. |
| Helper / Support Player | IconData only. | `arc_player_archetype_catalog.dart` | Onboarding, profile setup/edit, Match Rider | `archetype_helper_support_player.webp` | P2 | Add archetype asset support if production UI should use image art. |
| Trader / Resource Runner | IconData only. | `arc_player_archetype_catalog.dart` | Onboarding, profile setup/edit, Match Rider | `archetype_trader_resource_runner.webp` | P2 | Add archetype asset support if production UI should use image art. |
| PvP Hunter | IconData only. | `arc_player_archetype_catalog.dart` | Onboarding, profile setup/edit, Match Rider | `archetype_pvp_hunter.webp` | P2 | Add archetype asset support if production UI should use image art. |
| Rat Hunter | IconData only. | `arc_player_archetype_catalog.dart` | Onboarding, profile setup/edit, Match Rider | `archetype_rat_hunter.webp` | P2 | Add archetype asset support if production UI should use image art. |
| Casual Squad Player | IconData only. | `arc_player_archetype_catalog.dart` | Onboarding, profile setup/edit, Match Rider | `archetype_casual_squad_player.webp` | P2 | Add archetype asset support if production UI should use image art. |
| Field Tester Title | Text-only title treatment; no asset path. | `arc_operations_seed_data.dart` | Reward Vault title inventory/preview, profile title | `title_field_tester.webp` | P2 | Add title asset/treatment support if titles require artwork. |
| +1 Extra Trade Slot | Text reward chip only. | `arc_operations_seed_data.dart` | Operation cards and reward summary | `reward_extra_trade.webp` | P2 | Add non-cosmetic reward icon support. |
| +1 Extra Match Request | Text reward chip only. | `arc_operations_seed_data.dart` | Operation cards and reward summary | `reward_extra_match.webp` | P2 | Add non-cosmetic reward icon support. |
| +5 Intel XP | Text reward chip only. | `arc_operations_seed_data.dart` | Operation cards and reward summary | `reward_xp_5.webp` | P2 | Add non-cosmetic reward icon support. |
| +10 Intel XP | Text reward chip only. | `arc_operations_seed_data.dart` | Operation cards and reward summary | `reward_xp_10.webp` | P2 | Add non-cosmetic reward icon support. |
| +25 Intel XP | Text reward chip only. | `arc_operations_seed_data.dart` | Operation cards and reward summary | `reward_xp_25.webp` | P2 | Add non-cosmetic reward icon support. |
| Open The Market | No task-specific asset in Operations screen; falls back to `Icons.military_tech_rounded`. | `arc_operations_seed_data.dart` | Operations Command task card | `operation_beta_first_listing.webp` | P2 | Add operation task asset support or map task to existing operation-card art. |
| Squad Signal | No task-specific asset in Operations screen; falls back to `Icons.military_tech_rounded`. | `arc_operations_seed_data.dart` | Operations Command task card | `operation_beta_match_raider.webp` | P2 | Add operation task asset support or map task to existing operation-card art. |
| Field Tester | No task-specific asset in Operations screen; falls back to `Icons.military_tech_rounded`. | `arc_operations_seed_data.dart` | Operations Command task card | `operation_beta_feedback.webp` | P2 | Add operation task asset support or map task to existing operation-card art. |
| Daily/weekly/monthly Operation tasks without badge rewards | No task-specific asset in Operations screen; generic fallback icon. | `arc_operations_seed_data.dart` | Operations Command task cards | `operation_<canonical_id>.webp` | P2 | Add operation task asset support or map task to existing operation-card art. |

## P3 - Optional Polish Or Future Variation

| Canonical item | Current behaviour | Source file | Intended UI location | Recommended asset filename | Priority | Implementation dependency |
| --- | --- | --- | --- | --- | --- | --- |
| `ArcCosmeticRarity.founder` | Rarity exists but no seeded reward uses it. | `arc_operations_models.dart` | Future Reward Vault cosmetics | `rarity_founder_style_guide.webp` | P3 | Define founder reward before implementing art. |
| `ArcCosmeticRarity.creator` | Rarity exists but no seeded reward uses it. | `arc_operations_models.dart` | Future creator cosmetics | `rarity_creator_style_guide.webp` | P3 | Define creator reward before implementing art. |
| Partner rewards | No seeded partner reward definitions found. | Not defined | Future partner cosmetics | `partner_reward_placeholder.webp` | P3 | Add canonical partner reward definitions first. |
| `beta_pioneer.png` | Asset exists but is not mapped to a seeded reward. | `assets/arc_raiders/operations/badges/` | Not currently reachable | `badge_beta_pioneer.webp` | P3 | Decide whether to map or archive. |
| `cyberpunk_achievement.png` | Asset exists but is not mapped to a seeded reward. | `assets/arc_raiders/operations/badges/` | Not currently reachable | `badge_cyberpunk_achievement.webp` | P3 | Decide whether to map or archive. |
| `early_supporter.png` | Asset exists but is not mapped to a seeded reward. | `assets/arc_raiders/operations/badges/` | Not currently reachable | `badge_early_supporter.webp` | P3 | Decide whether to map or archive. |
| `gold_power.png` | Asset exists but is not mapped to a seeded reward. | `assets/arc_raiders/operations/badges/` | Not currently reachable | `badge_gold_power.webp` | P3 | Decide whether to map or archive. |
| `og_legend_alt_1.png` | Asset exists but is not mapped to a seeded reward. | `assets/arc_raiders/operations/badges/` | Not currently reachable | `badge_og_legend_alt_1.webp` | P3 | Decide whether to map or archive. |
| `og_legend_alt_2.png` | Asset exists but is not mapped to a seeded reward. | `assets/arc_raiders/operations/badges/` | Not currently reachable | `badge_og_legend_alt_2.webp` | P3 | Decide whether to map or archive. |
| `red_trailblazer.png` | Asset exists but is not mapped to a seeded reward. | `assets/arc_raiders/operations/badges/` | Not currently reachable | `badge_red_trailblazer.webp` | P3 | Decide whether to map or archive. |
| `skull_crown_legend.png` | Asset exists but is not mapped to a seeded reward. | `assets/arc_raiders/operations/badges/` | Not currently reachable | `badge_skull_crown_legend.webp` | P3 | Decide whether to map or archive. |
| `supporter_green.png` | Asset exists but is not mapped to a seeded reward. | `assets/arc_raiders/operations/badges/` | Not currently reachable | `badge_supporter_green.webp` | P3 | Decide whether to map or archive. |
| `trailblazer.png` | Asset exists but is not mapped to a seeded reward; note `trailblazer` is also a blueprint id. | `assets/arc_raiders/operations/badges/` | Not currently reachable as badge | `badge_trailblazer.webp` | P3 | Avoid concept collision with blueprint `trailblazer`. |
| `unity_emblem.png` | Asset exists but is not mapped to a seeded reward. | `assets/arc_raiders/operations/badges/` | Not currently reachable | `badge_unity_emblem.webp` | P3 | Decide whether to map or archive. |

## Duplicate And Inconsistency Notes

- No duplicate canonical Operation reward IDs were found in `ArcOperationsSeedData.rewards`.
- No duplicate canonical Operation task IDs were found in the seeded Operation lists.
- No tracked asset filenames differing only by casing were found under `assets/`.
- `ArcCosmeticRarity.founder` and `ArcCosmeticRarity.creator` are defined, but no seeded rewards use those rarity values.
- `Founding Raider Badge` is beta-exclusive but has rarity `Common`; this is canonical source behavior, not changed here.
- Several seeded Operation tasks share a reward asset in task cards because the card displays the first reward asset, not a task-specific asset. This is expected current behavior but limits visual distinction.
- Distinct profile frames and profile banners currently share generated placeholder treatments because their reward definitions have no `assetPath`.
- Existing Command Centre operation-card images are used by Command Centre system summaries and priorities, but they are not task-specific Operation reward assets.
