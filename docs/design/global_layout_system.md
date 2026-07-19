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
