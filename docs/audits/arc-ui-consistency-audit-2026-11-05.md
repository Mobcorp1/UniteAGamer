# UAG ARC Raiders Hub — UI consistency audit and safe convergence
Date: 5 November 2026
Working branch: codex/pass33-ui-consistency-orientation-20261105
Baseline: fix/pass05-stale-test-contracts-20261102 at 64a949f2189416ee469b064f166ae20e1c0983de
Status: shared UI convergence implemented for review; NOT device- or release-certified.

## Inventory

The baseline tree contains 732 application Dart files under lib/. A path-based source inventory of 298 screen, nested-screen, widget, authentication-shell and feature-panel Dart files was checked for orientation prompts, literal colours, pop-up entry points, local scaffolds and shared-shell usage. Every qualifying file and size is captured in arc-ui-file-inventory-2026-11-05.json.

| UI ownership group | Files |
| --- | ---: |
| ARC Raiders screens | 66 |
| ARC Raiders widgets | 122 |
| Other feature screens | 27 |
| Other feature widgets | 42 |
| Shared app widgets | 27 |
| App shell and authentication | 14 |
| Total | 298 |

This is a static source audit, not a visual inspection of every runtime route, data state, pop-up and device configuration. One file can render several screens or dialogs. UI can also exist in non-UI-named support files.

## Actual architecture

- **lib/main.dart** applies AppTheme.theme and mounts ArcGlobalVisualSystem once in MaterialApp.builder above the Navigator; authentication and feature-access route gates are there as well.
- **lib/widgets/theme.dart** provides global Material 3 component themes, typography and a compatibility palette.
- **arc_ui_tokens.dart** provides canonical ARC colours, semantic states, spacing, text roles and surface roles. ArcRaidersTheme delegates to these tokens.
- **arc_layout_system.dart** and **arc_responsive_page_shell.dart** provide breakpoint policy, content widths, padding, scrolling and safe-area placement.
- **arc_raiders_screen_shell.dart** owns ARC screen composition and ad reservation; it must not render a second background.
- **arc_modal_surface.dart** and **uag_dialogs.dart** provide reusable overlay/confirmation components, but individual features still own bespoke dialogs.
- **uag_cinematic_background.dart** provides the approved shared background asset and its overlays.

**Drift mechanism:** global primitives coexist with many independently styled feature components. A global theme cannot override explicit local Container decorations, modal colours or screen-specific opaque scaffolds.

## Findings and disposition

| Priority | Finding | Disposition |
| --- | --- | --- |
| P0 | Portrait rotation prompts were duplicated in collections, Blueprint grid, live scanner and three collection camera/crop stages. Some used oversized solid scaffolds and others bare text. | **Fixed:** shared ArcOrientationPrompt provides a compact content-sized glass card. Normal routes expose the global background; camera overlays have a cinematic cover. |
| P0 | Map editing, icon review and photo import could benefit from rotation without being blocked in portrait. | **Fixed:** a non-blocking ArcLandscapeAdvisory appears in portrait only, retaining all controls. |
| P1 | Framework menus, chips, text/outlined buttons and tooltips were missing consistent global theme treatments. | **Fixed:** global Material 3 defaults added; explicit feature styles remain available. |
| P1 | ArcSystemsPageWrapper rendered a second cinematic background despite global ownership. | **Fixed:** the wrapper now retains only safe area and responsive viewport. |
| P1 | Pop-ups remain independently defined in the admin map editor, collection visual sharing, beta first run, trade sessions, and missing-item dialogs. | **Safety hold:** raw/custom dialogs require behavioural and visual acceptance before rewriting. Shared framework styling applies where no override exists. |
| P1 | Hard-coded colours are numerous in operations command, nomadic trader, trade profile, collection visual share, Blueprint drop-report sheet, onboarding and authentication. | **Safety hold:** the raw colour counts include intentional image masks, semantic status colours and artwork. Global replacements could change meaning, contrast or visuals. |
| P1 | Large bespoke grids, panels and modal workspaces have locally defined padding and radii. | **Safety hold:** coordinate-sensitive map, scanner, data grid and trading layouts must be visually tested before structural migration. |

## Safe implementation in one branch

- Added a compact orientation component and non-blocking advisory at lib/widgets/arc_orientation_prompt.dart.
- Standardised rotation in arc_collections_screen.dart and blueprint_grid_screen.dart.
- Standardised portrait camera cover in arc_blueprint_live_scanner_screen.dart.
- Standardised three portrait prompts in arc_frozen_trail_single_grid_capture_screen.dart.
- Added non-blocking portrait advisory in arc_admin_map_editor_screen.dart, arc_map_filter_icon_review_screen.dart and arc_blueprint_photo_capture_screen.dart.
- Extended lib/widgets/theme.dart to centralise five framework component families.
- Removed redundant backdrop from arc_systems_page_wrapper.dart.
- Added test/arc_ui_consistency_orientation_pass33_test.dart for compact sizes, camera background, orientation changes, component adoption, theme coverage and background ownership.

**Protected behaviour:** Blueprint grid order, _buildGrid, BlueprintTile, ownership, duplicate/acquisition logic, Favourite Loadout layout, camera capture algorithms, Firebase models, auth/entitlement gates and ad-tier logic are not deliberately altered.

## Acceptance checklist

1. Run Dart formatting, flutter analyze and PASS 33 tests; also run current Blueprint, Favourite Loadout, onboarding, responsive, ads, scanner and theme regression suites.
2. Inspect 320x568, 390x844, 568x320, 844x390, 1280x720 and desktop widths, including text scaling, notches, pop-ups, keyboard, scrolling and back navigation.
3. On Sony/Android test all rotation transitions in Blueprint Tracker, Collections, Scanner, collection camera/crop, and the non-blocking map/photo hints.
4. Verify the global cinematic background is visible once, no ad space changes, no clipping, and locked layouts match reference screenshots.
5. Do not deploy or merge until CI and on-device checks pass.

**Certification limit:** Flutter/Dart tooling and Sony hardware are unavailable in this execution environment. No compile, runtime screenshot, on-device acceptance or release certification is claimed. Bulk changes to all bespoke screens and pop-ups are intentionally withheld as unsafe without those checks.
