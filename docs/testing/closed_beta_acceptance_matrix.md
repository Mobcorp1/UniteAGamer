# Closed Beta Acceptance Matrix - PASS 259C

This matrix defines the closed-beta manual acceptance journeys after PASS 259C. Automated tests cover pure model/policy logic and existing engines; manual testing is still required for live Firebase journeys, admin diagnostics and any future destructive reset UI.

## Summary

| Journey | Status |
| --- | --- |
| Existing progressed user | Partially automated, manual Firebase verification required |
| Fresh user | Partially automated, manual onboarding/profile verification required |
| Reset user | Coordinator/model automated, public reset flow deferred |
| Failure recovery | Coordinator model covered, live interruption test required |

## Required Manual Journeys

Detailed row-by-row steps live in:

`docs/testing/closed_beta_acceptance_matrix.csv`

## PASS 259C Acceptance Notes

- Admin/dev accounts should see the read-only Closed Beta Diagnostics card in Admin Console.
- Fresh login should create `users/{uid}/arc_season_state/current` if missing.
- Interrupted reset reconciliation is invoked at startup, but a user-facing reset preview/confirmation screen remains deferred.
- Operations progress, telemetry and reward claims written after PASS 259C should include `seasonId`.
- Reward inventory items written after PASS 259C should include source season/source Operation and permanence/equipability fields.
- Firestore rules changes must be deployed separately before production validation can be considered complete.
