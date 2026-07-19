# PASS 262B - Every-Screen Layout Manifest

PASS 262B converts the screen manifest from a file-level scan into a route-level layout audit. The CSV companion is the source of truth for each reachable user/admin destination and records its responsive status, carousel treatment, electric action state, and any controlled exception.

## Scope

- Total reachable full-screen destinations tracked: 59
- Migrated destinations: 59
- Blocked destinations: 0
- Admin-visible destinations tracked: 1
- Compatibility routes retained: 4
- Controlled carousel/protected-layout exceptions: 5

## Screen Archetypes

- Authentication / Entry / Loading / Error: root gate, auth landing, sign-in, legal documents, biometric relock.
- Dashboard / Command Screens: Home aliases, ARC Raiders hub, Command Centre, Match Rider, Raid Planner, Trader Hub.
- Catalogue / Grid Screens: UAG plans, Blueprint Grid, Favourite Loadout, Nomadic Trader.
- Tracker / Progression Screens: Scrappy, Bench, Quest, Play Like a Pro, Hunt Targets.
- List / Detail Screens: intel, help, trade listings, activity, offers, sessions, notifications, feedback.
- Form / Setup: onboarding, profile setup/edit, availability, away, trade creation, season reset, session planner.
- Reward / Operations Surfaces: Operations and embedded Reward Vault.
- Profile / Settings / Admin: monetisation, trading profile, profile settings, admin console.

## Controlled Exceptions

- `/auth-landing`: keeps the existing landing carousel animation while staying bounded by the global screen shell.
- `/trading-hub/arc-raiders`: keeps the branded ARC hub carousel treatment.
- `/my-hub`: remains route-compatible while surfacing Command Centre and preserving the Tool Deck path.
- `/trading-hub/arc-raiders/nomadic-trader`: keeps the trader purchase carousel because it is part of the buying flow.
- `/trading-hub/arc-raiders/blueprints`: Blueprint Grid internals remain protected. PASS 262B only records the shell/layout state.

## Validation Rules

- No reachable screen should use unbounded desktop-width content.
- Long single-column mobile flows must keep their current behavior but remain constrained on tablet and desktop.
- Carousels should use `UagPageCarousel` unless a controlled route-specific interaction is documented.
- Electric current should appear only on the single active or selected action surface.
- Protected systems remain unchanged: Blueprint Grid rendering, BlueprintTile, ownership writes, duplicate writes, `_buildGrid`, and carousel behavior outside the explicit shared-carousel migration.

## Files

- Route source of truth: `docs/design/global_layout_screen_manifest.csv`
- Manual QA checklist: `docs/testing/pass_262b_every_screen_layout_checklist.md`
- Checklist CSV: `docs/testing/pass_262b_every_screen_layout_checklist.csv`

## PASS 262C Runtime Repair Log

### Command Centre Systems Carousel

- Destination: `/trading-hub/arc-raiders/command-centre`
- Viewport tested: automated desktop/web harness at 1366 x 768 with a 1000 px carousel stage.
- Issue found: flat/non-3D carousels used the mobile `viewportFraction` on desktop, so the Command Centre systems deck could show oversized mobile-width cards on web.
- Root cause: `UagPageCarousel._effectiveViewportFraction` returned `viewportFraction` whenever `enable3d` was false.
- Fix applied: responsive viewport fraction selection now runs independently from the 3D transform mode; `enable3d` only controls page transforms.
- Automated coverage added: `flat command carousels keep responsive desktop page widths` in `test/arc_every_screen_layout_migration_test.dart`.
- Remaining manual check: authenticated Command Centre route walkthrough on Android portrait, Android landscape, tablet, and desktop/web to verify live data card density and tap targets.
