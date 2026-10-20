# PASS 14 — UAG ARC Visual Convergence (closed-beta)

## Source of truth
- Brand cyan `AppTheme.neonCyan` / `ArcUiTokens.primaryAccent` = #19E6F2.
- Brand pink `AppTheme.neonPink` / `ArcUiTokens.secondaryAccent` = #FF3B8D.
- Background `AppTheme.darkBackground` = #03060A.
- Dark modal `AppTheme.cardBackgroundDeep` = #071016.
- Headings use approved AppTheme typography. No substitute blues or pinks in duplicate states.

## Scope and preservation
PASS14 installs cross-app Material defaults (buttons, dialogs, menus, tooltips,
chips), makes local Flutter alert dialogs/sheets/menus dark where no explicit
surface is already selected, and unifies the known Stencils/Designs/Blueprint
collection duplicate accents. The source audit inventories **all** lib Dart
files, including screens, modal call sites, literal colours, alternate
MaterialApp/ThemeData and native/special modal call sites.

No business logic, persistence, scanner save operations, Firebase backend,
monetisation entitlement, advertising, collection slot order, protected
`_buildGrid`, `BlueprintTile`, BlueprintGridScreen or FavouriteLoadoutScreen
is edited. Existing explicit surface colours are preserved and reported as
review exceptions; they are **not** silently overwritten.

## Not a claim of visual perfection
Static codemods cannot visually verify every active screen, custom-painted
component, third-party popup, or test-device accessibility scenario. The
installer writes `plan.json` and `verified_ui_inventory.json`; the manual-review
flags in the latter are intentional QA debt. It is a release blocker to claim
full visual acceptance until the live route/modal matrix is reviewed on Android
and desktop web and the flagged exceptions are justified or corrected.

## Acceptance requirements
1. Stencils/Designs duplicates: tap +, verify dark confirmation; count/border
   uses the exact UAG pink; manage/remove spares still persists correctly.
2. All/Needed/Dupes, name assignment, screenshot review, discard/save and
   full-screen image preview retain existing actions.
3. Dialog, bottom sheet, menu and form surfaces on profile, onboarding,
   quests, raid intelligence, Match Raider, trading and monetisation should
   use dark backgrounds, neon accent and approved heading/body typography.
4. Android landscape/portrait and desktop web should not show white-blue
   app-owned dialogs, text clipping or overflow. Flag embedded native UIs as
   separately owned surfaces.
5. Full Flutter analyze/test, web and debug APK must pass. Payment, rules,
   role restrictions, advertising and Blueprint ownership tests remain intact.
6. Release remains gated on manual UI walk-through; no production deploy.

## Ongoing drift prevention
Run `node tools/pass14_visual_convergence.js --mode verify --project .` on
future passes. Its report inventories remaining explicit colour exceptions.
New work should use shared `AppTheme` / `ArcUiTokens` and `UagDialogs`.

## REV2 Windows formatting repair
The original PASS14 preflight failed its exact `DialogThemeData` anchor check on CRLF Windows checkout files. The transformer now uses LF internally, preserves the source file EOL convention when written, and tests both LF and CRLF plus idempotence. All acceptance gates remain unchanged.

## REV3 Flutter analyzer unused-import repair
REV2 passed theme-contract widget tests but failed `flutter analyze` due to nine
unused prefixed theme imports in already-styled dialogs. The modal transformer
now adds the prefixed theme import **only when the transformed Dart references
it**; no existing workflow, styles or protected files are changed by this
revision beyond removing unnecessary generated imports. Regression fixtures
exercise existing themed backgrounds, transparent overlays, duplicate accent
tokens and idempotence. The full analyzer and build gates remain required.


### REV4 Windows whitespace correction

REV3 passed Flutter analysis, regression suite, web release and Android debug
build, but Git whitespace check detected seven whitespace-only lines introduced
in modal calls. REV4 inserts new arguments after existing newline indentation,
normalizes whitespace-only lines in changed files, and runs Git's CRLF-safe
whitespace check **before** Flutter gates. No change to protected files, feature
behaviour, Firebase or the required git HEAD. Manual visual QA is still needed.

## REV5 installer gate correction

REV4 completed Flutter analysis, full tests, web and Android successfully but
failed at `git diff --cached --check` because a newly staged JavaScript
transformer had one trailing space. REV5 removes the trailing space. The
installer now tests exact planned output in a fresh temporary Git index and
checks its staged whitespace and complete file list before any Flutter gate.
A final staged check still protects the local-only commit. The live Git index
is never changed by the early check.

These automatic gates do not constitute visual acceptance on Android/web.
