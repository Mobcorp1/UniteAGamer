# PASS 301 Personalisation Contract

## Canonical Path

Personalisation is stored per user at:

`users/{uid}/personalisation/profile`

The app exposes this path through:

`ArcUserPersonalisationRepository.profilePath(uid)`

## Schema

Current schema version: `1`

Primary fields:

- `schemaVersion`: integer schema contract version.
- `completed`: whether the user has explicitly saved personalisation.
- `completedAt`: timestamp for explicit completion.
- `migratedAt`: timestamp for legacy inference/backfill.
- `updatedAt`: server timestamp for last write.
- `source`: write source such as `mandatory_onboarding`, `profile_settings` or `legacy_migration`.
- `goals`: typed `ArcPersonalisationGoal` names.
- `featureInterests`: map of `ArcPersonalisationFeature` name to `ArcPersonalisationInterestLevel`.
- `commandCentre`: density and section preference flags.
- `squadPreference`: typed solo/duo/squad/flexible preference.
- `notificationCategories`: typed canonical notification category names.
- `archetypeIds`: preserved legacy profile archetype identifiers.
- `playStyleIds`: preserved legacy play-style identifiers.
- `showFutureSystems`: controls whether future-only preferences are even considered.
- `reduceNoise`: allows neutral/success low-interest Command Centre cards to be hidden.

## Migration

`ArcUserPersonalisationRepository.migrateLegacyIfNeeded()` is safe and idempotent.

It reads existing user/onboarding fields and tracker evidence, then writes the profile document only when the document is missing or stale. It does not mark legacy users as explicitly completed. Existing users are therefore not blocked by the new contract and can later save explicit preferences from Settings.

Legacy inference uses only existing state:

- `users/{uid}.arcOnboarding`
- `users/{uid}.basicProfile`
- `users/{uid}.traderProfile`
- `users/{uid}/arc_blueprints`
- `users/{uid}/trading_activity`
- `users/{uid}/arc_scrappy_states`
- `users/{uid}/arc_quest_progress`
- `users/{uid}/arc_bench_progress`
- `users/{uid}/arc_saved_loadouts`

If a read fails, the repository logs and returns safe defaults without crashing.

## Firestore Rules

`firestore.rules` now allows owners/admin/devs to read and write:

`users/{userId}/personalisation/{docId}`

This follows existing nested user-state rules.

## Notification Categories

Canonical categories are:

- `tradeActivity`
- `listingMatches`
- `blueprintWatches`
- `favouriteRiderActivity`
- `matchRiderActivity`
- `availabilityReminders`
- `questProgress`
- `benchProgress`
- `scrappyProgress`
- `raidIntelligence`
- `systemAnnouncements`
- `futureBountyActivity`
- `futureRatRiskWarnings`

Existing device notification preferences remain authoritative. Canonical personalisation is applied only when a caller supplies the user profile to `UagNotificationDeliveryEngine`; this preserves Android and existing broadcast behaviour.
