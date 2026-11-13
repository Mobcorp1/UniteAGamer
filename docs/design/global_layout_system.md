# PASS 262A — Global Layout System

PASS 262A consolidates page sizing, responsive breakpoints, padding, cards, grids, state panels, action surfaces, and carousel navigation into shared widgets.

## Shared sources

- `lib/widgets/arc_layout_system.dart`
- `lib/widgets/arc_responsive_page_shell.dart`
- `lib/widgets/responsive_layout_helper.dart`
- `lib/widgets/arc_responsive_chrome.dart`
- `lib/widgets/uag_page_carousel.dart`
- `lib/widgets/theme.dart`

## Application-wide effect

The application theme now owns consistent cards, dialogs, sheets, list tiles, dividers, navigation, snackbars, and progress indicators. Existing screens using Material components inherit the same visual treatment without duplicating screen-specific values.

Shared page shells now use the same maximum widths, page padding, safe-area handling, dock/ad clearance, and scroll behaviour. Existing screens already using these shells inherit the new layout rules.

Carousels now retain mobile swipe behaviour and add shared desktop previous/next controls.

## Rules

- Feature logic is unchanged.
- Blueprint ordering and ownership behaviour are unchanged.
- The global Blueprint Grid background remains the canonical backdrop.
- Electric current remains reserved for the single active/actionable element.
- New screens should use `ArcPageViewport`, `ArcPageHeader`, `ArcSection`, `ArcAdaptiveGrid`, `ArcActionSurface`, and `ArcStatePanel` rather than adding local layout constants.

## PASS 262B migration notes

PASS 262B extends the shared system into route-level screen migration:

- `ArcRaidersResponsiveContent` and `ArcRaidersPageList` now default to `ArcLayoutTokens.pagePadding(context)` while preserving explicit caller padding.
- `ArcSystemsPageWrapper` uses the shared global ARC background and `ArcPageViewport` width constraints.
- `ArcResponsiveSplitPane` provides reusable desktop two-column / compact stacked composition for command-style screens.
- `ArcFormGrid` provides a standard two-column adaptive form field layout.
- Command Centre and Scrappy tracker carousels now use `UagPageCarousel` where their layouts can safely share the canonical carousel.

The route-level manifest is maintained in `docs/design/global_layout_screen_manifest.csv`.

## PASS 262C runtime note

`UagPageCarousel` responsive viewport fractions are independent from `enable3d`. Flat carousels, such as the Command Centre systems deck, must still honor mobile, tablet, and desktop page widths; `enable3d` only controls the transform treatment.
