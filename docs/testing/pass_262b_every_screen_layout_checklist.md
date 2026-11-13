# PASS 262B - Every-Screen Layout QA Checklist

Use this checklist after automated validation to confirm the layout migration behaves correctly on real devices and browser viewports.

## Viewports

- Android portrait: 390 x 844 or comparable emulator.
- Android landscape: 844 x 390 or comparable emulator.
- Tablet: 820 x 1180 or comparable emulator.
- Desktop/web: 1366 x 768 and one wide viewport near 1440+.

## Global Checks

- No overflow stripes or clipped text.
- No clipped banners, cards, or avatar frames.
- No nested scrolling traps.
- Primary actions remain reachable without precision scrolling.
- Desktop layouts use available width without becoming overly stretched.
- Tablet layouts do not show cramped desktop columns.
- Mobile landscape keeps core content usable above the fold.
- Empty states are intentional and not filler.
- Optional detail panels are visually secondary.
- Electric current appears only on the current actionable/selected card.

## Route Checklist

The CSV companion contains one row per reachable route and columns for the required viewport checks. Mark each row as `pass`, `fail`, or `not_applicable` during manual QA.

## Focus Routes

- Command Centre: first screen answers the next action before scrolling; systems carousel remains compact.
- ARC Raiders hub and My Hub: route compatibility remains intact and old My Hub stays accessible through the Tool Deck path.
- Progress Trackers: grouped Scrappy, Bench, Quest, and Hunt Target cards route to the existing tracker screens without layout overflow.
- Scrappy, Bench, and Quest trackers: canonical carousel is swipeable on mobile and arrowable on desktop.
- Operations and Reward Vault: preview panels and equip/claim actions remain reachable.
- Trading Hub flows: listing, offer, session, notification, and profile surfaces do not overflow on compact widths.
- Forms: onboarding, profile, trade creation, season reset, and session planner keep active actions visible.
- Legal and settings: long documents/lists stay readable at constrained widths.

## Completion

- Automated tests passed.
- Flutter analyzer passed.
- Web release build passed.
- Android debug build passed.
- `git diff --check` passed.
- No unrelated generated files included in the PASS 262B commit.

## PASS 262C Runtime Repair Log

### Command Centre

- Destination: `/trading-hub/arc-raiders/command-centre`
- Viewport tested: desktop/web automated widget harness at 1366 x 768.
- Issue found: the systems carousel could stay in mobile-width mode on desktop when rendered as a flat carousel.
- Root cause: the shared carousel tied responsive viewport fractions to `enable3d`, so flat carousels skipped tablet/web fractions.
- Fix applied: `UagPageCarousel` now applies tablet/web/mobile viewport fractions regardless of 3D transform mode.
- Automated coverage added: `flat command carousels keep responsive desktop page widths`.
- Remaining manual check: live authenticated Command Centre walkthrough on Android portrait, Android landscape, tablet, and desktop/web.

### Reviewed With No Code Repair

- Onboarding: reviewed focus/scroll architecture and retained existing active-card behavior; manual device walkthrough still required for consent progression.
- Profile & Reputation: reviewed route/layout construction; no deterministic shared blocker found in code scan.
- Favourite Loadout: reviewed responsive loadout grid usage; no repeatable shared blocker found beyond final build/test validation.
- Blueprint Tracker: protected grid internals were not modified.
- Scrappy / Bench / Quest trackers: reviewed shared carousel usage; 3D tracker mode already uses responsive fractions and focused carousel tests pass.
- Operations / Reward Vault: reviewed page-list shell usage; no safe repeatable shared blocker found in this pass.
- Trading Listings / Smart Trade / Match Rider / Raid Planner / Hunt Targets / Player Locker Pro / Admin preview tools: reviewed route construction and shared shell use; live data/manual walkthrough remains required where Firebase or entitlement state controls the route.
