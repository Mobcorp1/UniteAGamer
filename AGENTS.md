# UAG ARC Raiders Hub — AI Worker Instructions

## Repository authority
- Repository: `C:\Users\mikem\uag_traders_hub`
- GitHub: `Mobcorp1/UniteAGamer`
- Active convergence branch: `codex/full-arc-ui-convergence`
- Stable branch: `beta-stabilisation`
- The CURRENT LOCAL checkout/worktree is authoritative. GitHub may be behind.
- Never replace local files with GitHub versions merely to make a task easier.

## Launch mode
UAG is in launch-convergence mode. Prioritise:
1. Release blockers and compliance.
2. Cross-device visual convergence.
3. Account/data lifecycle and deletion.
4. Goal-aware Command Centre/events.
5. First-run/profile/avatar consistency.
6. End-to-end trading/trust/contracts.
7. Responsive defects and error/loading states.
8. Release validation.

Do not invent major new product systems unless explicitly asked.

## Multi-agent isolation
- One AI worker per Git worktree.
- Never edit another worker's worktree.
- Before editing, run:
  - `git status --short --branch`
  - `git rev-parse --short=12 HEAD`
- If the worktree contains unexpected dirty or staged paths, STOP and report them.
- Do not stash, reset, clean, restore, overwrite, or "fix" another worker's changes.
- Keep each pass/workstream coherent and reviewable.
- Prefer larger coherent launch passes only when file ownership is non-overlapping and validation remains practical.

## Absolute Git safety
NEVER run:
- `git reset --hard`
- `git clean`
- broad `git restore`
- `git add .`
- `git add -A`

Do not:
- push unless Mike explicitly approves
- deploy Firebase unless Mike explicitly approves
- upload to Google Play unless Mike explicitly approves
- merge to `beta-stabilisation` unless Mike explicitly approves
- amend unrelated commits
- reformat unrelated files

Use exact-path staging only.

## Before implementation
- Inspect the actual current source first.
- Do not assume project notes equal implemented code.
- Reuse existing engines, repositories, models and design primitives.
- Identify protected behavior and adjacent workstreams before editing.
- Keep presentation changes separate from business-logic changes where practical.
- If a task expands beyond its stated boundary, stop and report the expansion instead of silently absorbing it.

## Protected/high-risk systems
Do not change unless the assigned task explicitly requires it:
- Blueprint canonical grid/order
- Blueprint ownership/duplicate logic and persistence
- Blueprint scanner/photo capture/calibration
- Favourite Loadout game-accuracy rules
- Raid Intelligence map registry/calibration/coordinate transforms
- `arc_admin_map_markers`
- Raid Planner Hunt Targets authority
- Quest/Scrappy/Bench progression engines and collected-count semantics
- auth/onboarding persistence semantics
- monetisation/ad policy
- Firebase project configuration
- Android signing
- Google Play configuration
- production assets/dependencies

Never request or expose signing passwords, keystores, secret tokens or private credentials.

## Product/visual rules
The target is a compact ARC operations console, not a generic business app:
- near-black/navy base
- restrained cyan primary
- restrained pink secondary
- gold for premium/founder/reward
- semantic green/red/amber
- VT323/glass/holographic treatment only where useful
- reduce dead space, nested cards and repeated page identity
- preserve usable viewport area
- prefer `background -> section -> item` over deep card nesting
- mobile is not a squeezed desktop layout
- avoid giant decorative heroes where they displace useful content
- use loading, error, empty and stale-data states distinctly
- do not hide failures as empty results

### Canonical product hierarchy
- COMMAND: Command Centre, Events, Community Intel
- RAID: Blueprint Tracker, Favourite Loadout, Raid Intelligence, Raid Planner
- PROGRESS: Quest, Scrappy, Bench, Hunt Targets
- SOCIAL: Match Raider, Trading, Raider Contracts
- YOU: Profile, Reputation, subscriptions/referrals, privacy/data

Command Centre = what matters now.
My Hub = systems/settings/control surface.
Avoid duplicating the same information on both.

## Responsive expectations
Where the touched surface is user-facing, test appropriate representatives of:
- phone portrait around 320–430 px wide
- short phone landscape around 640x360 / 740x360 / 844x390
- tablet around 768x1024 / 1024x768
- desktop around 1280x900 or larger

Do not claim responsive correctness from source inspection alone if widget/render tests are practical.

## Validation
For code changes, normally run:
1. format ONLY touched source/test files
2. `git --no-pager -c core.safecrlf=false diff --check`
3. relevant targeted tests
4. `flutter analyze`
5. full `flutter test` for substantial/launch-facing changes
6. `flutter build web --release --no-wasm-dry-run`
7. `flutter build apk --debug`
8. inspect exact `git status`, `git diff --name-status`, and `git diff --stat`

Backend/rules work must also run its relevant Node/emulator tests.

Do not weaken existing tests simply to get green.
Do not claim a validation step passed unless it was actually run.

## Commit discipline
If all required validation passes:
- stage exact intended paths only
- verify the staged path set
- run staged `diff --check`
- create one local commit with a clear message
- leave the worktree clean

Do not push.

## Final worker report
Always report:
- starting HEAD
- final commit SHA
- exact changed files
- behavior implemented
- tests/checks actually run
- analyze result
- build results
- final git status
- anything not completed
- deployment/index/rules follow-up required
