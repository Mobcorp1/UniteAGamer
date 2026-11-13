# PASS 303 - Responsive Polish Audit

## Scope

This pass fixed responsive issues only where they were tied to closed-beta route or feature-state presentation. It did not redesign screens or alter tracker internals.

## Repairs

| Area | Viewports considered | Issue | Fix |
| --- | --- | --- | --- |
| Progress Trackers hub | 320, 360, 390, 412, 600, 768, 1024, 1440 | Static cards could expose hidden systems and force dead navigation. | Replaced static card list with availability-aware Wrap layout, Coming Soon status pills, and responsive empty state. |
| Progress Tracker cards | Mobile portrait and landscape | Long tracker subtitles and status labels needed safe wrapping. | Existing flexible Row/Expanded layout retained; status pill is constrained and secondary. |
| Admin diagnostics | Tablet and desktop/web | Long diagnostics list lacked a top-level beta summary and could require scanning every card. | Added compact summary pills, core journey status pills and warning rows above the existing responsive tile Wrap. |
| Coming Soon screen | Mobile and web | `Notify Me` wording implied a stronger action than currently implemented. | Changed copy to `Register Interest` and clarified Personalisation/Settings handoff. |

## Reviewed With No Code Change

- Blueprint grid: protected; no rendering, ownership, duplicate, zoom or carousel code changed.
- Scrappy/Bench/Quest tracker detail screens: protected progression logic; route gating only changed which feature flag opens each route.
- Command Centre layout: no new large cards or sections added; only recommendation dedupe changed.
- Auth/onboarding/profile layouts: no deterministic shared code blocker was changed in this pass; manual QA checklist added.

## Manual Responsive QA Required

- Android portrait: onboarding, consent, Command Centre, Progress Trackers, Blueprint Tracker, Bench, Scrappy and Feedback.
- Android landscape: onboarding action reachability, Progress Trackers Wrap layout, Blueprint controls and tracker carousels.
- Tablet: Command Centre summary density, diagnostics summary wrap, tracker card widths.
- Desktop/web: route gating from direct URL/name navigation, drawer visibility, diagnostics summary and Coming Soon back navigation.
