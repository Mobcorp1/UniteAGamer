# Closed Beta 2 Manual Test Checklist

Use this during short work breaks. Test with one admin account and one standard beta account.

## Authentication

- [ ] Web: login form supports normal browser autofill.
- [ ] Android portrait: login actions are visible above keyboard.
- [ ] Logout returns to login without stale previous-user beta state.
- [ ] Login as a second account does not show the first account's Command Centre state.

## Onboarding

- [ ] New standard account routes to consent/onboarding when required.
- [ ] Android portrait: Next and Back stay visible.
- [ ] Android landscape: active step can scroll fully into view.
- [ ] Web: Next progresses every step.
- [ ] Consent blocks progression until accepted.
- [ ] Final onboarding completion persists after refresh/restart.
- [ ] Admin replay/reset behaves intentionally.

## Personalisation

- [ ] Reduced beta config with only a few Live systems can still be completed.
- [ ] Coming Soon interests are clearly labelled and do not launch unfinished screens.
- [ ] Hidden interests are not shown to standard users.
- [ ] Existing stored hidden interests are not deleted when saving other preferences.

## Profile & Reputation

- [ ] Profile setup opens after onboarding when required.
- [ ] Archetype, communication preference and squad intent choices save.
- [ ] Optional mood/social-energy fields can be skipped safely.
- [ ] Returning to the screen shows saved values.

## Command Centre

- [ ] First screen answers the next useful action without long scrolling.
- [ ] Blueprint, Bench and Scrappy priorities appear only when relevant.
- [ ] Coming Soon recommendation opens the Coming Soon screen.
- [ ] Hidden features do not appear in Next Moves, Systems or Recommendations.
- [ ] Systems detail expansion is not empty.

## Blueprint Tracker

- [ ] Android portrait: grid controls remain reachable and do not cover tiles.
- [ ] Android landscape: pinch zoom and controls are usable.
- [ ] Web: cards do not overlap above the grid.
- [ ] Empty search results show a clear empty state.
- [ ] Ownership and duplicate interactions remain unchanged.

## Bench Tracker

- [ ] Route opens only when Bench Tracker is Live.
- [ ] Coming Soon state opens the Coming Soon screen.
- [ ] Hidden state rejects direct route access.
- [ ] Mobile cards do not overflow with long material names.

## Scrappy Tracker

- [ ] Route opens only when Scrappy Tracker is Live.
- [ ] Coming Soon state opens the Coming Soon screen.
- [ ] Hidden state rejects direct route access.
- [ ] Carousel/cards remain usable on mobile landscape.

## Coming Soon Feature

- [ ] Drawer Coming Soon item opens reusable Coming Soon screen.
- [ ] Back navigation returns to the previous beta surface.
- [ ] Register Interest copy does not promise push delivery.

## Admin State Changes

- [ ] Admin can set Blueprint Tracker to Live, Coming Soon and Hidden.
- [ ] Admin can set Bench Tracker to Live, Coming Soon and Hidden.
- [ ] Admin can set Scrappy Tracker to Live, Coming Soon and Hidden.
- [ ] Admin diagnostics show Live, Coming Soon and Hidden counts.
- [ ] Standard user drawer, My Hub, Command Centre and direct routes reflect each state.

## Feedback

- [ ] Feedback is reachable from the main beta surfaces.
- [ ] Categories include Bug, Layout/display issue, Something confusing, Feature request and General feedback.
- [ ] Submitted feedback includes current route, platform and viewport.

## Logout And Return Login

- [ ] Logout clears user-scoped transient beta state.
- [ ] Return login lands on the correct Command Centre state.
- [ ] Standard user cannot inherit admin preview access.
