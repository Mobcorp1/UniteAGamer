# PASS 301 Navigation Matrix

## Active Home Behaviour

- Post-login entry remains `AppEntryGate`.
- Users with mandatory onboarding incomplete continue to see `ArcMandatoryOnboardingScreen`.
- Completed users continue to land on `ArcCommandCentreScreen`.
- `/my-hub` still resolves to Command Centre.
- The old Tool Deck remains accessible through `MyHubScreen.toolDeckRouteName`.

## Personalisation-Aware Drawer

`ArcCompactNavigationCatalog.groupsForPersonalisation(profile)` now ranks drawer items inside each group by saved interest level.

Access is never removed by personalisation:

- FeatureAccess remains authoritative.
- Admin controls remain authoritative.
- Subscription gates remain authoritative where already implemented.
- Dormant future systems are not added to the drawer.

## Drawer Sources

`lib/screens/build/app_drawer.dart` remains an export of:

`lib/build/app_drawer.dart`

The single implementation now watches `ArcUserPersonalisationRepository.watchProfile()`.

## User Edit Path

Settings remains the top-level destination for preferences.

`ProfileSettingsScreen` now contains:

- `ArcPersonalisationPreferencesPanel`
- `UagNotificationPreferencesPanel`

No separate top-level personalisation route was added in this pass.

## Dormant/Future Features

The master registry reserves identifiers for:

- `report_a_rat`
- `hunt_a_rat`
- `rat_radar`
- `gift_subscriptions`

They have no beta route and are always hidden by diagnostics.
