# PASS 16 — Amplification Research / Loadout integration

Source baseline: local PASS 14B commit `cb5e597f637be8f7c8b3745e1e2ffc8bdab0fe2a`.

## Working integration
- 15 Amplified Research projects, combat objectives, 5 active slots with pause/resume, saved in the existing authenticated user's `users/{uid}/arc_amplification_research/state` Firestore document.
- Separate game-verified RP wallet, study credits, material balances, project completion with atomic resource deduction.
- Research Workstation opens the shared active research workspace.
- Favourite Loadout shows optional amplification research goals for current primary and secondary weapons, locked/unlocked/applied status, per-weapon upgrade node material costs and deliberate confirmation of installed perks.
- Existing Raid Intelligence map accepts a prefilled enemy/POI marker search; no fabricated spawn probabilities.
- Material trade brief copies exact current shortage and opens the existing Trading Hub; it does not publish an automatic listing or imply that research points are tradeable.
- Existing Blueprint grid, ownership/duplicate logic, layout slot compatibility, weapon attachment ordering, ad placements and saved loadout serialization are not changed.

## Important player-facing boundaries
- UAG does **not** read inventory or task progress from ARC Raiders; changes are manually entered by the player.
- Unlocking research is distinct from applying an irreversible weapon perk in-game.
- Some perks have prerequisite/conflict branches, and extra non-research upgrades; always follow the game's tree before spending materials. Node recipes are community references, not authoritative live game inventory.
- Community material trade eligibility is not guaranteed; no automatic publication or reserved inventory is performed.
- The shared progress record is per signed-in UAG user and syncs via Firestore; Firebase rules/access must be validated on the live account during Windows certification.
- Fast-expiring single-raid objectives are manually confirmed after that raid; UAG does not claim to derive live combat events.
- Research modules Mk I–V remain in the existing progression catalogue.

## Verification & release
- `flutter test test/pass16_amplification_research_test.dart`, `flutter analyze`, full `flutter test`, Flutter release web and debug APK, isolated staged Git whitespace and SHA attestations.
- Local commit only after passing tests. The attached deployment gate installs APK on one authorised Xperia and deploys the certified web build, verifying a live release marker. Never publish on failed tests.
- Source preflight enforces branch, HEAD and source fingerprint, and refuses unrelated modified/staged files.
- Output report distinguishes local certification, deployment failure and live web + Android QA readiness.

## Game data references (checked October 20, 2026)
- https://arcraiders.wiki/wiki/Amplified_Research
- https://arcraiders.wiki/wiki/Amplified_Weapons
- https://arctracker.io/research/magazine-geometry-101
- https://arctracker.io/research/shield-stress-testing
- https://www.keengamer.com/articles/guides/arc-raiders-all-15-amplified-weapons-how-to-unlock/

## Acceptance checks after deploying
- Create a research project; set damage, stock and RP; resume project on another login/device.
- Attempt sixth active project (must be blocked), pause/restart, complete research, verify correct resource deductions and permanent unlocked state.
- Select corresponding weapon in Favourite Loadout, plan an upgrade, check node cost and manually confirm after upgrading in-game. Confirm that normal attachments and Blueprint grid remain unchanged.
- Open linked enemy/POI marker search and Trading Hub. Confirm no unsupported automatic trade listing or game-state inference.
- Verify responsive Android/web layout, modal style, phone installation and web release marker.
