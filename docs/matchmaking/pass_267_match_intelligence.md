# PASS 267 Match Intelligence

## Current Flow Audit

- `ArcMatchRiderScreen` loads the current user profile through `ArcMatchRiderRepository`, saves the public Match Rider profile, and renders live candidate cards plus incoming/outgoing invites.
- `ArcMatchCompatibilityEngine` is the existing single match engine. PASS 267 extends it rather than creating a parallel matcher.
- Candidate data is read from `arc_match_rider_profiles` where `visibleInSearch == true`.
- Entitlement state is read from `users/{uid}` through the existing monetisation entitlement service/model.
- Favourite Rider relationship state is read from `arc_favourite_riders` and now feeds ranking where the user's tier allows that signal.
- Public candidate cards now render only score percentage, public label, tier badge, confidence label, and broad tags.

## Scoring Architecture

The engine now returns:

- overall match percentage;
- tier used for calculation;
- confidence level;
- internal scoring breakdown;
- internal reasons for tests/debugging;
- public-safe tags;
- exclusion reasons;
- deterministic ranking metadata.

Internal factor categories are:

- core profile fit;
- availability;
- communication;
- squad intent;
- archetype fit;
- reputation and reliability;
- Favourite Rider/prior relationship;
- progression fit;
- map and event preference fit;
- hidden blueprint complementarity;
- hidden competition penalty;
- incomplete-profile penalty.

## Tier Behaviour

- Free uses Basic Match Intelligence: core profile, platform, region, broad availability, broad play preference, and reputation safety.
- Essential uses Enhanced Match Intelligence: Basic plus communication, squad intent, archetype fit, social readiness, stronger reliability, and Favourite Rider priority.
- Premium uses Advanced Match Intelligence: Enhanced plus private progression fit, map/event preferences, trade/progression signals, hidden blueprint complementarity, competition reduction, and dynamic reranking.
- Admin/dev bypass maps to Advanced for internal testing.

## Exclusions And Fallbacks

The engine excludes or suppresses:

- blocked Match Rider IDs when a `blockedMatchRiderUids` list exists on the user document;
- hidden profiles;
- incompatible platform preferences;
- unsafe reputation threshold matches.

Incomplete profiles still receive a safe score, but confidence drops. Stale profiles reduce rank and confidence without revealing why to another player.

## Public-Safe Output

The public card output is limited to:

- percentage;
- `Strong fit`, `Good fit`, `Compatible`, or `Worth a look`;
- `Basic Match Intelligence`, `Enhanced Match Intelligence`, or `Advanced Match Intelligence`;
- confidence label;
- broad tags such as `Similar schedule`, `Compatible play style`, and `Good squad balance`;
- the privacy-safe explanation: `Your score is based on compatibility signals from your profile, availability and activity.`

Private blueprint IDs, internal weights, internal reasons, exact inventory state, and factor-by-factor breakdowns are not rendered to users.

## Manual QA

- Verify Match Rider on Android portrait, Android landscape, tablet, desktop, and web.
- Verify plan changes recompute Match Rider scores without an app restart.
- Verify public profile saves delete legacy private fields from `arc_match_rider_profiles`.
- Verify Favourite Rider changes reorder entitled feeds.
- Verify hidden and unsafe users do not appear in the feed.

## Deferred

- No visual admin editor was added because no existing admin tuning surface was suitable. The engine now has a typed `ArcMatchIntelligenceConfig` with documented defaults for future admin wiring.
- Three-player complementarity is only supported where future squad-ranking data provides enough private inputs. This pass implements two-player one-way and mutual complementarity safely.
