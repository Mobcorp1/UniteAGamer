# Events / Command Centre relevance

Starting checkout: `ai/codex-events-personalisation`, `6dbed95912a4`.

## Source audit and boundaries

- C2 Command Centre uses `ArcCommandCentreContent` and its existing responsive
  layout policy. Its priority deck and systems controls remain intact. An
  optional two-row event preview sits between the priority deck and utilities.
- PASS A/A2 already persist goals, feature interests, Raider stage, Blueprint
  ownership context, quest context, and reduce-noise preference in
  `ArcUserPersonalisationProfile`. Events reads this profile without migration
  or persistence changes. Stage alone is not evidence of an event reward.
- `RaidPlannerEventSchedule.slots` remains the standard schedule authority.
  Slot methods own UTC occurrence calculations. The bundled schedule is labelled
  with its existing MetaForge seed date, 27 April 2026, and is not live verified.
- `ArcRegionalMapConditionsService` remains the official regional authority.
  Its captured fallback is not treated as live. Refresh failures retain a prior
  live snapshot when available; expired windows are excluded and stale retained
  windows are labelled unverified. No second fetch/parser or schedule is added.
- `ArcRegionalOpportunityEngine` owns the reused Blueprint and material rules.
  Rule confidence is shown separately from schedule provenance. No reward,
  trading-price, or supply/demand connections are invented.
- Blueprint ownership and priority rank are read only. Saved loadout weapons and
  attachments match existing Blueprint labels; game-accuracy rules are unchanged.
- `ArcProgressionEngine` provides active quest and next upgrade context. Known
  active quest incomplete objectives can match existing material rules or an
  explicit map in the source hint. A map match is labelled **map context only**.
  Bench/Scrappy seed definitions support upgrade context, not claims about exact
  missing per-item counts. Their persistence and collected-count semantics are
  unchanged.
- Existing Community Intel remains a separate destination at `/market`.
  Community reports never overwrite official timing or become official evidence.
- Events gets a route, compact navigation entry and feature registry entry.
  It inherits Raid Planner's existing access/availability flag. The Command Centre
  preview is exposed only when that flag is live. No new admin flag is required.
- Operations Command's UAG missions/rewards, Hunt Targets, map calibration,
  global avatar/profile convergence and account deletion are untouched.

## Ranking policy

Current events come first. Within current/upcoming groups, a saved-loadout or
priority Blueprint link outranks a generic missing Blueprint link. Known active
quest/material links and explicit map context also contribute. Raid/operations
preferences give general schedule relevance without a reward claim. Ties are
chronological and deterministic. Existing high/primary feature preferences
select the relevant goal families.

No personalisation, Explore Everything, disabled noise reduction, and Show all
use chronological ordering. All events remain accessible; each unknown match
says “No confirmed link to your goals”. The compact preview is capped at two
events; full Events provides search, current/upcoming groups and regional selection.
No unsupported saved-event or notification actions are introduced.

## Metadata gaps

- Many quest hints describe container types without a map or event. These cannot
  support a specific event boost. Onboarding stage/quest context alone is not a
  substitute for a known active objective.
- There is no authoritative event-to-trading-market relationship to rank.
- Standard schedule freshness remains the freshness of the existing bundled
  seed. Updating that data is a separate authority task.
- Existing personalisation repository streams suppress errors internally; Events
  can display loading/retained context but cannot recover an error that upstream
  does not emit. Other emitted source failures are surfaced with retained-data
  notices. This pass does not alter repository contracts.

No Firebase deployment, index, rules, dependency or signing changes are required.

## Exact task files

```text
docs/EVENTS_PERSONALISATION_AUDIT.md
lib/main.dart
lib/features/trading_hub/arc_raiders/data/arc_compact_navigation_catalog.dart
lib/features/trading_hub/arc_raiders/data/arc_event_relevance.dart
lib/features/trading_hub/arc_raiders/data/arc_feature_registry.dart
lib/features/trading_hub/arc_raiders/screens/arc_command_centre_screen.dart
lib/features/trading_hub/arc_raiders/screens/arc_events_screen.dart
lib/features/trading_hub/arc_raiders/widgets/arc_events_workspace.dart
lib/features/trading_hub/arc_raiders/widgets/command_centre/arc_command_centre_content.dart
test/arc_command_centre_mobile_render_smoke_test.dart
test/arc_compact_navigation_catalog_test.dart
test/arc_event_relevance_test.dart
test/arc_events_workspace_test.dart
```

## Validation

- Touched Dart files formatted; working diff whitespace check passed.
- Ranking tests cover unknown/no preferences, Blueprint priorities and ownership,
  known quest map context, unknown quest context, raid, trading, Show all,
  Explore Everything, current/end boundaries and empty schedules.
- Events widget tests cover loading, failure, retry, captured and retained stale
  data; full workspace and two-row preview at 320x640, 430x932, 640x360,
  844x390, 768x1024, 1024x768 and 1280x900. All 16 passed.
- Command Centre mobile render test includes the new preview; existing C2
  convergence checks remain intact.
- Full `flutter test --no-pub --reporter expanded`: **1,171 passed**. The first
  full run identified the exact navigation-list expectation, which was updated
  to include Events and assert its existing Raid Planner access flag.
- `flutter analyze --no-pub`: no issues.
- `flutter build web --release --no-wasm-dry-run --no-pub`: passed.
- `flutter build apk --debug --no-pub`: passed; existing dependency Java
  source/target-8 and deprecated/unchecked API warnings were emitted.
