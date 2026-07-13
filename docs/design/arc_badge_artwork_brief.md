# ARC Badge And Identity Artwork Brief

Generated from commit: `d86bc796e2fc7cbde9ae46a47da6ac319f017516`

Use only the canonical names and identifiers below. Do not rename rewards, archetypes or Operations.

## Export Requirements

| Asset kind | Preferred format | Suggested size | Notes |
| --- | --- | --- | --- |
| Badge | `.webp` for new production art | 1024 x 1024 source, export 512 x 512 and 256 x 256 | Existing seeded badge files are `.png`; future production exports should move toward `.webp` when implementation updates asset paths. |
| Archetype icon | `.webp` | 1024 x 1024 source, export 512 x 512 and 256 x 256 | Must remain readable at small Match Rider/profile chip sizes. |
| Profile frame | `.webp` with transparency if supported by final pipeline, otherwise `.png` | 1024 x 1024 source, export 512 x 512 | Needs avatar-safe center clearance. |
| Profile banner | `.webp` | 1600 x 600 source, export 1200 x 450 and 800 x 300 | Must not rely on details at extreme edges. |
| Operation/Command card | `.webp` | 1440 x 1800 source | Existing hub README recommends keeping important detail away from bottom third. |

## Archetypes

Canonical entries: Balanced Raider, Quest-driven Raider, Blueprint Grinder, Helper / Support Player, Trader / Resource Runner, PvP Hunter, Rat Hunter, Casual Squad Player.

Functional purpose: selectable match-fit identity in onboarding, profile setup/edit, Match Rider and trader profile.

Required visual distinction: each archetype needs a unique icon subject, not only a color change.

Selectable or earned: selectable identity.

Recommended shared silhouette: circular or shield-like identity emblem with a consistent outer ring.

Recommended icon subjects:
- Balanced Raider: compass/route star.
- Quest-driven Raider: flag/objective marker.
- Blueprint Grinder: document/blueprint sheet.
- Helper / Support Player: support hand or rescue cross motif.
- Trader / Resource Runner: handshake/crate route.
- PvP Hunter: flame/target sight.
- Rat Hunter: radar sweep/hidden threat mark.
- Casual Squad Player: group/low-pressure squad mark.

Required variants: active, inactive/locked-tone, small chip.

Current UI locations: onboarding profile step, profile setup/edit, trading profile, Match Rider cards.

## Operations

Canonical entries: First Contact, Open The Market, Trade Pioneer, Verified Intel, Squad Signal, Personal Build Online, Field Tester, Guardian Run, Closed Beta Veteran, Keep The Market Alive, Update Availability, Confirm Intel, Market Operator, Intel Network, Build Progress, Trader Bronze, Guardian Detail, First Trade, Trader I, Guardian, Recruitment Cell.

Functional purpose: actionable Operations cards and reward unlock tracks.

Required visual distinction: Operations with no badge reward currently fall back to a generic military-tech icon in the Operations screen. These need task-level art if Operation cards should visually distinguish every objective.

Selectable or earned: earned achievement/progression objective.

Recommended shared silhouette: rectangular mission patch or command-card illustration.

Recommended icon subjects:
- First Contact: signal handshake/profile beacon.
- Open The Market: opening stall/trade terminal.
- Squad Signal: squad beacon.
- Field Tester: diagnostic clipboard.
- Keep The Market Alive: active listing pulse.
- Update Availability: calendar/radio window.
- Confirm Intel / Intel Network: verified signal stamp.
- Build Progress / Personal Build Online: weapon/loadout assembly.
- Recruitment Cell: connected node cluster.

Required variants: normal, ready-to-claim, completed.

Current UI locations: Operations Command screen, Command Centre system summaries and priority visuals.

## Trading

Canonical entries: Trade Pioneer Badge, +1 Extra Trade Slot, Open The Market, Market Operator, Trader Bronze, First Trade, Trader I.

Functional purpose: visible marketplace progression and trust signaling.

Required visual distinction: Trade Pioneer Badge already has `pathfinder.png`; Extra Trade Slot has no art.

Selectable or earned: earned achievement/reward.

Recommended shared silhouette: market stamp, trade-arrow token, or route badge.

Recommended icon subject: crossed trade arrows, exchange terminal, marked route.

Required variants: badge, slot token, Operation card.

Current UI locations: Reward Vault, Operations, profile/trading identity strips when equipped.

## Reputation

Canonical entries: TradingProfile risk labels Low Risk, Moderate Risk, Caution; foundingTrader flag; completed trade counters; no-show and betrayal flags.

Functional purpose: communicate trader reliability.

Required visual distinction: reputation indicators should not look like earned cosmetic badges unless they are claimable rewards.

Selectable or earned: system status, not a selectable cosmetic.

Recommended shared silhouette: compact trust meter or shield/status chip.

Recommended icon subject: verified shield, caution triangle, neutral meter.

Required variants: low risk, moderate risk, caution, founding trader.

Current UI locations: trading listings, trader profile, identity panels.

## Intel

Canonical entries: Intel Officer Badge, +5 Intel XP, +10 Intel XP, +25 Intel XP, Verified Intel, Confirm Intel, Intel Network.

Functional purpose: reward verified community intelligence and blueprint reporting.

Required visual distinction: Intel Officer Badge uses `golden_pathfinder.png`; Intel XP values currently have no unique art.

Selectable or earned: earned reward/status.

Recommended shared silhouette: scanner/verified-data seal.

Recommended icon subject: radar node, verified document, signal waveform.

Required variants: badge, XP token, operation card.

Current UI locations: Reward Vault, Operations, Command Centre intel objectives.

## Guardian

Canonical entries: Community Raider Badge, Guardian Signal Frame, Guardian Banner, Guardian Run, Guardian Detail, Guardian.

Functional purpose: reward helping other players and positive community behavior.

Required visual distinction: frame and banner currently share generated placeholders; they need unique Guardian-themed art.

Selectable or earned: earned achievement/cosmetic.

Recommended shared silhouette: protective signal, shield, rescue marker.

Recommended icon subject: shielded signal, hand/support mark, community beacon.

Required variants: badge, profile frame, profile banner, Operation card.

Current UI locations: Reward Vault, profile, trading identity strips, Operations.

## Founder

Canonical entries: Founding Raider Badge, UAG Inner Circle Badge. `ArcCosmeticRarity.founder` exists but no seeded reward currently uses that rarity.

Functional purpose: permanent early supporter/founder identity.

Required visual distinction: should feel more permanent and prestige-oriented than generic beta participation.

Selectable or earned: earned achievement/cosmetic.

Recommended shared silhouette: founder seal or command insignia.

Recommended icon subject: original signal, core emblem, inner-circle ring.

Required variants: badge and possible future title/frame/banner.

Current UI locations: Reward Vault, profile and trading identity strips when equipped.

## Closed Beta

Canonical entries: Beta Access Badge, Field Tester Title, Beta Signal Frame, Beta Command Banner, OG Legend Badge, Closed Beta Veteran, Field Tester, First Contact.

Functional purpose: beta-only identity, testing status and early participation.

Required visual distinction: Closed Beta cosmetics should read as time-limited and signal/testing oriented.

Selectable or earned: earned achievement/cosmetic.

Recommended shared silhouette: beta signal burst or sealed test patch.

Recommended icon subject: beacon, diagnostic pulse, test stamp.

Required variants: badge, title treatment, frame, banner, Operation card.

Current UI locations: Reward Vault, Operations, Command Centre, profile/trading identity strips when equipped.

## Community

Canonical entries: Community Raider Badge, Guardian Signal Frame, Guardian Banner, Guardian Run, Guardian Detail, Guardian.

Functional purpose: positive player contribution and community support.

Required visual distinction: should not duplicate closed-beta or trading visuals.

Selectable or earned: earned achievement/cosmetic.

Recommended shared silhouette: community heart/signal crest.

Recommended icon subject: connected players, heart/signal, support ring.

Required variants: badge, frame, banner.

Current UI locations: Reward Vault, Operations, profile/trading identity.

## Creator And Partner

Canonical entries: no seeded creator or partner rewards found. `ArcCosmeticRarity.creator` exists in `ArcCosmeticRarity`.

Functional purpose: reserved future rarity tier.

Required visual distinction: unavailable until production definitions exist.

Selectable or earned: not currently reachable.

Recommended shared silhouette: not defined by current app data.

Recommended icon subject: not defined by current app data.

Required variants: not defined.

Current UI locations: none found.

## Milestones

Canonical entries: First Trade, Trader I, Guardian, Recruitment Cell, Closed Beta Veteran.

Functional purpose: long-term lifetime achievements and status.

Required visual distinction: milestone badges should feel permanent and cumulative.

Selectable or earned: earned achievement.

Recommended shared silhouette: medal/rank patch.

Recommended icon subject: tally marks, rank bars, linked nodes.

Required variants: badge and Operation card.

Current UI locations: Lifetime Operations tab and Reward Vault when rewards are claimed.

## Reward Vault Cosmetics

Canonical entries: Beta Access Badge, Founding Raider Badge, Field Tester Title, Beta Signal Frame, Guardian Signal Frame, Beta Command Banner, Guardian Banner, Trade Pioneer Badge, Intel Officer Badge, Community Raider Badge, OG Legend Badge, UAG Inner Circle Badge.

Functional purpose: earned cosmetics that can be previewed and equipped. Equipped IDs persist through `arc_equipped_cosmetics` and profile/trading surfaces consume the same state.

Required visual distinction: badges have unique asset paths; title, frames and banners need production artwork/treatment.

Selectable or earned: earned and equippable cosmetics.

Recommended shared silhouette:
- Badges: circular/square medal badge.
- Titles: wordmark plaque.
- Frames: avatar ring/frame.
- Banners: wide header strip.

Recommended icon subject: derive from canonical reward name and unlock source.

Required variants: locked preview, owned, selected, equipped.

Current UI locations: Operations Command Reward Vault, profile header, trading identity strips and listing/session surfaces.
