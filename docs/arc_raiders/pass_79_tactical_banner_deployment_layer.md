# Pass 79 - Tactical Banner Deployment Layer

Applied shared tactical banner deployment foundation.

## Scope
- Integrated UagTacticalBannerAd above shared ARC bottom docks.
- Added UagAdAwareBottomDock wrapper.
- Added opt-out flags for future premium/ad-free screens.
- Preserved test-ad-first config from Pass 78.

## Safety
No tracker, blueprint ownership, carousel, Firestore, raid planner, hunt sync, trading, or loadout persistence logic was changed.

## Notes
Production AdMob IDs remain stored in config, but local/dev builds should keep UagAdMobConfig.useProductionAds disabled until release compliance is complete.
