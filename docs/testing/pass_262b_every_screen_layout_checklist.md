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
