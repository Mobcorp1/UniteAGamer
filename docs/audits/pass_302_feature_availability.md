# PASS 302 Feature Availability Audit

## Scope

PASS 302 replaces simple enabled/disabled launch gating with a compatible three-state beta availability model.

States:

- `Live`: visible and launchable.
- `Coming Soon`: visible, described, selectable as an interest, not launchable.
- `Hidden`: invisible to standard users and available only to admin/dev overrides.

## Storage

Existing boolean fields remain compatible.

Example legacy field:

`raidPlannerEnabled`

New availability field:

`raidPlannerAvailability`

Accepted storage values:

- `live`
- `comingSoon`
- `hidden`

Compatibility rule:

- explicit `*Availability` wins
- legacy `*Enabled == true` maps to `Live`
- legacy `*Enabled == false` maps to `Hidden`
- missing state maps to `Hidden`

## Runtime Access

Updated access layer:

`lib/features/feature_access_gate.dart`

New helpers:

- `FeatureAccess.getAvailability`
- `FeatureAccess.watchAvailability`
- `FeatureAccess.watchAvailabilityMap`
- `FeatureAccess.availabilityFromConfigData`
- `FeatureAccess.updatePayloadForAvailability`

Existing `hasAccess` and `watchFlag` remain available and return `true` only for `Live`.

## Navigation

Updated launch behavior:

- Drawer launches live routes.
- Drawer opens `FeatureComingSoonScreen` for Coming Soon entries.
- Drawer hides Hidden entries once feature availability resolves.
- Route gates render `FeatureComingSoonScreen` for Coming Soon routes.
- Hidden route gates render a locked/unavailable surface.
- Legacy My Hub / Tool Deck entry points open Coming Soon instead of placeholder exceptions.

## Admin Console

Both admin console copies were kept in sync:

- `lib/screens/admin_console_screen.dart`
- `lib/screens/build/admin_console_screen.dart`

Feature switches are now dropdown controls with:

- Live
- Coming Soon
- Hidden

Admin writes update both:

- legacy boolean field
- new availability field

## Notification Handoff

When an admin changes a feature from `Coming Soon` to `Live`, the admin console writes a deduped intent document:

`feature_live_notification_intents/{featureKey}`

Fields:

- `featureKey`
- `featureTitle`
- `message`
- `dedupeKey`
- `status`
- `createdAt`
- `updatedAt`

This avoids duplicate notification intents. Delivery to interested users still depends on the notification processor consuming these intents.

## Diagnostics

Feature visibility diagnostics now display the availability label instead of collapsing Coming Soon into Hidden.

## Tests

Coverage added:

- explicit availability fields override legacy booleans
- compatibility payload writes both fields
- Coming Soon to Live transition detection
- stable notification dedupe key
- Command Centre Coming Soon recommendation action

