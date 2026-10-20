# UAG PASS 14B — Visual Convergence Closure and Exceptions

Source: locally certified PASS14 REV5 HEAD `d93858e5bbe1ef8d82e07361033dafc1758137c5`.

## Changes (scope-controlled)
- Canonical cyan, pink, dark surfaces and warning accents on Collections entry, Stencils/Designs controls, duplicate ledger, read-only Blueprint collection overview, agreement and trade invitation landing. Camera action foregrounds use contrasting dark text on pink backgrounds.
- Consistent dark native date and time picker defaults inherited through `AppTheme.theme` by existing calling screens. No date/time selection flow was altered.
- Share preview *dialog* background and heading colour moved to canonical tokens; the painter/export image palette remains untouched, pending visual assessment.
- Added widget and design-contract regression coverage, without changing account logic, protected Blueprint tracker, Favourite Loadout, scanner algorithms, or persistence.

## Reviewed and intentionally unchanged
- `lib/main.dart`: both `MaterialApp` instances already use `AppTheme.theme`.
- `trading_profile_screen.dart`: review-highlighted dialog is in an unused badge thumbnail method; already dark and semantically within design system.
- Scanner acquisition/calibration overlays: calibrated status colours and transparent camera surfaces, preserve pending device review.
- `arc_collection_visual_share.dart` renderer/painter: raster gradient colours are part of the exported artwork; excluded from automated bulk replacement.
- Map pins, cinematic backdrops, special effect gradients: intentional gameplay accents, not default Material components.
- `ArcUiTokens` and `AppTheme`: authoritative tokens; their hexadecimal declarations are intentional, not drift.
- `arc_operations_models.dart`: original default model accent not changed pending consumers review.
- Other on-boarding, setup and account screens: PASS15 functional acceptance, not rewritten here.

## Automated acceptance
1. Package exact-path SHA256, source SHA256, protected paths and archive validation.
2. Read-only preflight and temporary Git index staged-whitespace check before Flutter tests.
3. PASS14B targeted widget tests, full Flutter analyze/test, release web build (public VAPID) and Android debug APK.
4. Staged-whitespace check repeated on actual scoped changes, local-only commit, rollback of changed files on failure.
5. Existing `.firebase/hosting.YnVpbGRcd2Vi.cache` left intact.

## Manual acceptance remains mandatory
Run app-owned dialogs, overlays, menus and native pickers on Android and web; capture representative portrait, landscape and desktop screenshots. Verify Collections Stencils/Designs Dupe and Sharing states; trade invite errors, agreement consent, scanner and overlays, and Blueprint/Loadout regression. Declare product visual signoff only after physical rendering comparisons. No claim of complete visual acceptance is made by source or build checks alone.
