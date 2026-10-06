# UAG Trading + Raid Intelligence Product Contract

Status: Build contract for PASS 369. This document is the project source of truth for the decisions made around Blueprint trading, sharing/referrals and goal-driven Raid Intelligence.

## 1. Blueprint market value

UAG market value is independent from Embark item rarity. It is a barter signal for the Trading Hub and Smart Trade Assist.

| UAG tier | Value points | Equivalent |
| --- | ---: | --- |
| S+ | 16 | 2 S / 4 A / 8 B / 16 C |
| S | 8 | 2 A / 4 B / 8 C |
| A | 4 | 2 B / 4 C |
| B | 2 | 2 C |
| C | 1 | Base unit |

Each Blueprint may also carry a separate gameplay tier. Gameplay tier describes the usefulness of the item; market tier describes the value of the Blueprint in player-to-player barter. These must never be collapsed into Embark rarity.

Canonical implementation:
- `models/arc_trade_value.dart`
- `data/arc_blueprint_trade_value_catalog.dart`
- `data/arc_trade_intelligence_engine.dart`

The catalog is a reviewed baseline. Smart Trade can additionally use live listing demand/supply when ranking opportunities.

## 2. HAVE • NEED • TRADE

The dedicated Blueprint trade board reads the existing Blueprint Tracker state; users do not maintain a second duplicate inventory.

Required behaviour:
- duplicates sorted highest UAG market tier first;
- quantity and total UAG value visible;
- S+/S/A/B/C filters;
- missing Blueprints shown as NEED, respecting Top 5 wanted priority before market value;
- gameplay tier shown separately when curated;
- copyable message suitable for PlayStation App, Discord, WhatsApp and other messaging surfaces;
- native share sheet available;
- share message contains useful HAVE/NEED data rather than being referral spam;
- referral attribution is attached after Refer a Raider terms are accepted;
- Smart Trade Assist remains one tap away.

Canonical implementation:
- `screens/arc_duplicate_blueprints_screen.dart`

## 3. Referral acquisition loop

The intended loop is:

Blueprint Tracker -> HAVE/NEED/TRADE -> share to known Raiders -> referral link -> new UAG user -> collection comparison/trade -> completed trade -> reward -> prompt to share updated list.

Referral subscription commission remains governed by the existing UAG referral/commercial policy. Trading must not implement a competing referral economy.

## 4. Successful trade rewards

A trading session only settles rewards when the session moves into a completed state. Settlement is server-authoritative and idempotent per trading session.

Current reward:
- +25 Trader Reputation points to each participant;
- completed trade count +1;
- successful trade streak +1;
- +1 bonus Raid Intelligence unlock, capped at 4 completed-trade Intel rewards per calendar usage month.

The bonus Intel credit is especially useful to Free users without creating a separate free-only data model. Premium remains unlimited through entitlement logic.

Trader reputation labels:
- New Trader;
- Verified Trader;
- Trusted Trader;
- Elite Trader;
- Legendary Trader.

After the second Raider completes the session, the client prompts the user to open and share the refreshed HAVE/NEED list.

## 5. Goal-driven Raid Intelligence

Default player-facing map behaviour is clean-map mode. The map is not intended to open as a wall of unrelated heatmap markers.

Raid setup inputs:
- map;
- spawn position/region (map tap is supported);
- Full / Mid / Late raid time profile;
- Standard Extraction or Raider Hatch;
- Hatch Key confirmation when using a hatch;
- route style and objective priority.

Default time budgets:
- Full: 28 minutes total;
- Mid: 17 minutes total;
- Late: 11 minutes total.

Extraction reserve:
- standard extraction: 3 minutes;
- Raider Hatch: 2 minutes.

The route engine removes the lowest-value optional stops until the planned run fits the usable route budget. The generated route can include the player's missing Blueprint opportunities plus tracker goals already produced by Quest, Scrappy and Bench intelligence. Natural-resource markers, including Apricot and Great Mullein semantics, can support relevant tracker objectives without claiming guaranteed spawns.

Manual map exploration remains available via **Explore all intel markers**. It is off by default.

## 6. Subscription layering

The quality of the primary recommended route must not be deliberately degraded for lower tiers. Monetisation is applied through usage allowance and depth of comparison.

- Free: one complete recommended route when an Intel unlock is consumed.
- Essential: primary route plus one viable alternative strategy.
- Premium: all viable Fast, Balanced, Thorough and Safer route styles.

The existing commercial economy remains the source of truth for monthly usage allowances. This pass does not create a second set of plan quotas.

The route UI should show why upgrading is useful by explaining additional viable strategies, rather than hiding the core feature behind a blank paywall.

## 7. Trials routing

Trials are a future objective source for the same routing engine, not a separate map product. The required data model is density/probability based: ARC type or container type, map/POI, cluster, confidence, interaction time and route detour cost. Trial-focused runs should give the selected Trial objective priority over incidental loot while still showing zero/low-detour opportunities.

Do not hard-code unverified live Trial densities into routing. Add them only when the underlying map/Trial evidence has been researched and versioned.

## 8. Frozen Trail / Research progression

Research Workstation, weapon amplification and new progression materials should feed the same objective/dependency engine once live recipes are confirmed. Preview material requirements must remain marked as preview evidence until verified in the live build.

## 9. Blueprint Acquisition Map Backend

Blueprint acquisition and trading value are separate signals that meet inside Raid Intelligence.

- **UAG market tier (S+/S/A/B/C)** decides which missing Blueprint is most valuable to prioritise.
- **In-game rarity, researched source family, required condition and map intel** decide where that Blueprint should be hunted.
- An exact/historical Blueprint marker outranks every fallback.
- A container/source-family marker can satisfy multiple Blueprints automatically when their canonical research profile matches that family. Event-only Blueprints may use a verified event/source marker only when the marker carries the matching event condition; they never degrade to a generic loot-zone fallback.
- A researched POI baseline outranks a generic high-value fallback.
- High-value/locked/container-cluster markers are probability fallbacks only when no stronger location/source data exists.
- Quest-only, event-only or condition-unavailable Blueprint pools must never silently degrade to a random map route.

Admin map markers can persist:
- Blueprint routing role: none / exact find / container opportunity / loot-zone fallback;
- linked Blueprint when known;
- container/source family;
- map condition/event IDs;
- loot tier;
- relevant container density (0-5);
- fallback eligibility;
- Blueprint research data version.

The Admin Map Editor pre-fills container family and condition data from the canonical Blueprint research catalogue when a Blueprint is selected. Existing First Wave Cache, Raider Cache, Security Room, Locked Room and High-Value Loot markers remain compatible through inferred routing traits.

Generated Raid Intelligence Blueprint markers continue to carry the missing Blueprint ID, so the player map uses the existing Blueprint opportunity artwork/card flow rather than rendering a generic loot pin.
