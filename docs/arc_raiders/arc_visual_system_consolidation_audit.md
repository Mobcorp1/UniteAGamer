# ARC Visual System Consolidation Audit

Date: 2026-08-25

## Scope

Audited the current ARC Raiders Flutter implementation under `lib/features/trading_hub/arc_raiders/`, plus shared app theme/layout files used by ARC surfaces.

## Findings

- The ARC foundation layer exists, but visual decisions were split between `ArcUiTokens`, `ArcRaidersTheme`, `AppTheme.trading*` helpers, and screen-local `Colors.*`, `fontSize`, `BorderRadius`, and `EdgeInsets` values.
- Major routed surfaces already use `ArcRaidersScreenShell` or `ArcRaidersPageScaffold`, but several master screens still own custom background and dock treatments.
- Trading had four tracked empty widget files: `trading_card.dart`, `trading_risk_badge.dart`, `trading_seed_bundle_picker.dart`, and `trading_stat_chip.dart`.
- Highest local-style density was found in Operations, Favourite Loadout, Blueprint Grid, trading create/profile/session screens, ARC Hub, My Hub, Raid Planner, and Nomadic Trader.
- Existing tracker, map, loadout, and trade business logic is intertwined with presentation; safe consolidation should start with shared tokens/components and migrate repeated UI shells without touching data ordering, ownership, map coordinates, trade lifecycle, or route behaviour.

## Implementation Decisions

- Centralize semantic ARC color, typography, spacing, radius, surface, state, input, chip, and button vocabulary in `ArcUiTokens`.
- Repoint `ArcRaidersTheme` and `AppTheme.trading*` helpers to a calmer tactical palette with cyan as the primary intelligence/action accent and magenta as a secondary brand accent.
- Reduce default glow intensity and favor surface contrast, subtle borders, and readable neutral text.
- Convert empty trading widget stubs into real reusable presentation components and wire them into listing/seed/trade-network surfaces.
- Keep map, blueprint, loadout, trading, onboarding, Firebase, route, entitlement, and persistence logic unchanged.
