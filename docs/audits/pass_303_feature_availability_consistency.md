# PASS 303 - Feature Availability Consistency

## Shared Interpretation

| State | Standard user visibility | Route behaviour | Personalisation/Command Centre behaviour |
| --- | --- | --- | --- |
| Live | Visible | Opens the feature | May create actionable recommendations. |
| Coming Soon | Visible where product rules permit | Opens reusable Coming Soon screen | May be surfaced as expressed interest, but never launches unfinished functionality. |
| Hidden | Not visible | Direct route is rejected by a locked/hidden surface | Excluded from normal navigation and Command Centre output; stored interests are preserved. |

PASS 303 added deterministic helpers for this interpretation on `FeatureAvailability`.

## Surfaces Audited

| Surface | Status | Notes |
| --- | --- | --- |
| Main named routes | Fixed | Blueprint, Bench, Quest, Raid Planner, Intel Explorer and Raid Intelligence now use `FeatureAccessRouteGate`. |
| App drawer | Fixed | PASS 302 watches the availability map; PASS 303 added missing gates for Blueprint, Raid Intelligence and Raid Planner plus grouped Progress Tracker visibility flags. |
| My Hub / Tool Deck | Fixed | Blueprint no longer bypasses feature state; title mapping uses the Blueprint Tracker flag. |
| ARC Raiders hub | Fixed | Same Blueprint title mapping and bypass removal as My Hub. |
| Progress Trackers hub | Fixed | Cards are filtered by Live/Coming Soon/Hidden and Coming Soon cards route safely. |
| Command Centre | Fixed | Coming Soon recommendations are deduped by feature gate. Hidden features remain excluded through the availability map. |
| Admin Console toggles | Already protected | Existing Live/Coming Soon/Hidden dropdowns remain the admin control surface. |
| Admin diagnostics | Fixed | Summary now reads the standard-user beta configuration from `config/feature_access`, not the admin bypass. |
| Personalisation | Working with caveat | Hidden stored interests are not deleted. Manual onboarding checks remain required for reduced-choice flows. |
| Notifications | Deferred | Coming Soon to Live intent handoff remains queued only; full fan-out is not implemented in this pass. |

## Inconsistencies Repaired

- Bench and Quest routes were incorrectly controlled by the Scrappy flag.
- Blueprint Tracker could open from hub shortcuts even if admin moved it to Coming Soon or Hidden.
- Raid Planner and Raid Intelligence direct routes could bypass the availability model.
- Drawer catalog entries for controlled Blueprint, Raid Planner and Raid Intelligence destinations lacked access flags.
- Progress Trackers hub could show hidden child systems.
- Admin diagnostics could misrepresent all gated systems as Live for admin users.

## Deferred Checks

- Live standard-user Firebase rule verification.
- Notification fan-out from queued feature-live intents.
- Onboarding reduced-choice widget walkthrough on real mobile and web devices.
