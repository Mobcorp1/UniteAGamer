# PASS 302 Beta Sandbox

## Objective

Closed beta users can now discover future systems without launching unfinished functionality.

The beta sandbox is centered on:

- feature state
- personalisation interest
- safe navigation
- Command Centre recommendations
- admin release controls

## User Experience

Live:

- feature appears normally
- route launches normally
- Command Centre may recommend it through existing intelligence

Coming Soon:

- feature can remain visible
- user can express interest through PASS 301 personalisation
- Drawer and route gates open a reusable Coming Soon screen
- Command Centre can surface a status card when the user has high interest
- no dead buttons or placeholder exceptions

Hidden:

- feature is removed from standard Drawer navigation after availability resolves
- admin/dev users retain live access through existing overrides

## Reusable Coming Soon Screen

Implemented in:

`lib/features/feature_access_gate.dart`

The screen includes:

- UAG artwork
- feature title
- closed beta status
- description
- purpose copy where provided
- benefits list
- notify action explaining that interest is managed through Personalisation and Settings

No release dates are invented.

## Command Centre Integration

`ArcCommandCentreEngine` now accepts:

`Map<String, FeatureAvailability> featureAvailability`

The engine adds up to three Coming Soon recommendations when:

- the feature has an access flag
- the feature is Coming Soon
- PASS 301 personalisation says the user has high/primary interest

The action uses `ArcCommandActionIntent.comingSoon` and opens the reusable Coming Soon screen.

## Personalisation

PASS 301 personalisation remains authoritative.

No personalisation model rewrite was performed.

Users may still choose future systems through the existing interest model. Dormant future-only identifiers remain protected by the existing `showFutureSystems` behavior.

## Admin Controls

Admin Console feature release state now supports:

- Live
- Coming Soon
- Hidden

Existing admin permission behavior was not changed.

## Deferred Work

The client now writes deduped notification intents for Coming Soon to Live transitions. A server-side processor or Cloud Function should consume `feature_live_notification_intents` and fan out notifications to users who expressed interest.

No broad onboarding redesign was performed in PASS 302. Coming Soon state is compatible with PASS 301 personalisation and navigation; deeper onboarding copy polish can be handled separately.

