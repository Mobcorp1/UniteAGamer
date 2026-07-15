# Closed Beta Acceptance Matrix - PASS 259D

This matrix defines the closed-beta manual acceptance journeys after PASS 259D. Automated tests cover pure model/policy logic and existing engines; manual testing is still required for live Firebase journeys, public reset execution, admin diagnostics and responsive UI.

## Summary

| Journey | Status |
| --- | --- |
| Existing progressed user | Partially automated, manual Firebase verification required |
| Fresh user | Partially automated, manual onboarding/profile verification required |
| Reset user | Public flow wired, manual Firebase verification required |
| Failure recovery | Coordinator model covered, live interruption test required |

## Required Manual Journeys

Detailed row-by-row steps live in:

`docs/testing/closed_beta_acceptance_matrix.csv`

## PASS 259D Acceptance Notes

- Admin/dev accounts should see the read-only Closed Beta Diagnostics card plus candidate diagnostics in Admin Console.
- Fresh login should create `users/{uid}/arc_season_state/current` if missing.
- Interrupted reset reconciliation is invoked at startup, and the Command Centre Expedition Reset card opens the public preview/confirmation screen.
- Operations progress, telemetry and reward claims written after PASS 259D should include `seasonId`.
- Reward inventory items written after PASS 259D should include source season/source Operation and permanence/equipability fields.
- Firestore rules tests/deployment remain blocked until a focused emulator harness and authenticated CLI deployment are available.
