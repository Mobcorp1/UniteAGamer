# PASS 301 Feature Health Audit

## Executive Summary

PASS 301 adds a canonical personalisation layer and connects it to onboarding, Command Centre relevance, navigation ordering, notification category mapping and admin diagnostics.

Closed-beta behaviour is preserved: users are not blocked by migration, existing feature gates remain authoritative, and no dormant Rat/Bounty surface becomes functional.

## Feature Registry Status

Canonical registry:

`lib/features/trading_hub/arc_raiders/data/arc_feature_registry.dart`

Ready or beta-routable systems:

- Command Centre
- Tool Deck
- Settings
- Communications Centre
- Blueprint Tracker
- Favourite Loadout
- Progress Trackers
- Trading Hub
- Smart Trade Assist
- Match Rider
- Raid Planner
- Hunt Targets
- Raid Intelligence
- Operations and Reward Vault

Foundational systems:

- Player Locker Pro
- Voice Assistant

Dormant future identifiers:

- Report A Rat
- Hunt A Rat
- Rat Radar
- Gift Subscriptions

## Admin Diagnostics

The Admin Console now includes `ArcFeatureVisibilityDiagnosticsPanel`, showing:

- feature label and lifecycle;
- FeatureAccess flag where present;
- admin control flag where present;
- saved personalisation interest;
- final visible/hidden state;
- reason.

Both admin console source copies were updated.

## Onboarding

Mandatory onboarding now saves an explicit personalisation profile before setting `arcMandatoryOnboardingComplete`.

Captured preferences:

- primary goals;
- Command Centre density;
- squad preference;
- canonical notification categories.

Existing profile, availability, blueprint, loadout and trade setup actions remain unchanged.

## Command Centre

Command Centre now watches the personalisation document and uses it to rank view state. Critical blockers stay visible regardless of preferences.

## Notifications

The new canonical mapper sits on top of existing device notification preferences. Existing Android/web delivery behaviour is unchanged unless a caller explicitly passes the personalisation profile.

## Risks

- Some Command Centre fixed summary panels are not fully collection-based, so they are not completely reorderable yet.
- Personalisation diagnostics currently reads current-user access rather than simulating another target user.
- Additional onboarding fields such as advanced communication style can be expanded later without changing the schema path.
