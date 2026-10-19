# PASS 13D — Android ANR evidence-led stability pass

## Incident (2026-10-19 17:14:37 Europe/London)
- Device: Sony Xperia XQ-ES54, Android 16 (API 36).
- Package: `com.mobcorp.uagtradershub`.
- Android recorded `Input dispatching timed out ... Waited 5000ms for MotionEvent`.
- Native main-thread trace contains `libflutter.so` followed by anonymous Dart code; release symbols do NOT identify the Dart function.
- Raster thread and several Firebase background threads were waiting when sampled; this does NOT rule out earlier rendering or asynchronous operations.
- RSS ~574,328 KiB, peak RSS ~764,752 KiB. These do not prove an image cache leak.
- App recovered after user selected Wait.

## Scope and explicit limitations
This pass adds Android-specific retained image cache bounds, defensive cleanup on OS memory-pressure notification, and opt-in event-loop/frame timing diagnostics. It marks the Collections Tracker surfaces during profiling. This is **not** proof that the historical ANR root cause is repaired. Full release certification requires real-device repetition and no new ANRs. Do not infer an exact Dart blocking function from the native release stack.

Blueprint grid order, `_buildGrid`, `BlueprintTile`, ownership/duplicates/acquisition, Favourite Loadout, ad slots, Firebase rules/functions, trade routing and matching flags remain untouched.

## Installation
The one-shot installer recognises certified PASS 13B head `25d421d0d6248428bda146a1b4f93a25c6f7beed` and integrates the already-packaged PASS 13C prerequisite automatically **if needed**, then applies PASS 13D. If PASS 13C has already committed, it skips that prerequisite.

No production Firebase deployment, Hosting deploy, GitHub push or Android app install occurs during LOCAL installation.

Required before installation: set the existing PUBLIC Firebase Web Push VAPID key in the PowerShell process environment, or provide it to the install script. No private keys.

Full gates: test script contract checks; Flutter targeted unit test, analyze, complete Flutter suite, VAPID web release, debug APK, diff integrity, exact-path local commit. Rollback restores only PASS 13D changed files on failure; an already-certified PASS 13C prerequisite commit is kept if it completed.

## Real Android closed-beta QA (after local installation)
Run `Run-UAG-PASS13D-DeviceQA.ps1 -ProjectRoot <path> -DurationSeconds 120`. This explicitly installs a signed **profile** APK with opt-in diagnostics over the installed UAG app using `adb install -r` (never uninstalls or clears data). Do not run if installing a profile build on the phone is not intended. If signatures differ, Android will refuse; never uninstall to make it work.

During the capture window: start Collections Tracker; scroll/pan/zoom 91-tile grid; switch ALL/NEEDED/DUPES; rotate to portrait and back; visit scanner and return (do not save or overwrite collection); return to control centre. Try three cycles, including a cold startup, and check for Android ANR dialogue, perceptible stalls and missing data.

Device QA logs: Android main/system/events logcat, frame/event-loop `UAG_ANR_DIAG`, device meminfo before/after, `dumpsys activity lastanr` before/after, and report. These are LOCAL and may contain private information; review before sharing.

Live certification is NOT automatic: a 120-second window without a reported ANR does not prove a repair. Requires user acceptance, and ideally repeat across an additional Android device and release-mode candidate build.

## Regressions that must remain closed
- 91 fixed slots and order; `_buildGrid` unchanged; `BlueprintTile` unchanged.
- Ownership, duplicate count, scanner acquisition and favourites data unchanged.
- Ads remain on the required screens with existing tier entitlement behaviour.
- PASS 13C QA-only matching control remains fail-closed and Firebase is not deployed by this script.
- No screenshot capture, remote metrics upload, or user/account IDs in new diagnostics.
